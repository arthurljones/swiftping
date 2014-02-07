package swiftping.utils
{
	import flash.filesystem.File;
	public function combinePaths(directory:String, relativePath:String):String
	{
		if (directory)
		{
			var base:File = new File(directory);
			if (!base.isDirectory)
				base = base.parent;
			
			relativePath = base.resolvePath(relativePath).nativePath;
		}
		
		return relativePath;
	}
}