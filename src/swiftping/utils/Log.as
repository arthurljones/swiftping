package swiftping.utils
{
    public class Log
    {
        import flash.filesystem.File
        import flash.filesystem.FileMode
        import flash.filesystem.FileStream
        import spark.formatters.DateTimeFormatter

        private static var sListeners:Vector.<Function> = new Vector.<Function>
        private static var sOut:FileStream = null
        private static var sSessionLog:String = ""
        private static var sTimeFormatter:DateTimeFormatter = new DateTimeFormatter()

        public static function log(...args):void
        {
            if (sOut == null)
            {
                var file:File = File.userDirectory.resolvePath("swiftpinglog.txt")
                sOut = new FileStream()
                sOut.open(file, FileMode.APPEND)
                sOut.writeUTFBytes("\n\n\n")
                sOut.writeUTFBytes("--- SwiftPing ---\n")
                sOut.writeUTFBytes("-- " + new Date() + " --\n")

                sTimeFormatter.dateTimePattern = "h:mm:ss a: "
            }

            var str:String = args.join(" ")
            trace(str)
            sOut.writeUTFBytes(str + "\n")
            sSessionLog += sTimeFormatter.format(new Date()) + str + "\n"

            for each (var listener:Function in sListeners)
            {
                listener(sSessionLog)
            }
        }

        public static function registerLogListener(listener:Function):void
        {
            sListeners.push(listener)
        }
    }
}