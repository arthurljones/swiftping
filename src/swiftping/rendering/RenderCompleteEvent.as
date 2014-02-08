package swiftping.rendering
{
    import flash.events.Event

    public class RenderCompleteEvent extends Event
    {
        public static const COMPLETE:String = Event.COMPLETE

        public var frames:FrameSequence = null

        public function RenderCompleteEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, eventFrames:FrameSequence=null)
        {
            super(type, bubbles, cancelable)
            frames = eventFrames
        }
    }
}