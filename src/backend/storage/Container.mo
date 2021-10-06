import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Buckets "Buckets";
import Types "./Types";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import CertifiedData "mo:base/CertifiedData";


// Container actor holds all created canisters in a canisters array 
// Use of IC management canister with specified Principal "aaaaa-aa" to update the newly 
// created canisters permissions and settings 
//  https://sdk.dfinity.org/docs/interface-spec/index.html#ic-management-canister
shared ({caller = owner}) actor class Container() = this {

 public type canister_id = Principal;
  public type canister_settings = {
    freezing_threshold : ?Nat;
    controllers : ?[Principal];
    memory_allocation : ?Nat;
    compute_allocation : ?Nat;
  };
  public type definite_canister_settings = {
    freezing_threshold : Nat;
    controllers : [Principal];
    memory_allocation : Nat;
    compute_allocation : Nat;
  };
  public type user_id = Principal;
  public type wasm_module = [Nat8];

  let IC = actor "aaaaa-aa" : actor {
    canister_status : shared { canister_id : canister_id } -> async {
      status : { #stopped; #stopping; #running };
      memory_size : Nat;
      cycles : Nat;
      settings : definite_canister_settings;
      module_hash : ?[Nat8];
    };
    create_canister : shared { settings : ?canister_settings } -> async {
      canister_id : canister_id;
    };
    delete_canister : shared { canister_id : canister_id } -> async ();
    deposit_cycles : shared { canister_id : canister_id } -> async ();
    install_code : shared {
        arg : [Nat8];
        wasm_module : wasm_module;
        mode : { #reinstall; #upgrade; #install };
        canister_id : canister_id;
      } -> async ();
    provisional_create_canister_with_cycles : shared {
        settings : ?canister_settings;
        amount : ?Nat;
      } -> async { canister_id : canister_id };
    provisional_top_up_canister : shared {
        canister_id : canister_id;
        amount : Nat;
      } -> async ();
    raw_rand : shared () -> async [Nat8];
    start_canister : shared { canister_id : canister_id } -> async ();
    stop_canister : shared { canister_id : canister_id } -> async ();
    uninstall_code : shared { canister_id : canister_id } -> async ();
    update_settings : shared {
        canister_id : Principal;
        settings : canister_settings;
      } -> async ();
    };

  type Bucket = Buckets.Bucket;
  type Service = Types.Service;
  type FileId = Types.FileId;
  type FileInfo = Types.FileInfo;
  type FileData = Types.FileData;
  type FileExtension = Types.FileExtension;
  type HttpRequest = Types.HttpRequest;
  type HttpResponse = Types.HttpResponse;
  type ChunkNum = Types.ChunkNum;

// canister info hold an actor reference and the result from rts_memory_size
  type CanisterState<Bucket, Nat> = {
    bucket  : Bucket;
    var size : Nat;
  };
  // canister map is a cached way to fetch canisters info
  // this will be only updated when a file is added 
  private let canisterMap = HashMap.HashMap<Principal, Nat>(100, Principal.equal, Principal.hash);


  private let canisters : [var ?CanisterState<Bucket, Nat>] = Array.init(10, null);
  // this is the number I've found to work well in my tests
  // until canister updates slow down 
  //From Claudio:  Motoko has a new compacting gc that you can select to access more than 2 GB, but it might not let you
  // do that yet in practice because the cost of collecting all that memory is too high for a single message.
  // GC needs to be made incremental too. We are working on that.
  // https://forum.dfinity.org/t/calling-arguments-from-motoko/5164/13
  private let threshold = 2147483648; //  ~2GB
  // private let threshold = 50715200; // Testing numbers ~ 50mb

  // each created canister will receive 1T cycles
  // value is set only for demo purposes please update accordingly 
  private let cycleShare = 1_000_000_000_000;


  // dynamically install a new Bucket
  func newEmptyBucket(): async Bucket {
    Cycles.add(cycleShare);
    let b = await Buckets.Bucket();
    let _ = await updateCanister(b); // update canister permissions and settings
    let s = await b.getSize();
    Debug.print("new canister principal is " # debug_show(Principal.toText(Principal.fromActor(b))) );
    Debug.print("initial size is " # debug_show(s));
    let _ = canisterMap.put(Principal.fromActor(b), threshold);
     var v : CanisterState<Bucket, Nat> = {
         bucket = b;
         var size = s;
    };
    canisters[1] := ?v;
  
    b;
  };

  // check if there's an empty bucket we can use
  // create a new one in case none's available or have enough space 
  func getEmptyBucket(s : ?Nat): async Bucket {
    let fs: Nat = switch (s) {
      case null { 0 };
      case (?s) { s }
    };
    let cs: ?(?CanisterState<Bucket, Nat>) =  Array.find<?CanisterState<Bucket, Nat>>(Array.freeze(canisters), 
        func(cs: ?CanisterState<Bucket, Nat>) : Bool {
          switch (cs) {
            case null { false };
            case (?cs) {
              Debug.print("found canister with principal..." # debug_show(Principal.toText(Principal.fromActor(cs.bucket))));
              // calculate if there is enough space in canister for the new file.
              cs.size + fs < threshold 
            };
          };
      });
    let eb : ?Bucket = do ? {
        let c = cs!;
        let nb: ?Bucket = switch (c) {
          case (?c) { ?(c.bucket) };
          case _ { null };
        };

        nb!;
    };
    let c: Bucket = switch (eb) {
        case null { await newEmptyBucket() };
        case (?eb) { eb };
    };
    c
  };
  // canister memory is set to 4GB and compute allocation to 5 as the purpose 
  // of this canisters is mostly storage
  // set canister owners to the wallet canister and the container canister ie: this
  func updateCanister(a: actor {}) : async () {
    Debug.print("balance before: " # Nat.toText(Cycles.balance()));
    // Cycles.add(Cycles.balance()/2);
    let cid = { canister_id = Principal.fromActor(a)};
    Debug.print("IC status..."  # debug_show(await IC.canister_status(cid)));
    // let cid = await IC.create_canister(  {
    //    settings = ?{controllers = [?(owner)]; compute_allocation = null; memory_allocation = ?(4294967296); freezing_threshold = null; } } );
    
    await (IC.update_settings( {
       canister_id = cid.canister_id; 
       settings = { 
         controllers = ?[owner, Principal.fromActor(this)];
         compute_allocation = null;
        //  memory_allocation = ?4_294_967_296; // 4GB
         memory_allocation = null; // 4GB
         freezing_threshold = ?31_540_000} })
    );
  };
  // go through each canister and check size
  public func updateStatus(): async () {
    for (i in Iter.range(0, canisters.size() - 1)) {
      let c : ?CanisterState<Bucket, Nat> = canisters[i];
      switch c { 
        case null { };
        case (?c) {
          let s = await c.bucket.getSize();
          let cid = { canister_id = Principal.fromActor(c.bucket)};
          // Debug.print("IC status..." # debug_show(await IC.canister_status(cid)));
          Debug.print("canister with id: " # debug_show(Principal.toText(Principal.fromActor(c.bucket))) # " size is " # debug_show(s));
          c.size := s;
          let _ = updateSize(Principal.fromActor(c.bucket), s);
        };
      }
    };
  };

  // get canisters status
  // this is cached until a new upload is made
  public query func getStatus() : async [(Principal, Nat)] {
    Iter.toArray<(Principal, Nat)>(canisterMap.entries());
  };

  // update hashmap 
  func updateSize(p: Principal, s: Nat) : () {
    var r = 0;
    if (s < threshold) {
      r := threshold - s;
    };
    let _ = canisterMap.replace(p, r);
  };

  // persist chunks in bucket
  public func putFileChunk(fileId: FileId, chunkNum : Nat, fileSize: Nat, chunkData : Blob) : async () {
    let b : Bucket = await getEmptyBucket(?fileSize);
    let _ = await b.putChunk(fileId, #nat_chunknum(chunkNum), chunkData);
  };

  // save file info 
  public func putFileInfo(fi: FileInfo) : async ?FileId {
    let b: Bucket = await getEmptyBucket(?fi.size);
    Debug.print("creating file info..." # debug_show(fi));
    let fileId = await b.putFile(fi);
    fileId
  };

  func getBucket(cid: Principal) : ?Bucket {
    let cs: ?(?CanisterState<Bucket, Nat>) =  Array.find<?CanisterState<Bucket, Nat>>(Array.freeze(canisters), 
        func(cs: ?CanisterState<Bucket, Nat>) : Bool {
          switch (cs) {
            case null { false };
            case (?cs) {
              Debug.print("found canister with principal..." # debug_show(Principal.toText(Principal.fromActor(cs.bucket))));
              Principal.equal(Principal.fromActor(cs.bucket), cid)
            };
          };
      });
      let eb : ?Bucket = do ? {
        let c = cs!;
        let nb: ?Bucket = switch (c) {
          case (?c) { ?(c.bucket) };
          case _ { null };
        };

        nb!;
    };
  };

  // get file chunk 
  public func getFileChunk(fileId : FileId, chunkNum : Nat, cid: Principal) : async ?Blob {
    do ? {
      let b : Bucket = (getBucket(cid))!;
      return await b.getChunks(fileId, #nat_chunknum(chunkNum));
    }   
  };

  // get file info
  public func getFileInfo(fileId : FileId, cid: Principal) : async ?FileData {
    do ? {
      let b : Bucket = (getBucket(cid))!;
      return await b.getFileInfo(fileId);
    }   
  };

    // delete file chunk
  public func delFileChunk(fileId: FileId, chunkNum : Nat, cid: Principal) : async ?() {
      do ? {
          let b : Bucket = (getBucket(cid))!;
          let _ = await b.delChunks(fileId, #nat_chunknum(chunkNum));
      }
  };

  // delete file info
  public func delFileInfo(fileId : FileId, cid: Principal) : async ?() {
      do ? {
        let b : Bucket = (getBucket(cid))!;
        let _ = await b.delFileInfo(fileId);
      }
  };

  // get a list of files from all canisters
  public func getAllFiles() : async [FileData] {
    let buff = Buffer.Buffer<FileData>(0);
    for (i in Iter.range(0, canisters.size() - 1)) {
      let c : ?CanisterState<Bucket, Nat> = canisters[i];
      switch c { 
        case null { };
        case (?c) {
          let bi = await c.bucket.getInfo();
          for (j in Iter.range(0, bi.size() - 1)) {
            buff.add(bi[j])
          };
        };
      }
    };
    buff.toArray()
  };  

  public shared({caller = caller}) func wallet_receive() : async () {
    ignore Cycles.accept(Cycles.available());
  };

  func ext2MIME(fileExt:FileExtension) : Text {
    switch fileExt {
      case(#jpeg){"image/jpeg"}; // are fallthroughs allowed?
      case(#jpg){"image/jpeg"};
      case(#png){"image/png"};
      case(#gif){"image/gif"};
      case(#svg){"image/svg+xml"};
      case(#mp3){"audio/mpeg"};
      case(#wav){"audio/wav"};
      case(#aac){"audio/aac"};
      case(#mp4){"video/mp4"};
      case(#avi){"video/x-msvideo"};
      case(#txt){"text/plain"};
      case(#html){"text/html"};
      case(#zip){"application/zip"};
      case(#json){"application/json"};
      case(#bin){"application/octet-stream"};
    };
  };

  public func http_request(req: HttpRequest) : async HttpResponse {
    // url format: <canisterid>.raw.ic0.app/storage?fileId=bucketId=<bucketId>&<fileId>&chunkNum=<chunkNum>
    // most images are only 1 chunk, so this will suffice for a profile picture or something
    // for later: output an httpstream, so we can load videos and progressive jpegwith a single link!
    var status_code=404;
    var headers = [("Content-Type",ext2MIME(#html))];
    var body:Blob = "404 Not Found";
    let _ = do ? { // is this possible without assignment
      let storageParams:Text = Text.stripStart(req.url, #text("/storage?"))!;
      let fields:Iter.Iter<Text> = Text.split(storageParams, #text("&"));
      var fileId:?FileId=null;
      var chunkNum:?ChunkNum=null;
      var bucketId:?Principal=null;
      for (field:Text in fields){
        let kv:[Text] = Iter.toArray<Text>(Text.split(field,#text("=")));
        if (kv[0]=="fileId"){
          fileId:=?kv[1];
        }
        else if (kv[0]=="chunkNum"){
          chunkNum:=?#text_chunknum(kv[1]);
        }
        else if (kv[0]=="bucketId"){
          bucketId:=?Principal.fromText(kv[1]);
        }
      };
      let b:Bucket = getBucket(bucketId!)!;
      let fileData:FileData = (await b.getFileInfo(fileId!))!;
      body := (await b.getChunks(fileId!, chunkNum!))!;
      headers := [("Content-Type",ext2MIME(fileData.extension)), ("certificate",Text.decodeUtf8(CertifiedData.getCertificate()!)!)];
      status_code:=200;
    };
    return {
      status_code=Nat16.fromNat(status_code);
      headers=headers;
      body=body;
    };
  };
};

  