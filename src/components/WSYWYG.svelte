<script lang="typescript">
    import { onMount } from "svelte"
    import { writable, get } from "svelte/store";
    import {AttachmentHandler} from "../lib/quill-upload"
    // import {ImageHandler, VideoHandler, AttachmentHandler } from "../lib/quill-upload";
    import { uploadFile, publishDraft, loadDraft, s_currentDraft, s_currentTitle } from "../lib/contentStore";
    import { Form, FormGroup, Button, Input, Label } from 'sveltestrap'

  
    let editor

    let isDragging = writable(false)

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
        


        // Quill.register("modules/imageUploader", ImageHandler);
        // Quill.register("modules/videoHandler", VideoHandler);
        Quill.register("modules/attachmentHandler", AttachmentHandler);

        // to upload our video chunks to IC, we need to break them up into small chunks and upload them.
        // On the display side, we should display a continuously growing video object blob.

        let quill = new Quill("#quill-editor", {
        modules: {
            toolbar: toolbarOptions,
            // imageHandler: {
            //     upload: async (file) => {
            //         return uploadFile(file)
            //     }
            // },
            // videoHandler: {
            //     upload: async (file) => {
            //         return uploadFile(file)
            //     }
            // },
            attachmentHandler: {
                upload: async (file) => {
                    return uploadFile(file)
                }
            }
        },
        theme: "snow",
        placeholder: "Write your article here..."
        })

        // bandaid for duplicate toolbar bug
        let toolbars=document.getElementsByClassName("ql-toolbar")
        if (toolbars.length > 1){
            toolbars[0].remove()
        }

        // manually add the attachments svg icon
        let attachmentButton = document.getElementsByClassName('ql-attachment')
        if (attachmentButton.length > 0){
            const icon = document.createElement('img')
            icon.setAttribute('src','paperclip.svg')
            icon.setAttribute('class', 'align-top')
            attachmentButton[0].appendChild(icon)
        }

        quill.on("text-change", function(delta, oldDelta, source){
            s_currentDraft.set(quill.container.firstChild.innerHTML)
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
          <Input type="text" bind:value={$s_currentTitle} id="title" placeholder="Title" required={true}/>
      </FormGroup>
      <FormGroup>
        <div class="editor-wrapper">
            <div class="editor" id="quill-editor">
                <!-- {#if $isDragging}
                    <p style="color:black">Place file here</p>
                {/if} -->
            </div>
            <div id="preview">
                {@html $s_currentDraft}
            </div>
        </div>
      </FormGroup>
      <Button color="primary" type="submit">Publish</Button>
    </form>



  
