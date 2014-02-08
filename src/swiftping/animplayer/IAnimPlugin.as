package swiftping.animplayer
{
    import flash.display.BitmapData
    import flash.events.IEventDispatcher
    import flash.events.MouseEvent
    import flash.geom.Matrix

    public interface IAnimPlugin extends IEventDispatcher
    {
        function draw(target:BitmapData, transform:Matrix):void
        function onMouseActivity(e:MouseEvent):void

        function isEnabled():Boolean
    }
}