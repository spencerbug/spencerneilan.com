import Constants from "../utils/Constants";
class BaseHandler {
    constructor(quill, options) {
        
        this.quill = quill;
        this.options = options;
        this.range = null
        this.handlerName = 'base'
        if (typeof this.options.upload !== "function"){
            console.warn("[Missing config] upload function that returns a promise is required")
        }
    }

    fileChanged() {
        console.error("Cannot call base class BadeHandler.fileChanged()");
    }

    applyForToolbar() {
        var toolbar = this.quill.getModule("toolbar")
        toolbar.addHandler(this.handlerName, this.selectLocalFile.bind(this))
    }

    selectLocalFile() {
        this.range = this.quill.getSelection();
        this.fileHolder = document.createElement("input")
        this.fileHolder.setAttribute("type","file")
        this.fileHolder.onchange = this.fileChanged.bind(this)
        this.fileHolder.click();
    }

    loadFile(context) {
        // set loading state
        const file = context.fileHolder.files[0]
        this.insertLoadingIcon()

        return file
    }

    insertLoadingIcon(){
        console.log("insertLoadingIcon")
        const range = this.range
        this.quill.insertEmbed(
            range.index,
            'image',
            "/loading_duck.gif"
        )
        const el = document.querySelectorAll('[src="/loading_duck.gif"]')[0]
        if (el) {
            el.setAttribute('class', Constants.QUILL_UPLOAD_LOADING_ICON_CLASSNAME)
            el.setAttribute('width', '50px')
            el.setAttribute('height', '50px')
        }
    }

    embedFile(file) {
        this.options.upload(file).then(
            value => {
                console.log(value)
                this.replaceFileToEditor(value)
            },
            error => {
                console.warn(error.message)
            }
        )
    }

    replaceFileToEditor(val) {
        
        this.quill.insertEmbed(
            this.range.index,
            this.handlerName,
            val
        )
        
        // remove the loading icon
        const els = document.getElementsByClassName(Constants.QUILL_UPLOAD_LOADING_ICON_CLASSNAME)
        for (const el of els){
            el.remove()
        }
    }

    isImage(extension) {
        return /(gif|jpg|jpeg|tiff|png)$/i.test(extension);
    }

    isVideo(extension) {
        return /(mp4|m4a|3gp|f4a|m4b|m4r|f4b|mov|flv|avi|ogg)$/i;
    }

}

export default BaseHandler
