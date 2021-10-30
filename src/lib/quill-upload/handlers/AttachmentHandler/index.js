
import BaseHandler from "../BaseHandler"
import { AttachmentBlot } from '../../blots';

class AttachmentHandler extends BaseHandler {
    constructor(quill, options) {
        super(quill, options)
        this.handlerName = 'attachment'
        this.applyForToolbar()
    }

    fileChanged() {
        console.log("fileChanged")
        const file = this.loadFile(this)
        this.embedFile(file)
    }

}

export default AttachmentHandler