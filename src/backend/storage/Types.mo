import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Blob "mo:base/Blob";

module {

  public type FileId = Text;
  
  public type Timestamp = Int; // See mo:base/Time and Time.now()

  public type ChunkData = Blob;

  public type ChunkId = Text; 

  type ReservedSize = Nat;

  public type FileInfo = {
    createdAt : Timestamp;
    chunkCount: Nat;    
    name: Text;
    size: Nat;
    filetype: Text;
    contentDisposition: Text;
  }; 

  public type FileData = {
    fileId : FileId;
    cid : Principal;
    uploadedAt : Timestamp;
    createdAt : Timestamp;
    chunkCount: Nat;    
    name: Text;
    size: Nat;
    filetype: Text;
    contentDisposition: Text;
  };

  public type FileUploadResult = {
    bucketId: Principal;
    fileId: FileId;
  };

  public type Service = actor {
    getSize : shared () -> async Nat;
    putFileChunk : shared (FileId, Nat, Blob) -> async ?Principal;
    putFileInfo : shared FileInfo -> async ?FileUploadResult;
    getFileChunk: shared (FileId, Nat, Principal) -> async ?Blob;
    getFileInfo: shared (FileId, Principal) -> async ?FileData;
    delFileChunk : shared (FileId, Nat, Principal) -> async ();
    delFileInfo : shared (FileId, Principal) -> async ();
    getAllFiles : shared () -> async [FileData];
  };

  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

  public type State = {
      files : Map<FileId, FileData>;
      // all chunks.
      chunks : Map<ChunkId, ChunkData>;
  };

  public type StableState = {
    files: [(FileId, FileData)];
    chunks: [(ChunkId, ChunkData)];
  };

  public func empty () : State {
    let st : State = {
      files = TrieMap.TrieMap<FileId, FileData>(Text.equal, Text.hash);
      chunks = TrieMap.TrieMap<ChunkId, ChunkData>(Text.equal, Text.hash);
    };
    st
  };

  public type StreamingCallbackToken = {
    key : Text;
    content_encoding : Text;
    index : Nat; //starts at 1
    sha256: ?[Nat8];
  };

  public type StreamingCallbackHttpResponse = {
    token : ?StreamingCallbackToken;
    body : [Nat8];
  };

  public type StreamingCallback = query StreamingCallbackToken  -> async StreamingCallbackHttpResponse;


  public type StreamingStrategy = {
    #Callback: {
      token : StreamingCallbackToken;
      callback : StreamingCallback
    }
  };

  public type HttpRequest = {
    method: Text;
    url: Text;
    headers: [(Text, Text)];
    body: Blob;
  };
  public type HttpResponse = {
    status_code: Nat16;
    headers: [(Text, Text)];
    body: Blob;
    streaming_strategy : ?StreamingStrategy;
  };

  
}