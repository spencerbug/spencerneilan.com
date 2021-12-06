import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import List "mo:base/List";
import Error "mo:base/Error";
import Types "./Types";
import Buckets "./Buckets";
import IC "./IC";


// Container actor holds all created canisters in a canisters array 
// Use of IC management canister with specified Principal "aaaaa-aa" to update the newly 
// created canisters permissions and settings 
//  https://sdk.dfinity.org/docs/interface-spec/index.html#ic-management-canister
shared ({caller = owner}) actor class Container() = this {

  type Bucket = Buckets.Bucket;
  type Service = Types.Service;
  type FileId = Types.FileId;
  type FileInfo = Types.FileInfo;
  type FileData = Types.FileData;
  type FileUploadResult = Types.FileUploadResult;

  let ic:IC.IC = actor("aaaaa-aa");

// canister info hold an actor reference and the result from rts_memory_size
  type CanisterState = {
    bucket  : Bucket;
    var size : Nat;
  };

  type SharedCanisterState = {
    bucket: Bucket;
    size: Nat;
  };

  private stable var stableCanisters: [CanisterState] = [];

  // restore state from memory
  private var canisters:List.List<CanisterState> = 
    List.fromArray<CanisterState>(stableCanisters);

  // canister map is a cached way to fetch canisters info
  // this will be only updated when a file is added 
  // restore this from stable memory as well
  private let canisterMap = HashMap.fromIter<Principal, Nat>(
    Iter.map<CanisterState, (Principal, Nat)>(
      Iter.fromArray<CanisterState>(stableCanisters),
      func(cs:CanisterState):(Principal, Nat) {
        (
          Principal.fromActor(cs.bucket),
          cs.size
        )
      }
    ),
    100,
    Principal.equal,
    Principal.hash
  );
  
  system func preupgrade() {
    stableCanisters := List.toArray(canisters);
  };

  system func postupgrade() {
    stableCanisters := [];
  };


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
     var v : CanisterState = {
         bucket = b;
         var size = s;
    };
    canisters := List.push<CanisterState>(v, canisters);
  
    b;
  };

  // check if there's an empty bucket we can use
  // create a new one in case none's available or have enough space 
  func getEmptyBucket(s : ?Nat): async Bucket {
    let fs: Nat = switch (s) {
      case null { 0 };
      case (?s) { s }
    };
    let cs:?CanisterState = List.find<CanisterState>(canisters,
      func(_cs:CanisterState):Bool {
        Debug.print("found canister with principal..." # debug_show(Principal.toText(Principal.fromActor(_cs.bucket))));
        _cs.size + fs < threshold
      }
    );
    let eb : ?Bucket = do ? {
        let c = cs!;
        c.bucket
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
    Debug.print("IC status..."  # debug_show(await ic.canister_status(cid)));
    // let cid = await IC.create_canister(  {
    //    settings = ?{controllers = [?(owner)]; compute_allocation = null; memory_allocation = ?(4294967296); freezing_threshold = null; } } );
    
    await (ic.update_settings( {
       canister_id = cid.canister_id; 
       settings = { 
         controllers = ?[owner, Principal.fromActor(this)];
         compute_allocation = null;
        //  memory_allocation = ?4_294_967_296; // 4GB
         memory_allocation = null; // 4GB
         freezing_threshold = ?31_540_000} })
    );
  };

  func asyncIterateList<T>(l:List.List<T>, f : T -> async ()): async () {
    switch (l) {
      case null { () };
      case (?(h, t)) {
        await f(h);
        await asyncIterateList<T>(t,f)
      };
    }
  };

  // find first occurence in a linkedlist, using an async bool function
  // we can't use polymorphism for async functions, so this needs to return a spefic type
  func asyncIterateFindList(l:List.List<CanisterState>, f: CanisterState -> async Bool.Bool): async ?SharedCanisterState {
    switch l {
      case null { null };
      case (?(cs:CanisterState, next)) {
        if (await f(cs)) {
          ?{
            bucket=cs.bucket;
            size=cs.size;
          }
         }
        else { await asyncIterateFindList(next, f);}
      };
    };
  };

  // go through each canister and check size
  public func updateStatus(): async () {
    await asyncIterateList<CanisterState>(canisters, func (cs:CanisterState): async (){
      let s:Nat = await cs.bucket.getSize();
      Debug.print("canister with id: " # debug_show(Principal.toText(Principal.fromActor(cs.bucket))) # " size is " # debug_show(s));
      cs.size := s;
      let _ = updateSize(Principal.fromActor(cs.bucket), s);
    });
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

  // allocate storage space in a new or existing bucket
  // must be followed by putChunks
  public shared(msg) func reserveFile(fi:FileInfo) : async ?FileUploadResult {
    // go through buckets, and attempt to reserve the size
    var fileId:FileId = "";
    let scs:?SharedCanisterState = await asyncIterateFindList(canisters, 
      func (cs:CanisterState): async Bool.Bool {
      switch(await cs.bucket.reserve(fi, msg.caller)) {
        case (?fid) {
          fileId := fid;
          true
        };
        case null {
          false
        };
      };
    });
    let cs:?CanisterState = switch(scs){
      case(?scs){ ?{bucket=scs.bucket; var size=scs.size;} };
      case null { null };
    };
    

    // return ?FileUploadResult
    do ?{
      switch(cs){
        case (?cs) { 
          Debug.print("found canister with principal..." # debug_show(Principal.toText(Principal.fromActor(cs.bucket))));
          {
            fileId = fileId;
            bucketId = Principal.fromActor(cs.bucket);
          }
        };
        case null { 
          // create new bucket if there wasnt enough space on existing bucket
          let b:Bucket = await newEmptyBucket();
          let fid:FileId = (await b.reserve(fi, msg.caller))!;
          {
            bucketId = Principal.fromActor(b);
            fileId = fid;
          }
        };
      };
    }
  };

  // update the allocation of an existing file in a bucket
  // (or delete it if the new size is larger, and put it in a new bucket)
  // must be followed by putChunks
  /*
  1) Call reserveUpdate(fileId, fileInfo) -> async ?ReservedSize
  1b) If null, move on to next bucket and call reserve(), or create new bucket and call reserve()
  2) Repeatedly call putChunks(fileId, chunkNum, chunkData) -> ?()
  */
  public shared(msg) func updateReserveFile(fileId:FileId, fi:FileInfo) : async ?FileUploadResult {
    let cs:?SharedCanisterState = await asyncIterateFindList(canisters, 
      func (cs:CanisterState): async Bool.Bool {
        Debug.print("calling reserveUpdate on "#debug_show(Principal.fromActor(cs.bucket)));
        switch(await cs.bucket.reserveUpdate(fileId, fi, msg.caller)){
          case(?reservedSize){ true };
          case null { false };
        };
    });
    do ?{
      switch(cs){
        case (?cs){
          Debug.print("found canister with principal..." # debug_show(Principal.toText(Principal.fromActor(cs.bucket))));
          {
            fileId = fileId;
            bucketId = Principal.fromActor(cs.bucket);
          }
        };
        case null {
          Debug.print("Need to make new bucket");
          null!
          // let b:Bucket = await newEmptyBucket();
          // {
          //   fileId = (await b.reserve(fi, msg.caller))!;
          //   bucketId = Principal.fromActor(b);
          // }
        };
      };
    };
  };

  // get a list of files from all canisters
  public func getAllFiles() : async [(Principal, FileData)] {
    let buff = Buffer.Buffer<(Principal, FileData)>(0);
    await asyncIterateList<CanisterState>(
      canisters,
      func (cs:CanisterState): async (){
        let bi = await cs.bucket.getInfo();
        for (j in Iter.range(0, bi.size() - 1)) {
          buff.add((Principal.fromActor(cs.bucket),bi[j]));
        };
      }
    );
    buff.toArray()
  };  

  public func listBuckets(): async [Principal] {
    List.toArray<Principal>(
      List.map<CanisterState, Principal>(canisters, func(cs:CanisterState):Principal{
        Principal.fromActor(cs.bucket)
      })
    )
  };

  public shared(msg) func wallet_receive() : async () {
    ignore Cycles.accept(Cycles.available());
  };

  public shared(msg) func wallet_balance() : async Nat {
    return Cycles.balance();
  };
};

  