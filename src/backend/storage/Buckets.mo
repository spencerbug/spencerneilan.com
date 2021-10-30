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
import CertifiedData "mo:base/CertifiedData";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat16 "mo:base/Nat16";

actor class Bucket () = this {

  type FileId = Types.FileId;
  type FileInfo = Types.FileInfo;
  type FileData = Types.FileData;
  type ChunkId = Types.ChunkId;
  type State = Types.State;
  type ChunkNum = Types.ChunkNum;
  type HttpRequest = Types.HttpRequest;
  type HttpResponse = Types.HttpResponse;

  var state = Types.empty();
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

  func createFileInfo(fileId: Text, fi: FileInfo) : ?FileId {
          switch (state.files.get(fileId)) {
              case (?_) { /* error -- ID already taken. */ null }; 
              case null { /* ok, not taken yet. */
                  Debug.print("id is..." # debug_show(fileId));   
                  state.files.put(fileId,
                                      {
                                          fileId = fileId;
                                          cid = Principal.fromActor(this);
                                          name = fi.name;
                                          createdAt = fi.createdAt;
                                          uploadedAt = Time.now();
                                          chunkCount = fi.chunkCount;
                                          size = fi.size ;
                                          filetype = fi.filetype;
                                      }
                  );
                  ?fileId
              };
          }
  };

  public func putFile(fi: FileInfo) : async ?FileId {
    do ? {
      // append 2 bytes of entropy to the name
      let fileId = await generateRandom(fi.name);
      createFileInfo(fileId, fi)!;
    }
  };

  func chunkId(fileId : FileId, chunkNum : ChunkNum) : ChunkId {
    // awkward workaround because there's no Text.parseNat()
      let chunkNumText:Text=switch chunkNum {
        case (#text_chunknum(x)){x};
        case (#nat_chunknum(x)){Nat.toText(x)};
      };
      fileId # chunkNumText
  };
  // add chunks 
  // the structure for storing blob chunks is to unse name + chunk num eg: 123a1, 123a2 etc
  public func putChunk(fileId : FileId, chunkNum : ChunkNum, chunkData : Blob) : async ?() {
    do ? {
      Debug.print("generated chunk id is " # debug_show(chunkId(fileId, chunkNum)) # " from "  #   debug_show(fileId) # " and " # debug_show(chunkNum)  #"  and chunk size..." # debug_show(Blob.toArray(chunkData).size()) );
      state.chunks.put(chunkId(fileId, chunkNum), chunkData);
    }
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
          }
      }
  };

  public query func getFileInfo(fileId : FileId) : async ?FileData {
    do ? {
      getFileInfoData(fileId)!
    }
  };

  public query func getChunks(fileId : FileId, chunkNum: ChunkNum) : async ?Blob {
      state.chunks.get(chunkId(fileId, chunkNum))
  };

  public func delChunks(fileId : FileId, chunkNum : ChunkNum) : async () {
        state.chunks.delete(chunkId(fileId, chunkNum));
  };

  public func delFileInfo(fileId : FileId) : async () {
      state.files.delete(fileId);
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

  public query func http_request(req: HttpRequest) : async HttpResponse {
    // url format: <canisterid>.raw.ic0.app/storage?fileId=<fileId>&<fileId>&chunkNum=<chunkNum>
    // http://<canisterId>.127.0.0.1:8453/storage?fileId=testfile.txt25&chunkNum=1
    // assume most images are only 1 chunk, so this will suffice for a profile picture or something
    // for later: output an httpstream, so we can load videos and progressive jpegwith a single link!
    var status_code=404;
    var headers = [("Content-Type","text/html")];
    var body:Blob = "404 Not Found";
    let _ = do ? { // is this possible without assignment
      let storageParams:Text = Text.stripStart(req.url, #text("/storage?"))!;
      let fields:Iter.Iter<Text> = Text.split(storageParams, #text("&"));
      var fileId:?FileId=null;
      var chunkNum:?ChunkNum=null;
      for (field:Text in fields){
        let kv:[Text] = Iter.toArray<Text>(Text.split(field,#text("=")));
        if (kv[0]=="fileId"){
          fileId:=?kv[1];
        }
        else if (kv[0]=="chunkNum"){
          chunkNum:=?#text_chunknum(kv[1]);
        }
      };
      let fileData:FileData = getFileInfoData(fileId!)!;
      body := state.chunks.get(chunkId(fileId!, chunkNum!))!;
      headers := [("Content-Type",fileData.filetype), ("Content-Length",Nat.toText(fileData.size)),("certificate",Text.decodeUtf8(CertifiedData.getCertificate()!)!)];
      status_code:=200;
    };
    return {
      status_code=Nat16.fromNat(status_code);
      headers=headers;
      body=body;
      streaming_strategy=null;
    };
  };

};