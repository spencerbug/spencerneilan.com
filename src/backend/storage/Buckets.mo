import Types "./Types";
import Random "mo:base/Random";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Prim "mo:prim";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat16 "mo:base/Nat16";
import TrieMap "mo:base/TrieMap";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";


shared({ caller = initializer }) actor class Bucket() = this {

  type FileId = Types.FileId;
  type FileInfo = Types.FileInfo;
  type FileData = Types.FileData;
  type ChunkId = Types.ChunkId;
  type ChunkData = Types.ChunkData;
  type Timestamp = Types.Timestamp;
  type State = Types.State;
  type StableState = Types.StableState;
  type HttpRequest = Types.HttpRequest;
  type HttpResponse = Types.HttpResponse;
  type StreamingCallbackToken = Types.StreamingCallbackToken;
  type StreamingStrategy = Types.StreamingStrategy;
  type StreamingCallbackHttpResponse = Types.StreamingCallbackHttpResponse;

  private let threshold = 2147483648; // this should be parametrized, but I don't know how to add the argument to dfx.json

  // reserve  an amount of space in this bucket, to be filled in with chunks
  // because for http_stream to work all the chunks need to be in the same bucket
  // and we don't want race conditions if the bucket gets full before the chunks are ready
  // this function also returns the FileId

  
  let reservationState:HashMap.HashMap<FileId, Nat> = HashMap.HashMap<FileId, Nat>(100,Text.equal,Text.hash);

  let recycleReservedMemoryOlderThanSeconds = 3600;

  var reservedMemory:Nat=0;

  // CRUD interface:
  /*
  Create: 2 steps:
  1) Call reserve(fileInfo, msg.caller) -> async fileId:?FileId
  1b) if null, move on to next bucket or create a new one
  2) Repeatedly call putChunks(fileId, chunkNum, chunkData) -> async ?()
  

  Read: 
  // call http request,
  http://<IC network>/storage?canisterId=<bucketId>&fileId=<fileId>

  Update:
  1) Call reserveUpdate(fileId, fileInfo) -> async ?Nat
  1b) If null, move on to next bucket and call reserve(), or create new bucket and call reserve()
  2) Repeatedly call putChunks(fileId, chunkNum, chunkData) -> ?()

  Delete:
  deleteFile(fileId:FileId -> async ?()

  */

  private func getUnusedFileId(name:Text, attempts:Nat): async ?FileId{
    if (attempts <= 0){
      return null;
    };
    let fileId:FileId = await generateRandom(name);
    switch (state.files.get(fileId)) {
      case (?_) { await getUnusedFileId(name, attempts-1) }; //fileId exists
      case null { ?fileId };
    }
  };

  private func addReservedMemory(fileId:FileId, size:Nat):async ?Nat{
    let currentMemUsage:Nat = await getSize();
    if ((size + reservedMemory + currentMemUsage) > threshold){
      return null;
    };
    let reservedAlready:?Nat = reservationState.get(fileId);
    switch (reservedAlready){
      case (?reserved) { 
        throw Error.reject ("reservation already exists for "#fileId);
        null
      };
      case null {
        reservationState.put(fileId, size);
        reservedMemory += size;
        ?size
      };
    };
  };

  private func subtractReservedMemory(fileId:FileId, size:Nat):?Nat{
    let reservedAlready:?Nat = reservationState.get(fileId);
    switch (reservedAlready){
      case (?reserved){
        reservationState.put(fileId, reserved - size);
        reservedMemory -= size;
        ?(reserved - size)
      };
      case null {
        null
      };
    };
  };

  public func reservationGarbageCollect(): async (){
    let now:Timestamp = Time.now();
    let reservedOriginally:Nat=reservedMemory;
    var freed:Nat=0;
    for ((fileId, size) in reservationState.entries()){
      switch(state.files.get(fileId)){
        case (?fileData){
          if (now - fileData.uploadedAt > recycleReservedMemoryOlderThanSeconds){
            reservationState.delete(fileId);
            reservedMemory -= size;
          }
        };
        case null {
          reservationState.delete(fileId);
          reservedMemory -= size;
        };
      };
      freed += size;
    };
    Debug.print("Freed "#debug_show(freed)#"/"#debug_show(reservedOriginally)#" reserved bytes.");
  };


  public shared(msg) func reserve(fi:FileInfo, caller:Principal):async ?FileId {
    if ( msg.caller != initializer ) {
        throw Error.reject ("Can only be called by Container contract");
    };
    do ?{
      let fid:FileId = (await getUnusedFileId(fi.name, 5))!;
      let _ = (await addReservedMemory(fid, fi.size))!;

      state.files.put(fid, {
        fileId = fid;
        cid = caller;
        name = fi.name;
        createdAt = fi.createdAt;
        uploadedAt = Time.now();
        chunkCount = fi.chunkCount;
        size = fi.size ;
        filetype = fi.filetype;
        contentDisposition = fi.contentDisposition;
      });

      fid
    }
  };

  private func _deleteFile(fileId:FileId, fileData:FileData): () {
    for (i in Iter.range(1, fileData.chunkCount)){
        state.chunks.delete(chunkId(fileId, i))
    };
    state.files.delete(fileId);
  };

  public shared(msg) func deleteFile(fileId:FileId): async ?(){
    do ?{
      let fileData:FileData = state.files.get(fileId)!;
      if (msg.caller != fileData.cid){
        throw Error.reject ("Only file owner " # debug_show(fileData.cid) # " can deleteFile(" #fileId#")");
      };
      _deleteFile(fileId, fileData);
    };
  };

  // re-researve space on canister given the same FileId (assuming it exists already),
  // also reupdates fileInfo
  // there can't be an existing reesrvation however, so you need to call putchunks
  // if there's not enough space, the FileId key is automatically deleted, and caller should move to a new bucket
  // returns either the size of the file reserved, or null for failure
  public shared(msg) func reserveUpdate(fileId:FileId, fi:FileInfo, caller:Principal):async ?Nat {
    if ( msg.caller != initializer ) {
        throw Error.reject ("Can only be called by Container contract");
    };
    do ?{
      let fileData:FileData = state.files.get(fileId)!;
      if ( caller != fileData.cid ) {
        throw Error.reject ("Only file owner " # debug_show(fileData.cid) # " can reserveUpdate(" #fileId#")");
      };
      switch(await addReservedMemory(fileId, fi.size)){
        case null {
          Debug.print("Deleting " # fileId # " because more space is needed then can fit on this bucket");
          _deleteFile(fileId, fileData);
          null!
        };
        case (?size) {
          // Debug.print("Putting fileinfo into state as fid:"#fileId);
          state.files.put(fileId, {
            fileId = fileId;
            cid = caller;
            name = fi.name;
            createdAt = fi.createdAt;
            uploadedAt = Time.now();
            chunkCount = fi.chunkCount;
            size = fi.size ;
            filetype = fi.filetype;
            contentDisposition = fi.contentDisposition;
          });
          size
        };
      }; // if we return null, then this canister is out of space
      
    }
  };

  func chunkId(fileId : FileId, chunkNum : Nat) : ChunkId {
      fileId # Nat.toText(chunkNum)
  };
  
  // put chunks representing a fileId. with chunkNum starting at 1, and chunkData is the actual data
  // we dealloc our reservation each time our chunks are entered, until all the chunks are sent
  // we can only put chunks that are reserved under the same principal ID as the reserver
  public shared(msg) func putChunks(fileId : FileId, chunkNum : Nat, chunkData : Blob) : async ?() {
    do ? {
      let fileData:FileData = state.files.get(fileId)!;
      if ( msg.caller != fileData.cid ) {
        throw Error.reject ("Only file owner " # debug_show(fileData.cid) # " can putChunk(" #fileId#")");
      };
      let chunkSize=Blob.toArray(chunkData).size();
      let bytesRemaining = subtractReservedMemory(fileId, chunkSize)!; // return null if reservation !exist
      if (bytesRemaining == 0){
        // lastChunk reserved
        Debug.print("Last chunk sent, reservation deleted");
        reservationState.delete(fileId);
      };
      Debug.print("generated chunk id is " # debug_show(chunkId(fileId, chunkNum)) # " from "  #   debug_show(fileId) # " and " # debug_show(chunkNum)  #"  and chunk size..." # debug_show(chunkSize) );
      state.chunks.put(chunkId(fileId, chunkNum), chunkData);
    }
  };

  private func deserializeState(s:StableState):State {
    {
      files = TrieMap.fromEntries<FileId, FileData>(
        Iter.fromArray<(FileId, FileData)>(
          s.files
        ),
        Text.equal,
        Text.hash
      );
      chunks = TrieMap.fromEntries<ChunkId, ChunkData>(
        Iter.fromArray<(ChunkId, ChunkData)>(
          s.chunks,
        ),
        Text.equal,
        Text.hash
      );
    }
  };

  private func serializeState(s:State):StableState {
    {
      files = Iter.toArray(s.files.entries());
      chunks = Iter.toArray(s.chunks.entries());
    }
  };

  stable var stableState:StableState = {
    files = [];
    chunks = [];
  };

  let state:State = deserializeState(stableState);

  system func preupgrade () {
    stableState := serializeState(state);
  };

  system func postupgrade () {
    stableState := {
      files = [];
      chunks = [];
    };
  };

  let limit = 20_000_000_000_000;

  public func getSize(): async Nat {
    Debug.print("canister balance: " # Nat.toText(Cycles.balance()));
    Prim.rts_memory_size();
  };
  // consume 1 byte of entrypy
  func getrByte(f : Random.Finite) : ? Nat8 {
    do ? {
      f.byte()!
    };
  };
  // append 2 bytes of entropy to the name
  // https://sdk.dfinity.org/docs/base-libraries/random
  public func generateRandom(name: Text): async Text {
    var n : Text = name;
    let entropy = await Random.blob(); // get initial entropy
    var f = Random.Finite(entropy);
    let count : Nat = 2;
    var i = 1;
    label l loop {
      if (i >= count) break l;
      let b = getrByte(f);
      switch (b) {
        case (?b) { n := n # Nat8.toText(b); i += 1 };
        case null { // not enough entropy
          Debug.print("need more entropy...");
          let entropy = await Random.blob(); // get more entropy
          f := Random.Finite(entropy);
        };
      };
      
    };
    
    n
  };

  func getFileInfoData(fileId : FileId) : ?FileData {
      do ? {
          let v = state.files.get(fileId)!;
            {
            fileId = v.fileId;
            cid = v.cid;
            name = v.name;
            size = v.size;
            chunkCount = v.chunkCount;
            filetype = v.filetype;
            createdAt = v.createdAt;
            uploadedAt = v.uploadedAt;
            contentDisposition = v.contentDisposition;
          }
      }
  };

  public query func getFileInfo(fileId : FileId) : async ?FileData {
    do ? {
      getFileInfoData(fileId)!
    }
  };


  public query func getInfo() : async [FileData] {
    let b = Buffer.Buffer<FileData>(0);
    let _ = do ? {
      for ((f, _) in state.files.entries()) {
        b.add(getFileInfoData(f)!)
      };
    };
    b.toArray()
  };

  public func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, limit));
    { accepted = Nat64.fromNat(accepted) };
  };

  public func wallet_balance() : async Nat {
    return Cycles.balance();
  };

  // To do: https://github.com/DepartureLabsIC/non-fungible-token/blob/1c183f38e2eea978ff0332cf6ce9d95b8ac1b43d/src/http.mo


  public query func streamingCallback(token:StreamingCallbackToken): async StreamingCallbackHttpResponse {
    Debug.print("Sending chunk " # debug_show(token.key) # debug_show(token.index));
    let body:Blob = switch(state.chunks.get(chunkId(token.key, token.index))) {
      case (?b) b;
      case (null) "404 Not Found";
    };
    let next_token:?StreamingCallbackToken = switch(state.chunks.get(chunkId(token.key, token.index+1))){
      case (?nextbody) ?{
        content_encoding=token.content_encoding;
        key = token.key;
        index = token.index+1;
        sha256 = null;
      };
      case (null) null;
    };

    {
      body=Blob.toArray(body);
      token=next_token;
    };
  };


  public query func http_request(req: HttpRequest) : async HttpResponse {
    // url format: raw.ic0.app/storage?canisterId=<bucketId>&fileId=<fileId>
    // http://127.0.0.1:8000/storage?canisterId=<bucketId>&fileId=testfile.txt25
    Debug.print(debug_show(req));
    var _status_code:Nat16=404;
    var _headers = [
      ("Content-Type","text/html"),
      ("Content-Disposition","inline"),
      ("Access-Control-Allow-Origin","*")
      ];
    var _body:Blob = "404 Not Found";
    var streaming_strategy:?StreamingStrategy = null;
    let _ = do ? {
      let storageParams:Text = Text.stripStart(req.url, #text("/storage?"))!;
      let fields:Iter.Iter<Text> = Text.split(storageParams, #text("&"));
      var fileId:?FileId=null;
      var chunkNum:Nat=1;
      for (field:Text in fields){
        let kv:[Text] = Iter.toArray<Text>(Text.split(field,#text("=")));
        if (kv[0]=="fileId"){
          fileId:=?kv[1];
        }
      };
      let fileData:FileData = getFileInfoData(fileId!)!;
      Debug.print("FileData: " # debug_show(fileData));
      _body := state.chunks.get(chunkId(fileId!, chunkNum))!;
      _headers := [
        ("Content-Type",fileData.filetype),
        // ("Content-Length",Nat.toText(fileData.size-1)),
        ("Transfer-Encoding", "chunked"),
        ("Content-Disposition",fileData.contentDisposition)
      ];
      _status_code:=200;
      if (fileData.chunkCount > 1){
        streaming_strategy := ?#Callback({
          token = {
            content_encoding="gzip";
            key=fileId!;
            index=chunkNum; //starts at 1
            sha256=null;
          };
          callback = streamingCallback;
        });
      };

    };
    return {
      status_code=_status_code;
      headers=_headers;
      body=_body;
      streaming_strategy=streaming_strategy;
    };
  };

};