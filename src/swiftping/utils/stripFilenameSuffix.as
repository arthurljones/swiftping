package swiftping.utils
{
	public function stripFilenameSuffix(filename:String):String
	{
		var dotpos:int = filename.indexOf(".");
		if (dotpos >= 0)
			return(filename.substr(0, dotpos));
		else
			return filename;
	}	
}