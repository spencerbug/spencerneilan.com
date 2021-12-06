import { writable, get } from "svelte/store";
import { s_agent, s_storageActor } from "./authStore";
import {idlFactory as bucket_idl} from "dfx-generated/bucket"
import type { FileData, _SERVICE as BUCKET_SERVICE } from "../backend/storage/bucket.types"
import type { _SERVICE as CONTAINER_SERVICE, FileId, FileInfo, FileUploadResult } from "../backend/storage/container.types"
import type { Principal } from '@dfinity/principal';
import { Actor, HttpAgent } from "@dfinity/agent";

export const s_uploadPostLoading = writable(false)

export interface UploadResult {
    url: string,
    id: string,
    text: string
}

export const uploadImage = async (file:File, fileUrl=""):Promise<UploadResult> => {
    return uploadOrReplaceFile(file, 'inline',fileUrl)
}

export const uploadVideo = async (file:File, fileUrl=""):Promise<UploadResult> => {
    return uploadOrReplaceFile(file, 'inline', fileUrl)
}

export const uploadOrReplaceFile = async (file:File, contentDisposition='', file_url=""):Promise<UploadResult> => {
    let storageActor:CONTAINER_SERVICE = get(s_storageActor)
    let agent:HttpAgent = get(s_agent)
    let principal=await agent.getPrincipal()
    console.log("principal is:", principal.toString())
    let value = {
        id: 'file0',
        url: '#',
        text: 'attachment'
    }
    let updating=false
    let fileId=""
    if (file_url){
        updating=true
        let splitStr = file_url.split("?")
        if (splitStr.length < 2){ return value }
        let queryString=splitStr[1]
        let urlSearchParams = new URLSearchParams(queryString)
        fileId=urlSearchParams.get('fileId')
    }
    //calculateNumber of chunks
    let max_chunk_size=1900000
    let numChunks = BigInt(Math.ceil(file.size / max_chunk_size))

    //create FileInfo struct
    let urlEncodedName = encodeURIComponent(file.name)
    if (!contentDisposition) {
        contentDisposition = `attachment; filename="${file.name}"`
    }
    let fileInfo:FileInfo = {
        name: urlEncodedName,
        createdAt: BigInt(file.lastModified),
        size: BigInt(file.size),
        chunkCount: numChunks,
        filetype: file.type,
        contentDisposition
    }

    //reserve file space and upload information  and get resulting bucketId and fileId
    let result:[]|[FileUploadResult]
    try {
        if (updating && fileId){
            result=await storageActor.updateReserveFile(fileId, fileInfo)
        }
        else {
            result=await storageActor.reserveFile(fileInfo)
        }
    }
    catch (error){
        alert(error)
        return value
    }
    if (result.length == 0) {return value}
    let bucketId:Principal = result[0].bucketId
    fileId = result[0].fileId

    // start uploading our chunks (TODO: Track progress with progressbar)
    let bucketActor:BUCKET_SERVICE=Actor.createActor(bucket_idl, {agent, canisterId:bucketId})
    let chunk_num:bigint=BigInt(1);
    for (let s=0; s < file.size; s+=max_chunk_size, chunk_num++){

        let e=Math.min(file.size, s+max_chunk_size)
        let chunk:Blob = file.slice(s,e, file.type)
        let buf=await chunk.arrayBuffer()
        let result = await bucketActor.putChunks(fileId, chunk_num, Array.from(new Uint8Array(buf)))
        if (result == [null]){
            console.log("error uploading chunk")
            return value
        }
    }

    //generate resulting URL to read file
    let baseurl="raw.ic0.app"
    let protocol="https"
    if (import.meta.env.MODE == "development"){
        baseurl="raw.localhost:8000"
        protocol="http"
    }
    value.url = `${protocol}://${baseurl}/storage?fileId=${fileId}&canisterId=${bucketId}`
    value.text = file.name
    value.id = fileId
    return value
}

export const listFiles = async ():Promise<Array<[Principal, FileData]>> => {
    let storageActor:CONTAINER_SERVICE = get(s_storageActor)
    return await storageActor.getAllFiles()
}

export const deleteFile = async (bucketId:Principal, fileId:FileId):Promise<Boolean> => {
    let agent = get(s_agent)
    let bucketActor:BUCKET_SERVICE=Actor.createActor(bucket_idl, {agent, canisterId:bucketId})
    let result = await bucketActor.deleteFile(fileId)
    if (result == [null]){return false}
    else return true
}