import Quill from "quill"
// import Parchment from "parchment"
import Constants from "../../utils/Constants";
const Link = Quill.import("formats/link")
import type { UploadResult } from '../../../storageStore'

class AttachmentBlot extends Link {
    /**
     * value must be: object of value.id, value.text, value.url
     */
    static create(value: UploadResult|string) {
        let url;
        let linktext;
        let id;
        let node;
        
        if (typeof value === 'object'){
            url = value.url? value.url : '#'
            linktext = value.text? value.text : 'attachment'
            id = value.id
        }
        else {
            url = value
            linktext = value
        }
        

        node = super.create(url)

        node.setAttribute('href', super.sanitize(url))
        node.setAttribute('target', '_blank')
        node.appendChild(new Text(linktext))
        if (id){
            node.setAttribute("id",id)
        }
        
        return node;
    }

    static formats(node) {
        return node.getAttribute('href')
    }

    static value(node) {
        return node.getAttribute('href')
    }
}
// @ts-ignore
AttachmentBlot.blotName = Constants.blots.attachment
// @ts-ignore
AttachmentBlot.tagName = 'A'
// @ts-ignore
AttachmentBlot.className = 'ql-attachment'

Quill.debug('error')
Quill.register('formats/attachment',AttachmentBlot, true)


export default AttachmentBlot