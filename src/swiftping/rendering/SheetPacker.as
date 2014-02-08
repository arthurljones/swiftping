package swiftping.rendering
{
    import flash.geom.Point
    import flash.geom.Rectangle

    import spark.primitives.BitmapImage
    import spark.primitives.Rect

    public class SheetPacker
    {
        import flash.display.BitmapData
        import swiftping.utils.Log

        private var mSheet:BitmapData = null
        private var mWastedSpace:int = 0
        private var mUniques:FrameSequence = null

        ///////////////////////////////////////////////////////////////////////
        // Public Funtions

        public function SheetPacker(frames:FrameSequence, padding:uint = 1, crop:Rectangle = null)
        {
            if (crop == null)
                crop = frames.minimumVisibleBounds

            frames.Crop(crop)
            frames.origin = new Point(0, 0)

            frames.CropToVisiblePixels()
            mUniques = frames.ExtractUniqueFrames()
            mUniques.SortByHeight()


            var sheetSize:Point = EstimateSpritesheetSize()
            var filledArea:Point
            while ((filledArea = PackUniqueImages(sheetSize, padding)) == null)
            {
                //Log.log("\tFailed to pack into " + sheetSize + ", trying next size...")
                if (sheetSize.y > sheetSize.x)
                    sheetSize.x *= 2
                else
                    sheetSize.y *= 2
            }
            Log.log("Sheet Packer: Packed " + mUniques.frames.length + " unique image(s) into " + sheetSize)

            DrawToSheet(sheetSize)
        }

        public function get uniqueImageCount():uint
        {
            return mUniques.frames.length
        }

        public function get sheet():BitmapData
        {
            return mSheet
        }

        ///////////////////////////////////////////////////////////////////////
        // Private Funtions

        //Just gives a decent minimum size for now, almost guaranteed to need iterative passes
        private function EstimateSpritesheetSize():Point
        {
            var size:Point = new Point(128, 128)

            for each (var frame:Object in mUniques)
            {
                var image:BitmapData = frame.image
                size.x = Math.max(size.x, image.width)
                size.y = Math.max(size.y, image.height)
            }

            //Bump sizes up to next power of two
            size.x = Math.pow(2, Math.ceil(Math.log(size.x) * Math.LOG2E))
            size.y = Math.pow(2, Math.ceil(Math.log(size.y) * Math.LOG2E))

            return size
        }

        //Attempts to pack images next to each other until there's no room left on the row, at
        // which point the algorithm returns back to the beginning of the line under the first
        // image of the last row.
        private function PackUniqueImages(sheetSize:Point, padding:int):Point
        {
            var filled:Point = new Point(0, 0)
            var curr:Point = new Point(0, 0)

            for each (var frame:Frame in mUniques.frames)
            {
                var image:BitmapData = frame.image
                if (curr.x + image.width >= sheetSize.x)
                {
                    if (curr.x == 0)
                        return null

                    curr.x = 0
                    curr.y = filled.y + padding
                }
                if (curr.y + image.height >= sheetSize.y)
                    return null

                filled.x = Math.max(curr.x + image.width, filled.x)
                filled.y = Math.max(curr.y + image.height, filled.y)
                frame.dest = new Point(curr.x, curr.y)
                curr.x += image.width + padding
            }

            return filled
        }

        //Draws the unique images onto a single image based on the layout from PackUniqueItems
        private function DrawToSheet(size:Point):void
        {
            if (mSheet)
                mSheet.dispose()

            mSheet = new BitmapData(size.x, size.y, true, 0x00FF00FF)
            for each (var frame:Frame in mUniques.frames)
            {
                mSheet.copyPixels(frame.image, frame.image.rect, frame.dest)
            }
        }
    }
}