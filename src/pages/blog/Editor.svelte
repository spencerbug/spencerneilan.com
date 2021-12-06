<script lang="ts">
import { loadExistingArticle, loadNewDraft, s_draftPreview, s_draftDescription, s_draftTitle, s_uploadDraftLoading, createOrUpdateArticle } from "../../lib/blogStore";
import { Button, FormGroup, Input, Label, Spinner } from "sveltestrap";

import WSYWYG from "../../components/WSYWYG.svelte"
import { onMount } from "svelte";

export let params={articleId:""}

onMount(async ()=>{
    if (params.articleId === "new"){
        loadNewDraft()
    }
    else {
        await loadExistingArticle(params.articleId)
    }
})
</script>

{#if $s_uploadDraftLoading}
<Spinner/>
{:else}

<FormGroup>
<Label for="title">Title</Label>
<Input type="text" bind:value={$s_draftTitle} id="title" placeholder="Title" required={true}/>

<Label for="description">Description</Label>
<Input type="text" bind:value={$s_draftDescription} id="description" placeholder="Description"/>
</FormGroup>

<!-- to do: Add tags input -->


<WSYWYG/>

<Button color="primary" type="button" on:click={async () => await createOrUpdateArticle(params.articleId)}>Publish</Button>

<div id="preview" class="text-secondary ql-editor">
    <h1>{$s_draftTitle}</h1>
    <h3>{$s_draftDescription}</h3>
    {@html $s_draftPreview}
</div>
{/if}




