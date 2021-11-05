import Quill from "quill"
import Constants from "../../utils/Constants";
let Link = Quill.import("formats/link")
import type { UploadResult } from '../../../contentStore'

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
        node.appendChild(new Text(linktext))
        if (id){
            node.setAttribute("id",id)
        }
        
        return node;
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


Quill.register(AttachmentBlot)


export default AttachmentBlot