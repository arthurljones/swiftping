package swiftping.rendering
{
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.Rectangle;

    public class RenderCompleteEvent extends Event
    {
        public static const COMPLETE:String = Event.COMPLETE;

        public var frames:FrameSequence = null;

        public function RenderCompleteEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, eventFrames:FrameSequence=null)
        {
            super(type, bubbles, cancelable);
            frames = eventFrames;
        }
    }
}