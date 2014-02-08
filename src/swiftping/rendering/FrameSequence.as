package swiftping.rendering
{
    import flash.display.BitmapData
    import flash.geom.Rectangle

    public dynamic class FrameSequence
    {
        import flash.geom.Point

        public var frames:Vector.<Frame> = new Vector.<Frame>()

        //TODO: clone()

        public function get minimumVisibleBounds():Rectangle
        {
            var minBounds:Rectangle = new Rectangle
            for each (var frame:Frame in frames)
            {
                var frameBounds:Rectangle = frame.visibleBounds
                frameBounds.x -= frame.origin.x
                frameBounds.y -= frame.origin.y
                minBounds = minBounds.union(frameBounds)
            }
            return minBounds
        }

        public function set origin(value:Point):void
        {
            for each(var frame:Frame in frames)
                frame.origin = value
        }

        public function AddFrame(image:BitmapData):Frame
        {
            var frame:Frame = new Frame(image)
            frames.push(frame)
            return frame
        }

        public function DisposeImages():void
        {
            for each (var frame:Frame in frames)
                frame.dispose()
        }

        public function Crop(rect:Rectangle):void
        {
            for each(var frame:Frame in frames)
            {
                frame.crop(rect)
            }
        }

        public function CropToVisiblePixels():void
        {
            for each(var frame:Frame in frames)
            {
                if (frame.image)
                {
                    var bounds:Rectangle = frame.visibleBounds
                    bounds.width = bounds.width || 1
                    bounds.height = bounds.height || 1
                    frame.crop(bounds)
                }
            }
        }

        public function SortByHeight():void
        {
            frames.sort(
                function (frame1:Frame, frame2:Frame):int
                {
                    if (frame1.image.height < frame2.image.height)
                        return 1
                    else if (frame2.image.height < frame1.image.height)
                        return -1
                    else
                        return 0
                }
            )
        }

        public function ExtractUniqueFrames(dispose:Boolean = true):FrameSequence
        {
            var uniques:FrameSequence = new FrameSequence()

            for each (var frame:Frame in frames)
            {
                var uniqueImage:Frame = null
                for each (var unique:Frame in uniques.frames)
                {
                    if (frame.hasSameImageAs(unique))
                    {
                        uniqueImage = unique
                        break
                    }
                }

                if (!uniqueImage)
                    uniqueImage = uniques.AddFrame(frame.image)

                frame.surrogate = uniqueImage
            }

            return uniques
        }
    }
}