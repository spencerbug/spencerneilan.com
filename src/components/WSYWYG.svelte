
<script lang="typescript">
    import { onMount } from "svelte"
    import { get, writable } from "svelte/store";
    import {ImageHandler, VideoHandler, AttachmentHandler } from "../lib/quill-upload";
    import ImageResize  from "../lib/quill-image-resize-module/ImageResize"
    import {uploadOrReplaceFile, uploadImage, uploadVideo} from "../lib/storageStore";
    import {s_draft, s_draftPreview} from "../lib/blogStore"
    import  BaseHandler  from "../lib/quill-upload/handlers/BaseHandler"

  

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

        Quill.register("modules/imageHandler", ImageHandler);
        Quill.register("modules/videoHandler", VideoHandler);
        Quill.register("modules/attachmentHandler", AttachmentHandler);
        Quill.register("modules/imageResize", ImageResize);

        let options={
            upload: async (file) => {
                return uploadImage(file)
            }
        }

        const dropFileUploadEvent = async (file, quill) => {
            let a
            const extension = file.name.split(".").pop();
            if (BaseHandler.isImage(extension)){
                a = new ImageHandler(quill, {upload: async (file) => {return uploadImage(file)}})
            }
            else if (BaseHandler.isVideo(extension)){
                a = new VideoHandler(quill, {upload: async (file) => {return uploadVideo(file)}})
            }
            else {
                a = new AttachmentHandler(quill, {upload: async (file) => {return uploadOrReplaceFile(file)}})
            }
            a.setRange(quill.getSelection())
            a.insertLoadingIcon()
            await a.embedFile(file)
        }

        // to upload our video chunks to IC, we need to break them up into small chunks and upload them.
        // On the display side, we should display a continuously growing video object blob.
        try {
            let quill = new Quill("#quill-editor", {
            modules: {
                toolbar: toolbarOptions,
                imageHandler: {upload: async (file) => {return uploadImage(file)}},
                videoHandler: {upload: async (file) => {return uploadVideo(file)}},
                attachmentHandler: {upload: async (file) => {return uploadOrReplaceFile(file)}},
                imageResize: {}
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

            // load existing draft if it exists
            let articleDelta = get(s_draft)
            quill.setContents(articleDelta)
            s_draftPreview.set(quill.container.firstChild.innerHTML)


            quill.on("text-change", function(delta, oldDelta, source){
                s_draft.set(quill.getContents())
                s_draftPreview.set(quill.container.firstChild.innerHTML)
            })
            
            quill.root.addEventListener('dragover', function(event){
                event.preventDefault()
                isDragging.set(true)
            }, false)
            quill.root.addEventListener('drop', async function(ev){
                ev.preventDefault()
                console.log(ev)
                isDragging.set(false)
                if (ev.dataTransfer.items) {
                    // Use DataTransferItemList interface to access the file(s)
                    for (let i = 0; i < ev.dataTransfer.items.length; i++) {
                        // If dropped items aren't files, reject them
                        if (ev.dataTransfer.items[i].kind === 'file') {
                            let file = ev.dataTransfer.items[i].getAsFile();
                            console.log('... file[' + i + '].name = ' + file.name);
                            await dropFileUploadEvent(file, quill)
                        }
                    }
                } else {
                    // Use DataTransfer interface to access the file(s)
                    for (let i = 0; i < ev.dataTransfer.files.length; i++) {
                        let file = ev.dataTransfer.files[i]
                        console.log('... file[' + i + '].name = ' + file.name);
                        await dropFileUploadEvent(file, quill)
                    }
                }
            })
            quill.root.addEventListener('dragleave', function(event){
                event.preventDefault()
                isDragging.set(false)
            
            })
        }
        catch(error) {
            // console.error(error)
        }
        

        
    })
</script>
  
<style>
@import 'https://cdn.quilljs.com/1.3.6/quill.snow.css';


:global(.ql-font-serif) {
    font-family: serif;
}
:global(.ql-font-monospace) {
    font-family:'Courier New', Courier, monospace
}
</style>
  
<div class="editor-wrapper">
    <div class="editor" id="quill-editor">
        {#if $isDragging}
            <p style="color:black">Place file here</p>
        {/if}
    </div>
</div>


  
