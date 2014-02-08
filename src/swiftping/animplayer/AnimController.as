package swiftping.animplayer
{
    import flash.events.EventDispatcher
    import flash.geom.Rectangle

    import mx.events.PropertyChangeEvent

    public class AnimController extends EventDispatcher
    {
        import flash.display.BitmapData
        import flash.events.Event
        import flash.events.MouseEvent
        import flash.geom.Matrix
        import flash.geom.Point

        import mx.events.ResizeEvent

        ///////////////////////////////////////////////////////////////////////
        // Public Variables

        ;[Bindable] public var clearColor:uint
        ;[Bindable] public var animPlayer:AnimPlayer = new AnimPlayer()
        ;[Bindable] public var collisionEditor:CollisionEditor = new CollisionEditor()

        ///////////////////////////////////////////////////////////////////////
        // Public Functions
        public function Initialize(view:AnimAnnotator, width:uint = 1024, height:uint = 1024):void
        {
            mView = view

            clearColor = 0xFFFF7FFF
            mBitmapData = new BitmapData(width, height)
            mBitmapData.fillRect(mBitmapData.rect, clearColor)
            mView.animImage.source = mBitmapData

            SetupTransforms()

            mView.scroller.addEventListener(ResizeEvent.RESIZE, CenterView)
            mView.addEventListener(Event.ENTER_FRAME, EnterFrame)

            var events:Array = [
                MouseEvent.MOUSE_MOVE,
                MouseEvent.MOUSE_DOWN,
                MouseEvent.MOUSE_UP,
                MouseEvent.MIDDLE_MOUSE_DOWN,
                MouseEvent.MIDDLE_MOUSE_UP,
                MouseEvent.RIGHT_MOUSE_DOWN,
                MouseEvent.RIGHT_MOUSE_UP,
                MouseEvent.MOUSE_WHEEL
            ]

            for each (var event:String in events)
                mView.animImage.addEventListener(event, OnMouseActivity)

            function setStatText(e:Event = null):void
            {
                var bounds:Rectangle = animPlayer.bounds
                mView.animStats.text = "Reference Point: (" + animPlayer.referencePoint.x + ", " + animPlayer.referencePoint.y +
                    ")\nBounds Size: (" + bounds.width + ", " + bounds.height + ")"
            }

            animPlayer.addEventListener("sequenceChanged", setStatText)
            animPlayer.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, setStatText); //TODO: Bit overkill to call for every prop change

            AddPlugin(animPlayer)
            AddPlugin(collisionEditor)

            animPlayer.enabled = true
        }

        ///////////////////////////////////////////////////////////////////////
        // Private Variables
        private var mBitmapData:BitmapData = null
        private var mView:AnimAnnotator = null
        private var mLastTicks:Number = 0
        private var mDrawRequested:Boolean = true
        private var mPlugins:Vector.<IAnimPlugin> = new Vector.<IAnimPlugin>()

        public var mImageToScreen:Matrix = new Matrix()
        public var mScreenToImage:Matrix = new Matrix()

        ///////////////////////////////////////////////////////////////////////
        // Private Functions
        private function AddPlugin(plugin:IAnimPlugin):void
        {
            plugin.addEventListener(AnimAnnotatorEvents.DRAW_REQUEST, DrawRequested)
            plugin.addEventListener(AnimAnnotatorEvents.RESET_VIEW_REQUEST, ResetViewRequested)

            mPlugins.push(plugin)
        }

        private function DrawRequested(e:Event):void
        {
            mDrawRequested = true
        }

        private function ResetViewRequested(e:Event):void
        {
            CenterView()
        }

        private function SetupTransforms():void
        {
            mImageToScreen = new Matrix()
            mImageToScreen.translate(mBitmapData.width * 0.5, mBitmapData.height * 0.5)

            mScreenToImage = mImageToScreen.clone()
            mScreenToImage.invert()
        }

        private function CenterView(e:ResizeEvent = null):void
        {
            var scrollX:Number = (mBitmapData.width - mView.scroller.width) * 0.5
            var scrollY:Number = (mBitmapData.height - mView.scroller.height) * 0.5

            mView.scrollArea.horizontalScrollPosition = scrollX
            mView.scrollArea.verticalScrollPosition = scrollY
        }

        private function EnterFrame(e:Event):void
        {
            if (mDrawRequested)
            {
                mBitmapData.fillRect(mBitmapData.rect, clearColor)

                for each (var plugin:IAnimPlugin in mPlugins)
                    plugin.draw(mBitmapData, mImageToScreen)

                mView.animImage.validateNow()
            }
        }

        private function OnMouseActivity(e:MouseEvent):void
        {
            var point:Point = mScreenToImage.transformPoint(new Point(e.localX, e.localY))
            e.localX = point.x
            e.localY = point.y

            for each (var plugin:IAnimPlugin in mPlugins)
                if (plugin.isEnabled())
                    plugin.onMouseActivity(e)
        }
    }
}