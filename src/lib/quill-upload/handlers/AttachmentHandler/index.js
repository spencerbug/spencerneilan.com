
import BaseHandler from "../BaseHandler"
import { AttachmentBlot } from '../../blots';

class AttachmentHandler extends BaseHandler {
    constructor(quill, options) {
        super(quill, options)
        this.handlerName = 'attachment'
        this.applyForToolbar()
    }

    

    fileChanged = async (event) => {
        const file = this.loadFile(this)
        await this.embedFile(file)
    }

    embedFile = async(file) => {
        const val=await super.embedFile(file)
        if(val){
            // workaround for a bug where inserting a link and pressing enter
            // seems to duplicate the link on the following line
            let newCursor=this.range.index+val.text.length
            this.quill.insertText(newCursor," ")
            this.quill.setSelection(newCursor+1)
            this.quill.removeFormat(newCursor,1) 
        }
        return val
    }

}

export default AttachmentHandler