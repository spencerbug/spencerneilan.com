import Quill from 'quill'
import Constants from '../../utils/Constants';
import type { UploadResult } from '../../../storageStore'
// import BlockEmbed from 'quill/blots/embed'

let BlockEmbed = Quill.import("blots/embed")

class VideoBlot extends BlockEmbed {
    /**
     * value must be object of value.id, value.src
     */
    static create(value:UploadResult|string) {
        let id;
        let src;
        let node;

        if (typeof value === 'object'){
            id = value.id
            src = value.url? value.url : '#'
        }
        else {
            src = value
        }
        

        node = super.create(src)

        node.setAttribute('src', src)
        if (id){
            node.setAttribute("id", id)
        }
        node.setAttribute("frameborder","0")
        node.setAttribute("allowfullscreen", true)

        return node

    }
    static formats(node) {
        // We still need to report unregistered embed formats
        let format = {}
        if (node.hasAttribute('height')){
            // @ts-ignore
            format.height = node.getAttribute('height') 
        }
        if (node.hasAttribute('width')) {
            // @ts-ignore
            format.width = node.getAttribute('width')
        }
        return format
    }

    static value(node) {
        return node.getAttribute('src')
    }

    format(name, value) {
        // Handle unregistered embed formats
        if (name === "height" || name === "width") {
            if (value) {
                // @ts-ignore
                this.domNode.setAttribute(name, value);
            } else {
                // @ts-ignore
                this.domNode.removeAttribute(name, value);
            }
        } else {
            super.format(name, value);
        }
    }
}
// @ts-ignore
VideoBlot.tagName = "iframe";
// @ts-ignore
VideoBlot.blotName = Constants.blots.video
// @ts-ignore
VideoBlot.className = 'quill-upload-video'

Quill.register(VideoBlot);

export default VideoBlot;
