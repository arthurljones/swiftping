package swiftping.rendering
{
    import flash.display.BitmapData
    import flash.events.EventDispatcher
    import flash.geom.Point
    import flash.geom.Rectangle

    import mx.events.PropertyChangeEvent

    import swiftping.utils.dispatchPropertyChangeEvent

    public dynamic class Frame extends EventDispatcher
    {
        [Bindable]
        public var origin:Point = new Point(0, 0)

        ;[Bindable]
        public function get image():BitmapData
        {
            if (_surrogate)
                return _surrogate.image
            else
                return _image
        }

        public function set image(value:BitmapData):void
        {
            setSurrogateAndImage(null, value)
        }

        [Bindable]
        public function get surrogate():Frame
        {
            return _surrogate
        }

        public function set surrogate(value:Frame):void
        {
            setSurrogateAndImage(value, null)
        }

        ///////////////////////////////////////////////////////////////////////
        // Public Functions

        public function Frame(frameImage:BitmapData = null)
        {
            image = frameImage
        }

        public function dispose():void
        {
            if (image != null)
            {
                image.dispose()
                image = null
            }
        }

        public function hasSameImageAs(other:Frame):Boolean
        {
            if (image == null)
                return (other.image == null)
            else if (other.image == null)
                return false
            else
                return (image.compare(other.image) == 0)
        }

        public function get visibleBounds():Rectangle
        {
            if (image)
                return image.getColorBoundsRect(0xFF000000, 0xFFFFFF, false)
            else
                return new Rectangle()
        }

        public function crop(rect:Rectangle):void
        {
            if (!_image)
                return

            var newImage:BitmapData = new BitmapData(rect.width, rect.height)
            newImage.copyPixels(_image, rect, new Point(0, 0))
            _image.dispose()
            _image = newImage

            origin = new Point(origin.x - rect.x, origin.y - rect.y)
        }

        ///////////////////////////////////////////////////////////////////////
        // Protected Variables

        protected var _image:BitmapData = null
        protected var _surrogate:Frame = null

        ///////////////////////////////////////////////////////////////////////
        // Private Functions

        private function setSurrogateAndImage(sur:Frame, img:BitmapData):void
        {
            if (sur != null && img != null)
                throw new Error("setSurrogateAndImage: One or both of sur and image must be null!")

            var oldImage:BitmapData = image
            var oldSurrogate:Frame = surrogate

            _image = img
            _surrogate = sur

            dispatchPropertyChangeEvent(this, "imageSurragate", oldSurrogate, surrogate)
            dispatchPropertyChangeEvent(this, "image", oldImage, image)

            if (oldSurrogate)
                oldSurrogate.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, surrogatePropertyChanged)

            if (surrogate)
                surrogate.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, surrogatePropertyChanged)
        }

        private function surrogatePropertyChanged(e:PropertyChangeEvent):void
        {
            if (e.property == "image" || e.property == "ref")
                dispatchPropertyChangeEvent(this, "image", image, image)
        }
    }
}