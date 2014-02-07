package swiftping.utils
{
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.graphics.codec.PNGEncoder;
	
	public function writePng(bitmap:BitmapData, file:File):Boolean
	{
		var encoder:PNGEncoder = new PNGEncoder;
		var encoded:ByteArray = encoder.encode(bitmap);
		
		var fileStream:FileStream = new FileStream();
		fileStream.open(file, FileMode.WRITE);
		fileStream.writeBytes(encoded, 0);
		
		fileStream.close();
		
		return true;
	}		
}