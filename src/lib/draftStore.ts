import { writable, get } from "svelte/store";
import { GraphqlClient } from "./graphqlClient";
import { s_identity, s_isLoggedIn, s_graphqlClient } from "./authStore";
import type { Identity } from "@dfinity/agent";
import { uploadFile, UploadResult } from "./storageStore";

// state for draft (writing blog post articles)

export const s_draftTitle = writable("")
export const s_draftDescription = writable("")
export const s_draftTags = writable([])
export const s_draftThumbnailUrl = writable("")
export const s_draft = writable("")
export const s_draftId = writable("")
export const s_uploadDraftLoading = writable(false)
export const s_draftPublishedDate = writable("")

export const createOrUpdateArticle = async (articleUrl:String) => {
    
    const identity:Identity = get(s_identity)
    const draftId = get(s_draftId)
    const draftPublishedDate = get(s_draftPublishedDate) 
    const isLoggedIn:boolean = get(s_isLoggedIn)
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    if (identity && isLoggedIn && graphqlClient) {
        s_uploadDraftLoading.set(true)
        const mutateFn = (s_draftId ? "updateArticle" : "createArticle")
        const query = {
            mutation: {
                [mutateFn]: {
                    __args: {
                        input: {
                            ...(draftId && {id:draftId}),
                            ...(!draftPublishedDate && {publishedAt: new Date().toISOString()}),
                            articleUrl,
                            title: get(s_draftTitle),
                            description: get(s_draftDescription),
                            thumbnailUrl: get(s_draftThumbnailUrl),
                            tags: get(s_draftTags)
                        }
                    },
                    id: true
                }
            }
        }
        const result = await graphqlClient.query(query)
        console.log(result)
        if (result.data?.[mutateFn]?.length > 0) {
            s_draftId.set(result.data[mutateFn].id)
        }
        s_uploadDraftLoading.set(false)
    }
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
        [new Blob([get(s_draft)], {type: 'text/html'})],
        `${get(s_draftTitle)}.html`,
    )
    let result:UploadResult = await uploadFile(htmlFile)
    console.log(result)
    if (result.url !== '#') {
        await createOrUpdateArticle(result.url)
    }
    
    
}

export const loadDraft = async () => {

}