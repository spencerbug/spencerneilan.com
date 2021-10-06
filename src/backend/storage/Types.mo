import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Blob "mo:base/Blob";

module {
  
  public type Service = actor {
    getSize : shared () -> async Nat;
    putFileChunk : shared (FileId, ChunkNum, Blob) -> async ?();
    putFile : shared FileInfo -> async ?FileId;
    getFileChunk: shared (FileId, ChunkNum, Principal) -> async ?Blob;
    getFileInfo: shared (FileId, Principal) -> async ?FileData;
    delFileChunk : shared (FileId, ChunkNum, Principal) -> async ();
    delFileInfo : shared (FileId, Principal) -> async ();
    getAllFiles : shared () -> async [FileData];
  };
  
  public type Timestamp = Int; // See mo:base/Time and Time.now()

  public type FileId = Text;

  public type ChunkData = Blob;

  public type ChunkId = Text; 
  

  public type FileExtension = {
    #jpeg;
    #jpg;
    #png;
    #gif;
    #svg;
    #mp3;
    #wav;
    #aac;
    #mp4;
    #avi;
    #txt;
    #html;
    #zip;
    #json;
    #bin;
  };

  public type ChunkNum = {
    #text_chunknum:Text;
    #nat_chunknum:Nat;
  };
  

  public type FileInfo = {
    createdAt : Timestamp;
    chunkCount: Nat;    
    name: Text;
    size: Nat;
    extension: FileExtension;
  }; 

  public type FileData = {
    fileId : FileId;
    cid : Principal;
    uploadedAt : Timestamp;
    createdAt : Timestamp;
    chunkCount: Nat;    
    name: Text;
    size: Nat;
    extension: FileExtension;
  };

  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

  public type State = {
      files : Map<FileId, FileData>;
      // all chunks.
      chunks : Map<ChunkId, ChunkData>;
  };

  public func empty () : State {
    let st : State = {
      files = TrieMap.TrieMap<FileId, FileData>(Text.equal, Text.hash);
      chunks = TrieMap.TrieMap<ChunkId, ChunkData>(Text.equal, Text.hash);
    };
    st
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
  };

  
}