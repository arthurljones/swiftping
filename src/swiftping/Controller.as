package swiftping
{
	import flash.display.BitmapData;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import flashx.textLayout.tlf_internal;
	
	import mx.collections.ArrayList;
	import mx.events.AIREvent;
	
	import swiftping.utils.ExtendedObjectProxy;

	public class Controller extends EventDispatcher
	{
		import flash.desktop.NativeApplication;

		import flash.display.Sprite;
		import flash.events.Event;
		import flash.events.InvokeEvent;
		import flash.events.MouseEvent;
		import flash.events.IOErrorEvent;
		import flash.filesystem.File;
		import flash.media.SoundTransform;
		import flash.net.FileFilter;
		
		import mx.collections.ArrayCollection;
		import mx.controls.Alert;
		import mx.events.CloseEvent;
		import mx.utils.ObjectProxy;
		
		import swiftping.utils.calculateRelativePath;
		import swiftping.utils.combinePaths;
		import swiftping.utils.stripFilenameSuffix;
		import swiftping.utils.getPathParent;
		import swiftping.utils.writePng;
		import swiftping.utils.BindingDebugger;
		import swiftping.utils.Log;
		
		import swiftping.rendering.SwfRenderer;
		import swiftping.rendering.RenderCompleteEvent;
		import swiftping.rendering.SheetPacker;
		import swiftping.rendering.FrameSequence;
		import swiftping.export.CoronaExporter;
		
		///////////////////////////////////////////////////////////////////////
		// Public Properties
				
		public const mFileSuffix:String = "sp";
					
		public const mLoopTypes:ArrayList = new ArrayList([
			"Bonuce Forever",//-2
			"Bonuce Once",//-1
			"Loop Forever",//0
			"Play Once",//1
			"Loop Counted",//2+
		]);
		
		//TODO These are public mostly because I don't want to write getters with events right now
		[Bindable]
		public var mFrames:FrameSequence = null;
		
		[Bindable]
		public var mRenderer:SwfRenderer = null;
		
		[Bindable]
		public var mSheetStats:String = "";
		
		///////////////////////////////////////////////////////////////////////
		// Accessors for Settings
		
		private static function SetupSettingsAccessors(data:ExtendedObjectProxy):void
		{
			data.setGetter("inputChosen",
				function(obj:ExtendedObjectProxy):Boolean
				{
					return Boolean(obj.fullInputPath);
				}, "fullInputPath");
			
			data.setGetter("loopCountEnabled", 
				function(obj:ExtendedObjectProxy):Boolean
				{
					return obj.loopParam >= 1;
				}, "loopParam");
			
			data.setGetter("loopTypeIndex",
				function(obj:ExtendedObjectProxy):uint
				{
					return Math.min(obj.loopParam + 2, 4);
				}, "loopParam");
			
			data.setSetter("loopTypeIndex",
				function(obj:ExtendedObjectProxy, value:uint):void
				{
					var param:int = value - 2;
					if (param >= -2 && param <= 2) // Only set valid values
					{
						if (!(obj.loopCountEnabled && param >= 1)) //Don't smash the existing loop count
						{	
							obj.loopParam = param;
						}
					}
				});	
		
			data.setGetter("loopCount", 
				function(obj:ExtendedObjectProxy):Number
				{
					if (!obj.loopCountEnabled)
						return NaN
					else
						return obj.loopParam;
				}, "loopParam");
			
			data.setSetter("loopCount",
				function(obj:ExtendedObjectProxy, value:uint):void
				{
					if (obj.loopCountEnabled && value >= 1)
						obj.loopParam = value;
				});
				
			data.setSetter("diskLocation",
				function(obj:ExtendedObjectProxy, value:String):void
				{
					var input:String = combinePaths(obj.accessorGet("diskLocation"), obj.relativeInput);
					var output:String = combinePaths(obj.accessorGet("diskLocation"), obj.relativeOutput);
					
					var newBase:String = new File(value).parent.nativePath;
					obj.relativeInput = calculateRelativePath(newBase, input);
					obj.relativeOutput = calculateRelativePath(newBase, output);
					
					obj.accessorSet("diskLocation", value);
				});
			
			data.setGetter("projectFileDisplay",
				function(obj:ExtendedObjectProxy):String
				{
					var location:File = obj.diskLocation as File
					if (location)
						return location.nativePath;
					else
						return "New Project";
				}, "diskLocation");
			
			data.setGetter("fullInputPath",
				function(obj:ExtendedObjectProxy):String
				{
					return combinePaths(obj.diskLocation, obj.relativeInput);
					
				}, "diskLocation", "relativeInput");
			
			data.setSetter("fullInputPath",
				function(obj:ExtendedObjectProxy, value:String):void
				{
					obj.relativeInput = calculateRelativePath(getPathParent(obj.diskLocation), value);
				});	
			
			data.setGetter("fullOutputPath",
				function(obj:ExtendedObjectProxy):String
				{
					return combinePaths(obj.diskLocation, obj.relativeOutput);
					
				}, "diskLocation", "relativeOutput");
			
			data.setSetter("fullOutputPath",
				function(obj:ExtendedObjectProxy, value:String):void
				{
					obj.relativeOutput = calculateRelativePath(getPathParent(obj.diskLocation), value);
				});	
		}
		
		///////////////////////////////////////////////////////////////////////
		// Public Methods
		
		//TODO: move to utils
		private static function endsWith(str:String, pattern:String):Boolean
		{
			return str.lastIndexOf(pattern) == (str.length - pattern.length);
		}
		
		public function Controller(args:Array, path:File):void
		{
			mData = new ExtendedObjectProxy();
			SetupSettingsAccessors(mData);
			mData.setObject(new Settings());
			
			var swfFile:File = null;
			var spFile:File = null;
			var usageError:Boolean = false;
			var printUsage:Boolean = false;
			
			while (args.length > 0)
			{
				var arg:String = args.shift();
				
				if (arg == "--auto-export" || arg == "-a")
				{
					Log.log("Auto export enabled");
					mAutoExport = true;
				}
				else if (arg == "--help")
				{
					printUsage = true;
					break;
				}
				else if (endsWith(arg, ".swf"))
				{
					if (swfFile)
					{
						usageError = true;
						break;
					}
					
					Log.log("SWF to load:", arg);
					swfFile = path.resolvePath(arg);
				}
				else if (endsWith(arg, ".sp"))
				{
					if (spFile)
					{
						usageError = true;
						break;
					}
					
					Log.log("SP to load:", arg);
					spFile = path.resolvePath(arg);
				}
				else
				{
					Log.log("Unknown command: ", arg);
					usageError = true;
					break;
				}
			}
			
			Log.log("Sanity checking args");
			
			if (mAutoExport && !(swfFile || spFile))
				usageError = true;
			
			if (swfFile && spFile)
				usageError = true;
			
			if (printUsage || usageError)
			{
				Log.log("Usage: SwiftPing [OPTIONS] [filename]")
				Log.log("\tfilename must be a .swf or .sp file");
				Log.log("\tOPTIONS:")
				Log.log("\t-a, --auto-export: Export after rendering, without starting the GUI. Requires a file to be specified");
				
				NativeApplication.nativeApplication.exit(usageError ? 1 : 0);
			}
		
			function onComplete(e:Event = null):void
			{
				if (swfFile)
					loadSwf(swfFile);
				else if (spFile)
					LoadSettings(spFile);
			}
			
			if (mAutoExport)
			{
				Log.log("Doing auto export");
				onComplete();
			}
			else
			{
				var timer:Timer = new Timer(1000);
				timer.addEventListener(TimerEvent.TIMER, onCheckFileTimer);
				timer.start();
				
				createView(onComplete);
			}
		}
	
		private function onCheckFileTimer(e:TimerEvent):void
		{
			if (mData.inputChosen)
			{
				var file:File = new File(mData.fullInputPath);
				if (mLastInputFile && file.nativePath == mLastInputFile.nativePath)
				{
					if (!file || !file.exists)
						return;
			
					if (mLastInputModification != null && mLastInputModification.time < file.modificationDate.time)
					{
						if (mData.autoReload)
						{
							reload();
						}
						
						mLastInputModification = file.modificationDate;
					}
				}
				else
				{
					mLastInputFile = file;
					if (file && file.exists)
						mLastInputModification = file.modificationDate;
					else
						mLastInputModification = new Date;
				}
			}
		}
		
		public function Export():void
		{
			var outputImage:File = new File(combinePaths(mData.fullOutputPath, mData.outputPrefix + ".png"));
			var outputScript:File = new File(combinePaths(mData.fullOutputPath, mData.outputPrefix + ".lua"));
			
			Log.log("Exporting data to \"" + outputImage.nativePath + "\" and \"" + outputScript.nativePath + "\"...");
			
			writePng(mSheetPacker.sheet, outputImage);
			
			var exporter:CoronaExporter = new CoronaExporter(outputScript);
			exporter.writeAnim(mData, mFrames);
			
			Log.log("\tSuccessfully exported!");
			
			if (mAutoExport)
				NativeApplication.nativeApplication.exit(0);
		}
		
		public function reload():void
		{
			mExportOnRenderOnce = mData.exportOnReload;
			render();
		}
		
		public function OpenProject():void
		{
			Log.log("Choosing project to open...");
			
			var chooser:File = new File();
			chooser.addEventListener(Event.SELECT, function(e:Event):void { LoadSettings(e.target as File); });
			chooser.browseForOpen("Choose a project file", [new FileFilter("SwiftPing Export Settings", "*." + mFileSuffix)]);
		}
		
		public function SaveProject():void
		{	
			Log.log("Saving project...");
			
			if (mProjectFile)
				SaveSettings(mProjectFile);
			else
				SaveProjectAs();
		}
		
		public function SaveProjectAs():void
		{
			Log.log("Choosing file to save project to...");
			
			var chooser:File = null;
			if (mProjectFile)
			{
				chooser = new File(mProjectFile.nativePath);
			}
			else
			{
				chooser = new File(mData.fullOutputPath);
				chooser = chooser.resolvePath(mData.outputPrefix + "." + mFileSuffix);
			}
			chooser.addEventListener(Event.SELECT, SaveLocationChosen);
			chooser.browseForSave("Choose a filename");
		}
		
		public function ChooseSWF():void
		{
			Log.log("Choosing input SWF...");
			
			var chooser:File = new File();
			chooser.addEventListener(Event.SELECT, function(e:Event):void { loadSwf(e.target as File) });
			chooser.browseForOpen("Choose a SWF movie to open", [new FileFilter("SWF movies", "*.swf")]);
		}
		
		public function ChooseOutputDir():void
		{
			Log.log("Choosing output directory...");
			
			var chooser:File = new File();
			chooser.addEventListener(Event.SELECT, function(e:Event):void { mData.fullOutputPath = e.target.nativePath; } );
			chooser.browseForDirectory("Choose a directory to save files in");		
		}
		
		///////////////////////////////////////////////////////////////////////
		// Private Properties
		
		private var mData:ExtendedObjectProxy = null;
		private var mSheetPacker:SheetPacker = null;
		private var mSetDefaultSettings:Boolean = true;
		private var mProjectFile:File = null;
		private var mAutoExport:Boolean = false;
		private var mExportOnRenderOnce:Boolean = false;
		private var mLastInputFile:File = null;
		private var mLastInputModification:Date = null;
		
		///////////////////////////////////////////////////////////////////////
		// Private Methods
		
		private function onViewClose(e:Event):void
		{
			Log.log("Closing");
			NativeApplication.nativeApplication.exit(0);	
		}
		
		private function createView(onComplete:Function):void
		{
			Log.log("Opening view window");
			
			var view:View = new View();
			
			view.addEventListener(Event.CLOSE, onViewClose);
			view.addEventListener(Event.CLOSING, onViewClose);
				
			view.mData = mData;
			view.mController = this;
			view.open(true);
			
			view.addEventListener(AIREvent.WINDOW_ACTIVATE,
				function(e:Event):void
				{
					view.nativeWindow.x = (Screen.mainScreen.bounds.width - view.nativeWindow.width) / 2;
					view.nativeWindow.y = (Screen.mainScreen.bounds.height - view.nativeWindow.height) / 2;
					
					var descriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
					var ns:Namespace = descriptor.namespaceDeclarations()[0];
					view.title = "SwiftPing " + (descriptor.ns::versionNumber);
				});
			
			view.addEventListener(AIREvent.WINDOW_COMPLETE, 
				function (e:Event = null, delay:int = 500):void
				{
					//HACK: Window won't load correctly if we do this too soon, but I don't know what event to listen for to know 
					// we're good to go.
					var timer:Timer = new Timer(500, 1);
					timer.addEventListener(TimerEvent.TIMER, onComplete);
					timer.start();
				});
			
			//BindingDebugger.debugComponent(mView);
		}
		
		private function loadSwf(target:File):void
		{
			mData.fullInputPath = target.nativePath;
			mData.fullOutputPath = target.parent.nativePath;
			mData.outputPrefix = stripFilenameSuffix(target.name);
			
			render();			
		}
		
		private function SaveLocationChosen(e:Event):void
		{
			var dst:File = e.target as File;
			
			if (dst.extension != mFileSuffix)
				dst.nativePath += "." + mFileSuffix;
			
			SaveSettings(dst);
		}
		
		private function LoadSettings(src:File):void
		{
			Log.log("Loading settings from \"" + src.nativePath + "\"...");
			
			mProjectFile = src;
			mData.setObject(Settings.Load(src));
			if (mData.fullInputPath != "")
				render();
			
			dispatchEvent(new Event("projectFileDisplayStringChanged"));
		}
		
		private function SaveSettings(dst:File):void
		{
			Log.log("Saving settings to \"" + dst.nativePath + "\"...");
			
			mProjectFile = dst;
			mData.diskLocation = dst.nativePath;
			mData.Save();
			dispatchEvent(new Event("projectFileDisplayStringChanged"));
		}
		
		private function render():void
		{	
			mFrames = null;
			mSheetStats = "";
			
			mRenderer = new SwfRenderer(mData.fullInputPath);
			mRenderer.addEventListener(RenderCompleteEvent.COMPLETE, RenderComplete);
			mRenderer.addEventListener(IOErrorEvent.IO_ERROR, onSwfLoadError);
			mRenderer.render();
		}
		
		private function onSwfLoadError(e:IOErrorEvent):void
		{
			Alert.show("Couldn't load \"" + mData.fullInputPath + "\": " + e.text, "Error Loading File");
			mData.relativeInput = "";
		}
		
		private function RenderComplete(e:RenderCompleteEvent):void	
		{
			mSetDefaultSettings = false;
			
			var frames:FrameSequence = e.frames;
			
			mSheetPacker = new SheetPacker(frames, mData.framePadding);
			mSheetStats = "Packed " + mSheetPacker.uniqueImageCount + " unique frames into a " +
				mSheetPacker.sheet.width + " x " + mSheetPacker.sheet.height + " texture";
			
			//Don't set this until after we're done operating on the frames, lest a listener start using them prematurely
			mFrames = frames;
			
			if (mAutoExport || mExportOnRenderOnce)
			{
				Export();
			}
			
			mExportOnRenderOnce = false;
		}
	}
}