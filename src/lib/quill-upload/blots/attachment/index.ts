import Quill from "quill"
import Constants from "../../utils/Constants";
let Link = Quill.import("formats/link")
let Icons = Quill.import('ui/icons');
import type { UploadResult } from '../../../contentStore'

class Attachment extends Link {
    /**
     * value must be: object of value.id, value.text, value.url
     */
    blotName:string
    static create(value:UploadResult) : Node {
        let url;
        let linktext;
        let id;
        let node;

        url = value.url? value.url : '#'
        linktext = value.text? value.text : 'attachment'
        id = value.id

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
Attachment.blotName = Constants.blots.attachment
// @ts-ignore
Attachment.tagName = 'A'
// @ts-ignore
Attachment.className = 'ql-attachment'


Icons['attachments'] = Quill.import("assets/icons/attachment.svg")

Quill.register(Attachment)


export default Attachment