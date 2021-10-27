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

    static id=0

    applyForToolbar() {
        var toolbar = this.quill.getModule("toolbar")
        toolbar.addHandler(this.handlerName, this.selectLocalFile.bind(this))
    }

    selectLocalFile() {
        this.range = this.quill.getSelection()
        this.fileHolder = document.createElement("input")
        this.fileHolder.setAttribute("type","file")
        this.fileHolder.onchange = this.fileChanged.bind(this)
    }

    loadFile(context) {
        // set loading state
        const file = context.fileHolder.files[0]
        this.handlerId = `${Constants.HANDLER_PREFIX}-${BaseHandler.id}`
        BaseHandler.id+=1
        const fileReader = new FileReader()
        fileReader.addEventListener(
            "load",
            () => {
                this.insertBase64Data(this.handlerId)
            }, 
            false
        )
        if (!file) {
            console.warn("[File not found] Something was wrong")
            return
        }

        fileReader.readAsDataURL(file)

        return file
    }

    embedFile(file) {
        this.options.upload(file).then(
            value => {
                this.insertFileToEditor(value)
            },
            error => {
                console.warn(error.message)
            }
        )
    }

    insertBase64Data(url) {
        const range = this.range
        this.quill.insertEmbed(
            range.index,
            this.handlerName,
            `${this.handlerId}${Constants.ID_SPLIT_FLAG}${url}`
        )

        const el = document.getElementById(this.handlerId)
    }

    insertFileToEditor(url) {
        const el = document.getElementById(this.handlerId)
        if (el) {
            el.setAttribute("src", url)
            el.removeAttribute("id")
            el.removeAttribute("class")
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
