import type { Principal } from '@dfinity/principal';
export interface Bucket {
  'deleteFile' : (arg_0: FileId) => Promise<[] | [null]>,
  'generateRandom' : (arg_0: string) => Promise<string>,
  'getFileInfo' : (arg_0: FileId) => Promise<[] | [FileData]>,
  'getInfo' : () => Promise<Array<FileData>>,
  'getSize' : () => Promise<bigint>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'putChunks' : (arg_0: FileId, arg_1: bigint, arg_2: Array<number>) => Promise<
      [] | [null]
    >,
  'reservationGarbageCollect' : () => Promise<undefined>,
  'reserve' : (arg_0: FileInfo) => Promise<[] | [FileId]>,
  'reserveUpdate' : (arg_0: FileId, arg_1: FileInfo) => Promise<[] | [bigint]>,
  'streamingCallback' : (arg_0: StreamingCallbackToken) => Promise<
      StreamingCallbackHttpResponse
    >,
  'wallet_balance' : () => Promise<bigint>,
  'wallet_receive' : () => Promise<{ 'accepted' : bigint }>,
}
export interface FileData {
  'cid' : Principal,
  'contentDisposition' : string,
  'name' : string,
  'createdAt' : Timestamp,
  'size' : bigint,
  'filetype' : string,
  'fileId' : FileId__1,
  'chunkCount' : bigint,
  'uploadedAt' : Timestamp,
}
export type FileId = string;
export type FileId__1 = string;
export interface FileInfo {
  'contentDisposition' : string,
  'name' : string,
  'createdAt' : Timestamp,
  'size' : bigint,
  'filetype' : string,
  'chunkCount' : bigint,
}
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<[string, string]>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<[string, string]>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export type StreamingCallback = (arg_0: StreamingCallbackToken__1) => Promise<
    StreamingCallbackHttpResponse__1
  >;
export interface StreamingCallbackHttpResponse {
  'token' : [] | [StreamingCallbackToken__1],
  'body' : Array<number>,
}
export interface StreamingCallbackHttpResponse__1 {
  'token' : [] | [StreamingCallbackToken__1],
  'body' : Array<number>,
}
export interface StreamingCallbackToken {
  'key' : string,
  'sha256' : [] | [Array<number>],
  'index' : bigint,
  'content_encoding' : string,
}
export interface StreamingCallbackToken__1 {
  'key' : string,
  'sha256' : [] | [Array<number>],
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken__1,
      'callback' : StreamingCallback,
    }
  };
export type Timestamp = bigint;
export interface _SERVICE extends Bucket {}
