package swiftping.utils
{
    import flash.filesystem.File
    public function getPathParent(path:String):String
    {
        if (path)
            return (new File(path)).parent.nativePath
        else
            return null
    }
}