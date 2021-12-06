import { writable, get } from "svelte/store";
import type { GraphqlClient } from "./graphqlClient";

import { s_identity, s_isLoggedIn, s_graphqlClient, s_authDataLoading } from "./authStore";
import type { Identity } from "@dfinity/agent";
import { uploadOrReplaceFile } from "./storageStore";
import type {UploadResult} from './storageStore'
import { push } from "svelte-spa-router";
import { encode as cborEncode, decode as cborDecode } from "@dfinity/agent/lib/cjs/cbor";

export const s_draftTitle = writable("")
export const s_draftDescription = writable("")
export const s_draftTags = writable([])
export const s_draftThumbnailUrl = writable("")
export const s_draft = writable({})
export const s_draftPreview = writable("")
export const s_uploadDraftLoading = writable(false)
export const s_draftPublishedDate = writable("")
export const s_blogComments=writable([])
export const s_blogArticlePublishedAt=writable("")
export const s_blogAuthor=writable({id:"",firstName:"",lastName:"",imgUrl:""})


const articleReturnSchema={
    content: true,
    title: true,
    publishedAt: true,
    thumbnailUrl: true,
    description: true,
    tags: {
        id: true
    },
    comments: {
        id: true,
        text: true,
        author: {
            id: true,
            firstName: true,
            lastName: true
        }
    },
    author: {
        id: true,
        firstName: true,
        lastName: true,
        imgUrl: true
    }
}

// fetch a list of authors and their articles, if authorId==null
// else fetch the author and articles written by authorId
export const fetchAuthors = async (authorId:String|null) => {
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    if (!graphqlClient){
        return []
    }
    const query = {
        query : {
            readAccount: {
                ...(authorId && {
                    __args: {
                        search: {
                            id: {eq:authorId}
                        }
                    }
                }),
                id: true,
                firstName: true,
                lastName: true,
                imgUrl: true,
                company: true,
                companyPosition: true,
                email: true,
                articles: {
                    id: true,
                    title: true,
                    description: true,
                    thumbnailUrl: true,
                    publishedAt: true,
                    tags: {
                        id: true
                    }
                },
            }
        }
    }
    const result = await graphqlClient.query(query)
    return result.data?.readAccount
}

export const fetchArticle = async (articleId) => {
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    if (!graphqlClient){
        return []
    }
    const query = {
        query: {
            readArticle: {
                __args: {
                    search: {
                        id: {
                            eq: articleId
                        }
                    }
                },
                ...articleReturnSchema
            }
        }
    };
    const result = await graphqlClient.query(query)
    return result.data?.readArticle
}

export const createOrUpdateArticle = async (articleId:String):Promise<string> => {
    const identity:Identity = get(s_identity)
    const draftPublishedDate = get(s_draftPublishedDate) 
    const isLoggedIn:boolean = get(s_isLoggedIn)
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    let resultArticleId=""
    if (articleId === "new"){
        articleId=null
    }
    if (identity && isLoggedIn && graphqlClient) {
        s_uploadDraftLoading.set(true)
        const draftDelta = get(s_draft)

        const mutateFn = (articleId ? "updateArticle" : "createArticle")
        const query = {
            mutation: {
                [mutateFn]: {
                    __args: {
                        input: {
                            ...(articleId && {id:articleId}),
                            ...(!draftPublishedDate && {publishedAt: new Date().toISOString()}),
                            content: btoa(escape(JSON.stringify(draftDelta))),
                            title: get(s_draftTitle),
                            description: get(s_draftDescription),
                            thumbnailUrl: get(s_draftThumbnailUrl),
                            ...(get(s_draftTags)==[] && {tags: get(s_draftTags)}),
                            author: {
                                connect: identity.getPrincipal().toString()
                            }
                        }
                    },
                    id: true
                }
            }
        }
        const result = await graphqlClient.mutation(query)
        console.log(result)
        if (result.data?.[mutateFn]?.length > 0) {
            resultArticleId = result.data[mutateFn][0].id
        }
    }
    push(`/blog/${resultArticleId}`)
    s_uploadDraftLoading.set(false)
    return resultArticleId
}

export const deleteArticle = async (articleId:String) => {
    const identity:Identity = get(s_identity)
    const isLoggedIn:boolean = get(s_isLoggedIn)
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    if (identity && isLoggedIn && graphqlClient) {
        s_uploadDraftLoading.set(true)
        const query = {
            mutation: {
                deleteArticle: {
                    __args: {
                        input: {
                            id: articleId
                        }
                    },
                    ...articleReturnSchema
                }
            }
        }
        const result = await graphqlClient.mutation(query)
        s_uploadDraftLoading.set(false)
        console.log(result)
        return result
        
    }
}

export const loadExistingArticle = async (articleId) => {
    s_uploadDraftLoading.set(true)
    let articles=await fetchArticle(articleId)
    if (articles.length > 0){
        const article=articles[0]
        s_draftDescription.set(article.description)
        s_draftThumbnailUrl.set(article.thumbnailUrl)
        s_draftTitle.set(article.title)
        s_draftTags.set(article.tags)
        s_draftPublishedDate.set(article.publishedAt)
        s_draft.set(JSON.parse(unescape(atob(article.content))))
        s_blogComments.set(article.comments)
        s_blogAuthor.set(article.author)
        s_blogArticlePublishedAt.set(article.publishedAt)
    }
    s_uploadDraftLoading.set(false)
    return articles
}

export const loadNewDraft = () => {
    s_draftTitle.set("")
    s_draftDescription.set("")
    s_draftThumbnailUrl.set("")
    s_draftPublishedDate.set("")
    s_draft.set("")
    s_draftPreview.set("")
    s_draftTags.set([])
    s_blogComments.set([])
    s_blogAuthor.set({id:"",firstName:"",lastName:"",imgUrl:""})
    s_blogArticlePublishedAt.set("")
}