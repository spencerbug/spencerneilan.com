import { writable, get } from "svelte/store";
import { s_storageActor } from "./authStore";
// import {idlFactory as storage_idl} from "dfx-generated/storage"
import type { FileInfo, FileId, FileUploadResult, _SERVICE } from "../backend/storage/types"
import type { Principal } from '@dfinity/principal';

export const s_uploadPostLoading = writable(false)
export const s_currentDraft = writable("")
export const s_currentTitle = writable("")

export interface UploadResult {
    url: string,
    id: string,
    text: string
}

export const uploadFile = async (file:File):Promise<UploadResult> => {
    let storageActor:_SERVICE = get(s_storageActor)
    let max_chunk_size=1900000
    let numChunks = BigInt(Math.ceil(file.size / max_chunk_size))
    let value = {
        id: 'file0',
        url: '#',
        text: 'attachment'
    }
    //upload file information
    let urlEncodedName = encodeURIComponent(file.name)
    let fileInfo:FileInfo = {
        name: urlEncodedName,
        createdAt: BigInt(file.lastModified),
        size: BigInt(file.size),
        chunkCount: numChunks,
        filetype: file.type 
    }
    let result:[]|[FileUploadResult]=await storageActor.putFileInfo(fileInfo)
    if (result.length == 0) {return value}
    let bucketId:Principal = result[0].bucketId
    let fileId:FileId = result[0].fileId

    // start uploading our chunks
    let chunk_num:bigint=BigInt(1);
    for (let s=0; s < file.size; s+=max_chunk_size, chunk_num++){
        
        let e=Math.min(file.size, s+max_chunk_size)
        let chunk:Blob = file.slice(s,e, file.type)
        let buf=await chunk.arrayBuffer()
        let newBucketId:Principal = await storageActor.putFileChunk(fileId, chunk_num, Array.from(new Uint8Array(buf)))
        if (newBucketId.toText != bucketId.toText){
            console.log("Warning! File chunks expand across multiple canisters. This file cannot be downloaded with a direct link until canister2canister queries are implemented on the IC")
        }
    }
    let baseurl="raw.ic0.app"
    let protocol="https"
    if (import.meta.env.MODE == "development"){
        baseurl="localhost:8000"
        protocol="http"
    }
    value.url = `${protocol}://${baseurl}/storage?fileId=${fileId}&chunkNum=1&canisterId=${bucketId}`
    value.text = file.name
    value.id = fileId
    return value
}






// information we need:
/* 
Principal, title, article HTML, 
we don't want to be currently uploading a file
delete the old copy, and upload the newcopy
Or we can upload the deltas
*/
export const publishDraft = async () => {

    let htmlFile:File = new File(
        [new Blob([get(s_currentDraft)], {type: 'text/html'})],
        `${get(s_currentTitle)}.html`,
    )
    let result:UploadResult = await uploadFile(htmlFile)
    
}

export const loadDraft = async () => {

}