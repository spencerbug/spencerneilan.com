import type { Principal } from '@dfinity/principal';
export interface Container {
  'getAllFiles' : () => Promise<Array<[Principal, FileData]>>,
  'getStatus' : () => Promise<Array<[Principal, bigint]>>,
  'reserveFile' : (arg_0: FileInfo) => Promise<[] | [FileUploadResult]>,
  'updateReserveFile' : (arg_0: FileId, arg_1: FileInfo) => Promise<
      [] | [FileUploadResult]
    >,
  'updateStatus' : () => Promise<undefined>,
  'wallet_balance' : () => Promise<bigint>,
  'wallet_receive' : () => Promise<undefined>,
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
export interface FileUploadResult {
  'bucketId' : Principal,
  'fileId' : FileId__1,
}
export type Timestamp = bigint;
export interface _SERVICE extends Container {}
