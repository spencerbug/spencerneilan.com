import Quill from "quill"
import Constants from "../../utils/Constants";
// let BlockEmbed = Quill.import("blots/embed")
let Image = Quill.import("formats/image")
import type { UploadResult } from '../../../storageStore'

const ATTRIBUTES = [
    'alt',
    'height',
    'width',
    'display',
    'style'
  ];
class ImageBlot extends Image {
    /**
     * value must be: object of value.id, value.src
     */
    static create(value:UploadResult|string) {
        let id;
        let src;
        let node;

        if (typeof value === 'object'){
            id = value.id
            src = value.url? value.url : '#'
        }
        else {
            src = value
        }

        node = super.create(src)

        node.setAttribute('src', src)
        if (id){
            node.setAttribute("id",id)
        }
        return node;
    }

    static formats(domNode) {
        return ATTRIBUTES.reduce(function(formats, attribute) {
          if (domNode.hasAttribute(attribute)) {
            formats[attribute] = domNode.getAttribute(attribute);
          }
          return formats;
        }, {});
      }

    static value(node) {
        return {
            alt: node.getAttribute('alt'),
            url: node.getAttribute('src')
        }
    }
}

// @ts-ignore
ImageBlot.blotName = Constants.blots.image
// @ts-ignore
ImageBlot.tagName = 'img'
// @ts-ignore
ImageBlot.className = 'ql-image'

Quill.debug('error')
Quill.register('formats/image',ImageBlot, true)

export default ImageBlot
