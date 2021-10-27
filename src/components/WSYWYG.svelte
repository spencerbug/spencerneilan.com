<script lang="typescript">
    import { onMount } from "svelte"
    import { writable, get } from "svelte/store";
    import {ImageHandler, VideoHandler, AttachmentHandler } from "../lib/quill-upload";
    import { uploadFile, publishDraft, loadDraft, s_currentDraft, s_currentTitle } from "../lib/contentStore";
    import { Form, FormGroup, Button, Input, Label } from 'sveltestrap'
  
    let editor

    let isDragging = writable(false)

    // class QuillAttachments {
    //     constructor(quill, options) {
    //         this.quill = quill
    //         this.options = options
    //         this.container = document.querySelector(options.container)
    //         this.handlers = ["attachment", "image", "video"]
    //     }

    // }
      
    export let toolbarOptions = [
        [{header: [1,2,3,false]}],
        ["blockquote", "link", "image", "video", "attachment"],
        ["bold", "italic", "underline", "strike"],
        [{ list: "ordered" }, { list: "bullet" }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'font': [] }],
        [{ align: [] }],
        ["clean"]
    ];

      
    onMount(async () => {
        const { default: Quill } = await import("quill");
        


        Quill.register("modules/imageUploader", ImageHandler);
        Quill.register("modules/videoHandler", VideoHandler);
        Quill.register("modules/attachmentHandler", AttachmentHandler);

        // to upload our video chunks to IC, we need to break them up into small chunks and upload them.
        // On the display side, we should display a continuously growing video object blob.


        let quill = new Quill(editor, {
        modules: {
            toolbar: toolbarOptions,
            imageHandler: {
                upload: async (file) => {
                    return uploadFile(file)
                }
            },
            videoHandler: {
                upload: async (file) => {
                    return uploadFile(file)
                }
            },
            attachmentHandler: {
                upload: async (file) => {
                    return uploadFile(file)
                }
            }
        },
        theme: "snow",
        placeholder: "Write your article here..."
        })

        quill.on("text-change", function(delta, oldDelta, source){
            let contentnode = quill.container.firstChild
            contentnode.insertAdjacentHTML("afterbegin", `<h1>${get(s_currentTitle)}</h1>`)
            s_currentDraft.set(contentnode.innerHTML)
        })

        quill.root.addEventListener('dragover', function(event){
            event.preventDefault()
            isDragging.set(true)
        }, false)
        quill.root.addEventListener('drop', function(event){
            event.preventDefault()
            isDragging.set(false)
        })
        quill.root.addEventListener('dragleave', function(event){
            event.preventDefault()
            isDragging.set(false)
        })
    })
  
  </script>
  
  <style>
    @import 'https://cdn.quilljs.com/1.3.6/quill.snow.css';
    .editor {
        color: var(--bs-dark);
    }
    #preview {
        color: var(--bs-gray-dark);
    }

    :global(.ql-font-serif) {
        font-family: serif;
    }
    :global(.ql-font-monospace) {
        font-family:'Courier New', Courier, monospace
    }
  </style>
  
  
  <form on:submit|preventDefault={async event => await publishDraft()}>
      <FormGroup>
          <Label for="title">Title</Label>
          <Input type="text" bind:value={$s_currentTitle} id="title"/>
      </FormGroup>
      <FormGroup>
        <div class="editor-wrapper">
            <div class="editor" bind:this={editor}>
                {#if $isDragging}
                    <p style="color:black">Place file here</p>
                {/if}
            </div>
          </div>
      </FormGroup>
      <Button color="primary" type="submit">Publish</Button>
    </form>


  <div id="preview">
      {$s_currentDraft}
  </div>
  
