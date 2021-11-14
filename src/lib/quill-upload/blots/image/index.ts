import Quill from "quill"
import Constants from "../../utils/Constants";
let BlockEmbed = Quill.import("blots/embed")
import type { UploadResult } from '../../../contentStore'

class Image extends BlockEmbed {
    /**
     * value must be: object of value.id, value.src
     */
    static create(value:UploadResult) {
        let id;
        let src;
        let node;

        id = value.id
        src = value.url? value.url : '#'

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
Image.blotName = Constants.blots.video
// @ts-ignore
Image.tagName = 'img'
// @ts-ignore
Image.className = 'ql-image'

Quill.register(Image)

export default Image
