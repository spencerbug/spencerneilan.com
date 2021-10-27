import BaseHandler from '../BaseHandler'
import { Video } from '../../blots';

class VideoHandler extends BaseHandler {
    constructor(quill, options){
        super(quill, options)
        
        this.handlerName = 'video'
        this.applyForToolbar()
    }

    fileChanged() {
        const file = this.loadFile(this)
        const extension = file.name.split(".").pop()

        if (!this.isVideo(extension)) {
            console.warn(
                "[Wrong Format] ImageHandler requires an image format extension"
            )
            return
        }

        this.embedFile(file)
    }
}

export default VideoHandler