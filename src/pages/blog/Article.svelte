<script lang="ts">
import { loadExistingArticle, s_draft, s_draftTitle, s_blogAuthor, s_blogArticlePublishedAt, s_draftDescription } from "../../lib/blogStore";
import { onMount } from "svelte";
import { Icon } from 'sveltestrap'
import { push } from 'svelte-spa-router'
import { s_identity } from "../../lib/authStore";
import {get} from 'svelte/store'
import Quill from 'quill'

export let params = {articleId:"", edit:""}
let articleHtml=""

onMount(async () => {
    await loadExistingArticle(params.articleId)
    let articleDelta=get(s_draft)
    let tempContent = document.createElement("div")
    let q = new Quill(tempContent)
    q.setContents(articleDelta)
    articleHtml=tempContent.getElementsByClassName("ql-editor")[0].innerHTML
})

let prefix=`/blog/${params.articleId}`
</script>


<div class="container text-secondary ql-editor">
    <h1 class="d-inline float-left">{$s_draftTitle}</h1>
    
    <!-- edit button -->
    {#if get(s_identity)?.getPrincipal().toString() === $s_blogAuthor.id}
    <button class="btn btn-default d-inline float-right" on:click={async () => {
        push(`${prefix}/edit`)
    }}>
        <Icon name="pencil-fill"/>
    </button>
    {/if}
    <p>Published on {$s_blogArticlePublishedAt}</p>
    <p id="description">{$s_draftDescription}</p>
    <div class="ql-editor">
        {@html articleHtml}
    </div>
</div>

