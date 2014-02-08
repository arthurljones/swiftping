package swiftping.rendering
{
    import flash.events.EventDispatcher;

    public class SwfRenderer extends EventDispatcher
    {
        import mx.controls.Alert;
        import flash.display.Loader;
        import flash.display.LoaderInfo;
        import flash.display.MovieClip;
        import flash.events.IOErrorEvent;
        import flash.filesystem.File;
        import flash.system.LoaderContext;
        import flash.utils.ByteArray;
        import flash.events.ProgressEvent;
        import flash.geom.Matrix;
        import flash.geom.Point;
        import flash.geom.Rectangle;
        import flash.display.BitmapData;
        import flash.display.MovieClip;
        import flash.events.Event;

        import swiftping.utils.Log;

        ///////////////////////////////////////////////////////////////////////
        // Public Functions

        public function SwfRenderer(path:String)
        {
            mFile = new File(path);

            mFile.addEventListener(Event.COMPLETE, fileLoaded);
            mFile.addEventListener(IOErrorEvent.IO_ERROR, ioError);
        }

        public function render():void
        {
            Log.log("Reading \"" + mFile.nativePath + "\" from file...");
            mFile.load();
        }

        public function stop():void
        {
            mClip.loaderInfo.loader.unloadAndStop();
            mClip = null;
        }

        public function get file():File
        {
            return mFile;
        }

        public function get sequence():FrameSequence
        {
            if (!rendering)
                return mFrameSequence;
            else
                return null;
        }

        public function get rendering():Boolean
        {
            return mClip != null && mClip.isPlaying;
        }

        ///////////////////////////////////////////////////////////////////////
        // Private Variables

        private var mFile:File;
        private var mClip:MovieClip;
        private var mFrameSequence:FrameSequence = new FrameSequence();
        private var mTotalFrames:uint = 0;
        private var mCurrentFrame:uint = 0;
        private var mRenderSize:Point = null;
        private var mRenderTransform:Matrix = null;

        ///////////////////////////////////////////////////////////////////////
        // Private Functions

        private function getClipFrameCount(clip:MovieClip, totalFrames:uint = 1):uint
        {
            totalFrames = Math.max(clip.totalFrames, totalFrames);
            if (totalFrames == 1)
            {
                for (var i:uint = 0; i < clip.numChildren; ++i)
                {
                    var child:MovieClip = clip.getChildAt(i) as MovieClip;
                    if (child != null)
                        totalFrames = this.getClipFrameCount(child, totalFrames);
                }
            }
            return totalFrames;
        }

        private function ioError(e:IOErrorEvent):void
        {
            dispatchEvent(e);
        }

        private function fileLoaded(e:Event):void
        {
            Log.log("Loading MovieClip from data...")

            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext;
            loaderContext.allowLoadBytesCodeExecution = true;
            loader.loadBytes(e.target.data, loaderContext);
            loader.contentLoaderInfo.addEventListener(Event.INIT, clipReady);
        }

        private function clipReady(e:Event):void
        {
            mClip = e.target.content as MovieClip;
            if (!mClip)
            {
                //TODO: Throw error!
                Log.log("File loaded was not a SWF!");
                return;
            }

            mFrameSequence = new FrameSequence();
            mFrameSequence.framerate = mClip.loaderInfo.frameRate;

            mCurrentFrame = 0;
            mTotalFrames = getClipFrameCount(mClip, 0);//getClipFrameCount(mClip);

            mClip.addEventListener(Event.ENTER_FRAME, onFrame);

            Log.log("Renderer: Rendering " + mTotalFrames + " frames");
            mClip.play();
        }

        private function onFrame(e:Event):void
        {
            if (mCurrentFrame < mTotalFrames - 1)
            {
                var width:uint = mClip.loaderInfo.width * 2;
                var height:uint = mClip.loaderInfo.height * 2;

                var frame:BitmapData = new BitmapData(width, height, true, 0);
                var transform:Matrix = new Matrix();
                transform.translate(width / 4, height / 4);
                frame.draw(mClip, transform);
                mFrameSequence.AddFrame(frame);
                dispatchProgresEvent();

                ++mCurrentFrame;
            }
            else
            {
                this.stop();
                var stop:RenderCompleteEvent = new RenderCompleteEvent(RenderCompleteEvent.COMPLETE, false, false, mFrameSequence);
                dispatchEvent(stop);
            }
        }

        private function dispatchProgresEvent():void
        {
            var progress:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
            progress.bytesLoaded = mCurrentFrame + 1;
            progress.bytesTotal = mTotalFrames;
            dispatchEvent(progress);
        }
    }
}