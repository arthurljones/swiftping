package swiftping.export
{
	import flash.filesystem.File;
	
	import swiftping.rendering.FrameSequence;
	import swiftping.shapes.Triangulator;
	import swiftping.utils.ExtendedObjectProxy;

	public class CoronaExporter
	{
		import flash.geom.Point;
		import flash.geom.Rectangle;
		import flash.filesystem.FileStream;
		import flash.filesystem.FileMode;
		
		import mx.utils.StringUtil;
		
		import swiftping.Settings;
		import swiftping.rendering.Frame;
		import swiftping.utils.printf;
		import swiftping.utils.combinePaths;
		
		private var _output:String = "";
		private var _tabLevel:int = 0;
		private var _dest:File = null;
		
		public function CoronaExporter(dest:File)
		{
			_dest = dest;	
		}
		
		public function writeAnim(settings:ExtendedObjectProxy, sequence:FrameSequence):void
		{
			var bounds:Rectangle = sequence.minimumVisibleBounds;
			
			var triangles:Vector.<Vector.<Object>> = new Vector.<Vector.<Object>>;
			var shape:Vector.<Object> 
			for each (shape in settings.shapes)
				triangles = triangles.concat((new Triangulator(shape)).triangles);
			
			writeLine("return {")
			_tabLevel++;
				writeLine("loopParam = %d,", settings.loopParam);
				writeLine("framerate = %d,", settings.framerate);
				writeLine("referencePoint = { x = %d, y = %d },", settings.referencePoint.x, settings.referencePoint.y);
				writeLine("boundingRect = { x = %d, y = %d, width = %d, height = %d },",
						bounds.x, bounds.y, bounds.width, bounds.height)
				writeLine("frameData = {");
				_tabLevel++;
					for each (var frame:Frame in sequence.frames)
						writeFrame(frame, bounds);
				_tabLevel--;
				writeLine("},");
				writeLine("shapes = {")
				_tabLevel++;
					for each (shape in triangles)
						writeShape(shape);
				_tabLevel--;
				writeLine("},");
			_tabLevel--;
			writeLine("}");
			
			var stream:FileStream = new FileStream();
			stream.open(_dest, FileMode.WRITE);
			stream.writeUTFBytes(_output);
			stream.close();
		}

		private function writeLine(line:String, ...args):void
		{
			if (args.length > 0)
			{
				var printfArgs:Array = [line].concat(args);
				line = printf.apply(null, printfArgs);
			}
			
			_output += StringUtil.repeat("\t", _tabLevel) + line + "\n";
		}
		
		private function writeShape(shape:Vector.<Object>):void
		{
			var str:String = "{ ";
			for each (var vert:Object in shape)
				str += vert.x + ", " + vert.y + ", ";
			str += "},";
			
			writeLine(str);				
		}
		
		private function writeFrame(frame:Frame, rect:Rectangle):void
		{
			var result:String = "";
			
			//TODO: Not flexible
			var dest:Point = frame.dest;
			if (!dest)
				dest = frame.surrogate.dest;
			
			writeLine("{");
			_tabLevel++;
				writeLine("textureRect = { x = %d, y = %d, width = %d, height = %d },",
					dest.x, dest.y, frame.image.width, frame.image.height);
				writeLine("spriteTrimmed = true,");
				writeLine("spriteColorRect = { x = %d, y = %d},", -frame.origin.x, -frame.origin.y);
				writeLine("spriteSourceSize = { width = %d, height = %d}", rect.width, rect.height);
			_tabLevel--;
			writeLine("},");
		}
	}
}