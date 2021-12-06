import BaseHandler from "../BaseHandler";
import { ImageBlot } from "../../blots";

class ImageHandler extends BaseHandler {
    constructor(quill, options){
        super(quill, options)

        this.handlerName = 'image'
        this.applyForToolbar()
    }

    fileChanged = async () => {
        const file = this.loadFile(this)
        const extension = file.name.split(".").pop();

        if (!BaseHandler.isImage(extension)){
            console.warn(
                "[Wrong Format] ImageHandler requires an image format extension"
            );
            return;
        }

        await this.embedFile(file);
    }

}

export default ImageHandler
