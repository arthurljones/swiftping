package swiftping.utils
{
    import flash.filesystem.File;

    public function calculateRelativePath(fromDir:String, to:String):String
    {
        if (!fromDir)
            return to;

        if (!to)
            return null;

        var fromParts:Array = fromDir.split(File.separator);
        var toParts:Array = to.split(File.separator);

        while (fromParts.length > 0 && toParts.length > 0 && fromParts[0] == toParts[0])
        {
            fromParts.shift();
            toParts.shift();
        }

        Log.log("\"" + fromParts + "\" ->  \"" + toParts + "\"");

        for each (var part:String in fromParts)
            toParts.unshift("..");

        var result:String = toParts.join(File.separator);
        Log.log("\t = \"" + result + "\"");
        return result;
    }

}