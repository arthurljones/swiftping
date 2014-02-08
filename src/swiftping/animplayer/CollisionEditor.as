package swiftping.animplayer
{
    import flash.display.BitmapData
    import flash.events.EventDispatcher
    import flash.events.MouseEvent
    import flash.geom.Matrix

    public class CollisionEditor extends EventDispatcher implements IAnimPlugin
    {
        import flash.events.Event
        import flash.display.Shape
        import flash.geom.Rectangle
        import flash.geom.Point

        import swiftping.shapes.Triangulator
        import swiftping.utils.dispatchPropertyChangeEvent
        import swiftping.utils.Log

        ///////////////////////////////////////////////////////////////////////
        // Public Properties

        ;[Bindable] public var enabled:Boolean = false

        public function CollisionEditor()
        {
        }

        ;[Bindable]
        public function get shapes():Vector.<Vector.<Object>>
        {
            return mDrawnShapes
        }

        public function set shapes(value:Vector.<Vector.<Object>>):void
        {
            var oldVal:Vector.<Vector.<Object>> = shapes
            mDrawnShapes = value
            dispatchPropertyChangeEvent(this, "shapes", oldVal, shapes)

            calculateShapes()
        }

        ///////////////////////////////////////////////////////////////////////
        // Public Functions

        public function onMouseActivity(e:MouseEvent):void
        {
            if (e.type == MouseEvent.MOUSE_DOWN)
            {
                if (shapes.length == 0)
                    shapes.push(new Vector.<Object>)

                shapes[0].push({ x: e.localX, y: e.localY })
                calculateShapes()
                dispatchEvent(new Event(AnimAnnotatorEvents.DRAW_REQUEST))
            }
            if (e.type == MouseEvent.RIGHT_MOUSE_DOWN)
            {
                if (shapes.length > 0)
                    shapes[0].pop()

                calculateShapes()
                dispatchEvent(new Event(AnimAnnotatorEvents.DRAW_REQUEST))
            }
        }

        public function draw(target:BitmapData, transform:Matrix):void
        {
            for each (var shapeGraphic:Shape in mDrawables)
                target.draw(shapeGraphic, transform)
        }

        public function isEnabled():Boolean
        {
            return enabled
        }

        public function clear():void
        {
            shapes = new Vector.<Vector.<Object>>
            calculateShapes()
        }

        ///////////////////////////////////////////////////////////////////////
        // Private Variables

        private var mDrawables:Vector.<Shape> = new Vector.<Shape>
        private var mDrawnShapes:Vector.<Vector.<Object>> = new Vector.<Vector.<Object>>
        private var mTriangles:Vector.<Vector.<Object>> = new Vector.<Vector.<Object>>

        ///////////////////////////////////////////////////////////////////////
        // Private Funcions

        private function calculateShapes():void
        {
            mTriangles = new Vector.<Vector.<Object>>
            mDrawables = new Vector.<Shape>

            for each (var shape:Vector.<Object> in mDrawnShapes)
            {
                var triangulator:Triangulator = new Triangulator(shape)
                var triangles:Vector.<Vector.<Object>> = triangulator.triangles

                if (triangles)
                {
                    pushDrawable(shape, 3, 0x00FF00, 0.5)
                    mTriangles = mTriangles.concat(triangles)
                }
                else
                {
                    pushDrawable(shape, 3, 0xFF0000, 0.5)
                }
            }

            for each (var triangle:Vector.<Object> in mTriangles)
            {
                pushDrawable(triangle, 1, 0x000000, 0.25, true, 0x00FF00, 0.15)
            }
        }

        private function pushDrawable(shape:Vector.<Object>, lineThickness:uint, lineColor:uint,
                                   lineAlpha:Number, fill:Boolean = false, fillColor:uint = 0x000000, fillAlpha:Number = 0.5):void
        {
            var drawable:Shape = new Shape
            if (shape.length > 0)
            {
                drawable.graphics.lineStyle(lineThickness, lineColor, lineAlpha, true)
                if (fill)
                    drawable.graphics.beginFill(fillColor, fillAlpha)

                drawable.graphics.moveTo(shape[shape.length-1].x, shape[shape.length-1].y)
                for each (var vert:Object in shape)
                    drawable.graphics.lineTo(vert.x, vert.y)

                if (fill)
                    drawable.graphics.endFill()
            }
            mDrawables.push(drawable)
        }
    }
}