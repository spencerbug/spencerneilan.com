
import BaseHandler from "../BaseHandler"
import { Attachment } from '../../blots';

class AttachmentHandler extends BaseHandler {
    constructor(quill, options) {
        super(quill, options)
        this.handlerName = 'attachment'
        this.applyForToolbar()
    }

    fileChanged() {
        const file = this.loadFile(this)
        this.embedFile(file)
    }

}

export default AttachmentHandler