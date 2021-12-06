import BaseHandler from '../BaseHandler'
import { VideoBlot } from '../../blots';

class VideoHandler extends BaseHandler {
    constructor(quill, options){
        super(quill, options)
        
        this.handlerName = 'video'
        this.applyForToolbar()
    }

    fileChanged = async () => {
        const file = this.loadFile(this)
        const extension = file.name.split(".").pop()

        if (!BaseHandler.isVideo(extension)) {
            console.warn(
                "[Wrong Format] ImageHandler requires an image format extension"
            )
            return
        }

        await this.embedFile(file)
    }
}

export default VideoHandler