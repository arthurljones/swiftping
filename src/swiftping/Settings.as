package swiftping
{
    import flash.filesystem.File
    import flash.filesystem.FileMode
    import flash.filesystem.FileStream

    import swiftping.utils.shallowCopyObject

    public class Settings extends Object
    {
        public var relativeInput:String = ""
        public var relativeOutput:String = ""
        public var outputPrefix:String = ""
        public var autoReload:Boolean = false
        public var exportOnReload:Boolean = false

        public var loopParam:Number = 0
        public var framePadding:Number = 2
        public var framerate:Number = 60
        public var referencePoint:Object = { x: 0, y: 0 }
        public var shapes:Vector.<Vector.<Object>> = new Vector.<Vector.<Object>>

        public var diskLocation:String = ""

        public function Settings() { }

        private static function Replacer(key:String, value:*):*
        {
            if (key == "diskLocation")
                return undefined
            else
                return value
        }

        private static function Revivifier(key:String, value:*):*
        {
            if (key == "shapes")
            {
                var newShapes:Vector.<Vector.<Object>> = new Vector.<Vector.<Object>>
                for each (var shape:Array in value)
                {
                    var newShape:Vector.<Object> = new Vector.<Object>
                    for each (var vert:Object in shape)
                        newShape.push(vert)
                    newShapes.push(newShape)
                }
                return newShapes
            }
            else
            {
                return value
            }
        }

        public function Save():void
        {
            var dest:File = new File(this["diskLocation"])
            if (dest == null)
                throw new Error("Attempted to call Save() on settings with no diskLocation set")

            var text:String = JSON.stringify(this, Replacer, "\n")
            var stream:FileStream = new FileStream()
            stream.open(dest, FileMode.WRITE)
            stream.writeUTFBytes(text)
            stream.close()
        }

        public static function Load(src:File):Settings
        {
            var stream:FileStream = new FileStream()
            stream.open(src, FileMode.READ)
            var text:String = stream.readUTFBytes(stream.bytesAvailable)
            stream.close()
            var parsed:Object = JSON.parse(text, Revivifier)
            var settings:Settings = new Settings()
            shallowCopyObject(parsed, settings)
            settings.diskLocation = src.nativePath
            return settings
        }
    }
}