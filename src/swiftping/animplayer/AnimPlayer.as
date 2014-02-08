package swiftping.animplayer
{
    import flash.events.EventDispatcher;
    import flash.events.TimerEvent;
    import flash.geom.Point;

    import mx.core.UIComponent;

    import swiftping.rendering.FrameSequence;

    public class AnimPlayer extends EventDispatcher implements IAnimPlugin
    {
        import flash.display.BitmapData;
        import flash.display.Shape;
        import flash.events.Event;
        import flash.events.MouseEvent;
        import flash.geom.Matrix;
        import flash.geom.Rectangle;
        import flash.utils.getTimer;
        import flash.utils.Timer;

        import swiftping.rendering.Frame;
        import swiftping.utils.dispatchPropertyChangeEvent;

        ///////////////////////////////////////////////////////////////////////
        // Public Properties

        [Bindable]
        public var referencePoint:Object = {x: 0, y: 0};

        [Bindable]
        public var enabled:Boolean = false;

        [Bindable(event = "sequenceChanged")]
        public function get bounds():Rectangle
        {
            if (frameSequence)
                return frameSequence.minimumVisibleBounds;
            else
                return new Rectangle;
        }

        [Bindable(event = "sequenceChanged")]
        public function get frameCount():uint
        {
            if (frameSequence)
                return frameSequence.frames.length;
            else
                return 0;
        }

        [Bindable]
        public function get frameRate():uint
        {
            return _mFrameRate;
        }

        public function set frameRate(value:uint):void
        {
            var oldVal:uint = _mFrameRate
            _mFrameRate = value;
            dispatchPropertyChangeEvent(this, "frameRate", oldVal, value);

            mTimer.delay = 1000 / frameRate;
        }

        [Bindable]
        public function get currentFrame():uint
        {
            return _mCurrFrame;
        }

        public function set currentFrame(value:uint):void
        {
            var oldVal:uint = _mCurrFrame;
            if (frameSequence && value >= frameSequence.frames.length)
                value = frameSequence.frames.length - 1;

            _mCurrFrame = value;
            if (oldVal != value)
                dispatchEvent(new Event(AnimAnnotatorEvents.DRAW_REQUEST));

            dispatchPropertyChangeEvent(this, "currentFrame", oldVal, value);
        }

        [Bindable]
        public function get frameSequence():FrameSequence
        {
            return _mFrameSequence;
        }

        public function set frameSequence(value:FrameSequence):void
        {
            var oldVal:FrameSequence = _mFrameSequence;
            _mFrameSequence = value;
            dispatchPropertyChangeEvent(this, "frameSequence", oldVal, value);
            dispatchEvent(new Event("sequenceChanged"));

            trace("frameSequence -> " + value);

            if (value != null)
            {
                var bounds:Rectangle = frameSequence.minimumVisibleBounds;
                mSequenceTransform = new Matrix();
                mSequenceTransform.translate(
                    -(bounds.left + bounds.right) * 0.5,
                    -(bounds.top + bounds.bottom) * 0.5);

                mBounds.graphics.clear();
                mBounds.graphics.lineStyle(1, 0xFF00FF, 0.75);
                mBounds.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);

                currentFrame = 0;
                playing = true;
                dispatchEvent(new Event(AnimAnnotatorEvents.RESET_VIEW_REQUEST));
            }
            else
            {
                mTimer.stop();
                playing = false;
            }
        }

        [Bindable]
        public function get playing():Boolean
        {
            return mTimer.running;
        }

        public function set playing(value:Boolean):void
        {
            var oldVal:Boolean = mTimer.running;

            if (value)
            {
                mLastTicks = 0;
                mLeftoverTicks = 0;
                mTimer.start();
                UpdateFrame();
            }
            else
            {
                mTimer.stop();
            }

            dispatchPropertyChangeEvent(this, "playing", mTimer.running, oldVal);
        }

        ///////////////////////////////////////////////////////////////////////
        // Public Functions
        public function AnimPlayer()
        {
            mTimer.addEventListener(TimerEvent.TIMER, UpdateFrame);

            mReferenceShape.graphics.lineStyle(1, 0xFF00FF, 0.75);
            mReferenceShape.graphics.moveTo(0, -10);
            mReferenceShape.graphics.lineTo(0, 10);
            mReferenceShape.graphics.moveTo(-10, 0);
            mReferenceShape.graphics.lineTo(10, 0);
        }

        public function isEnabled():Boolean
        {
            return enabled;
        }

        public function onMouseActivity(e:MouseEvent):void
        {
            if (e.type == MouseEvent.MOUSE_DOWN)
            {
                referencePoint.x = e.localX;
                referencePoint.y = e.localY;
            }
        }

        public function draw(target:BitmapData, transform:Matrix):void
        {
            if (frameSequence)
            {
                var sequenceTransform:Matrix = transform.clone();
                sequenceTransform.concat(mSequenceTransform);

                    var frame:Frame = frameSequence.frames[currentFrame];
                    var frameTransform:Matrix = sequenceTransform.clone();
                    frameTransform.translate(-frame.origin.x, -frame.origin.y);

                    target.draw(frame.image, frameTransform);

                var referenceTransform:Matrix = transform.clone();
                referenceTransform.translate(referencePoint.x, referencePoint.y);
                    target.draw(mReferenceShape, referenceTransform);

                target.draw(mBounds, sequenceTransform);
            }
        }

        public function UpdateFrame(e:Event = null):void
        {
            var ticks:Number = getTimer();
            var elapsedTicks:Number = mLeftoverTicks + (ticks - mLastTicks);
            var ticksPerFrame:Number = 1000 / frameRate;
            var framesToPlay:Number = Math.floor(elapsedTicks / ticksPerFrame);
            mLastTicks = ticks;
            mLeftoverTicks = elapsedTicks - (framesToPlay * ticksPerFrame);

            currentFrame = (currentFrame + framesToPlay) % frameSequence.frames.length;
        }

        ///////////////////////////////////////////////////////////////////////
        // Private Variables
        private var _mFrameSequence:FrameSequence = null;
        private var _mCurrFrame:uint = 0;
        private var _mFrameRate:uint = 0;

        private var mLastTicks:Number = 0;
        private var mLeftoverTicks:Number = 0;
        private var mBounds:Shape = new Shape();
        private var mSequenceTransform:Matrix = new Matrix();
        private var mTimer:Timer = new Timer(1);
        private var mReferenceShape:Shape = new Shape();
    }
}