import Quill from "quill"
import Constants from "../../utils/Constants";
let BlockEmbed = Quill.import("blots/embed")
import type { UploadResult } from '../../../contentStore'

class ImageBlot extends BlockEmbed {
    /**
     * value must be: object of value.id, value.src
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
            node.setAttribute("id",id)
        }
        return node;
    }

    static value(node) {
        return {
            alt: node.getAttribute('alt'),
            url: node.getAttribute('src')
        }
    }
}

// @ts-ignore
ImageBlot.blotName = Constants.blots.video
// @ts-ignore
ImageBlot.tagName = 'img'
// @ts-ignore
ImageBlot.className = 'ql-image'

Quill.register(ImageBlot)

export default ImageBlot
