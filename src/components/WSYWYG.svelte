<script>
    import { onMount } from "svelte"
    import ImageUploader from "quill-image-uploader/src/quill.imageUploader";
    import { writable } from "svelte/store";
  
    let editor
    let contents

    let isDragging = writable(false)
      
    export let toolbarOptions = [
        [{header: [1,2,3,false]}],
        ["blockquote", "link", "image", "video"],
        ["bold", "italic", "underline", "strike"],
        [{ list: "ordered" }, { list: "bullet" }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'font': [] }],
        [{ align: [] }],
        ["clean"]
    ];
      
    onMount(async () => {
        const { default: Quill } = await import("quill");

        Quill.register("modules/imageUploader", ImageUploader);

        let quill = new Quill(editor, {
        modules: {
            toolbar: toolbarOptions,
            imageUploader: {
                upload: (file) => {
                    return new Promise((resolve, reject) => {
                        setTimeout(() => {
                            console.log(file)
                            resolve("https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/JavaScript-logo.png/480px-JavaScript-logo.png")
                        }, 3500)
                    })
                }
            }
        },
        theme: "snow",
        placeholder: "Write your article here..."
        })

        quill.on("text-change", function(delta, oldDelta, source){
            contents = quill.container.firstChild.innerHTML
            document.getElementById("preview").innerHTML = contents
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
  
  <div class="editor-wrapper">
    <div class="editor" bind:this={editor}>
        {#if $isDragging}
            <p style="color:black">Place file here</p>
        {/if}
    </div>
  </div>


  <div id="preview"></div>

  <!-- {@html contents} -->