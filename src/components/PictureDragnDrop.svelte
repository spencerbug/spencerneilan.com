<script>
import { onMount } from "svelte";

import { writable } from "svelte/store";

let isDragging = writable(false)
let dragndropElement;

let dragTargetsRef=[]

function onDragEnterCb(event) {
    event.preventDefault()
    event.stopPropagation()
    dragTargetsRef = [...dragTargetsRef, event.target  ]
}

</script>



<div bind:this={dragndropElement} on:dragenter=>

</div>