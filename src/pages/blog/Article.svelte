<script lang="ts">
import { loadExistingArticle, s_draft, s_draftTitle, s_blogAuthor, s_blogArticlePublishedAt, s_draftDescription, deleteArticle, s_uploadDraftLoading } from "../../lib/blogStore";
import { onMount } from "svelte";
import { Icon, Spinner } from 'sveltestrap'
import { push, replace } from 'svelte-spa-router'
import { s_identity } from "../../lib/authStore";
import {get} from 'svelte/store'
import Quill from 'quill'

export let params = {articleId:"", edit:""}
let articleHtml=""
let articles=[]

onMount(async () => {
    articles=await loadExistingArticle(params.articleId)
    let articleDelta=get(s_draft)
    let tempContent = document.createElement("div")
    let q = new Quill(tempContent)
    q.setContents(articleDelta)
    articleHtml=tempContent.getElementsByClassName("ql-editor")[0].innerHTML
})

let prefix=`#/blog/${params.articleId}`
</script>


{#if $s_uploadDraftLoading}
<Spinner/>
{:else}
{#if articles.length > 0}
<div class="container text-secondary ql-editor">
    <h1 class="d-inline float-left">{$s_draftTitle}</h1>
    
    <!-- edit button -->
    {#if get(s_identity)?.getPrincipal().toString() === $s_blogAuthor.id}
    <span class="float-right">
        <button class="btn btn-default" on:click={async () => {
            if (confirm("Delete article?")){
                await deleteArticle(params.articleId)
                replace('#/blog')
            }
        }}>
            <Icon name="trash"/>
        </button>
        <button class="btn btn-default" on:click={async () => {
            push(`${prefix}/edit`)
        }}>
            <Icon name="pencil-fill"/>
        </button>
    </span>
    {/if}
    <p>Published on {$s_blogArticlePublishedAt}</p>
    <p id="description">{$s_draftDescription}</p>
    <div class="ql-editor">
        {@html articleHtml}
    </div>
</div>
{:else}
<h1>Article not found</h1>
{/if}

{/if}