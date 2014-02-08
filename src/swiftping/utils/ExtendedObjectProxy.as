package swiftping.utils
{
    import flash.events.Event
    import flash.events.EventDispatcher
    import flash.events.IEventDispatcher
    import flash.utils.Proxy
    import flash.utils.flash_proxy

    import mx.events.PropertyChangeEvent
    import mx.events.PropertyChangeEventKind
    import mx.utils.ObjectProxy
    import mx.utils.object_proxy

    use namespace flash_proxy
    use namespace object_proxy

    ;[Bindable("propertyChange")]
    dynamic public class ExtendedObjectProxy extends Proxy implements IEventDispatcher
    {
        protected var mGetters:Object = {}
        protected var mSetters:Object = {}
        protected var mCascades:Object = {}
        protected var mObject:ObjectProxy = null
        protected var mEventDispatcher:EventDispatcher = null
        protected var mDebug:Boolean = false

        protected var mAccessorReentryCount:uint = 0

        public function ExtendedObjectProxy(debug:Boolean = false)
        {
            mDebug = debug
            mEventDispatcher = new EventDispatcher(this)
        }

        public function setObject(obj:Object):void
        {
            localTrace("EOP: setObject: " + mObject + "->" + obj)

            var oldValues:Object = {}
            var prop:String

            var oldObj:ObjectProxy = mObject
            var newObj:ObjectProxy = new ObjectProxy(obj)

            if (oldObj != null)
            {
                for each (prop in propertyList)
                    oldValues[prop] = this[prop]

                oldObj.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangePassthrough)
            }

            mObject = newObj

            if (mObject != null)
            {
                newObj.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangePassthrough)

                for each (prop in propertyList)
                {
                    var oldVal:* = oldValues[prop]
                    var newVal:* = this[prop]

                    if (oldVal != newVal)
                        propertyChanged(prop, oldVal, newVal)
                }
            }
        }

        public function get propertyList():Array
        {
            var props:Array = []
            var prop:String

            for each (prop in enumerateObjectProperties(mObject.object_proxy::object))
                props.push(prop)
            for (prop in mGetters)
                props.push(prop)

            return props
        }

        //Binds a getter to a name. Additional arguments are taken as cascades,
        // that is, variables that will change the output of the getter if changed
        public function setGetter(propName:String, getter:Function, ...cascades):void
        {
            localTrace("EOP: Set getter for \"" + propName + "\"")
            mGetters[propName] = getter

            for each (var cascade:* in cascades)
                if (cascade is String)
                    addCascade(cascade as String, propName)
        }

        public function setSetter(propName:String, setter:Function):void
        {
            localTrace("EOP: Set setter for \"" + propName + "\"")
            mSetters[propName] = setter
        }

        public function accessorGet(propName:String):*
        {
            if (mAccessorReentryCount == 0)
            {
                Log.log("EOP: ERROR: It is forbidden to use accessorGet from outside an accessor")
                return null
            }
            else
            {
                return mObject[propName]
            }
        }

        public function accessorSet(propName:String, value:*):void
        {
            if (mAccessorReentryCount == 0)
            {
                Log.log("EOP: ERROR: It is forbidden to use accessorSet from outside an accessor")
            }
            else
            {
                mObject[propName] = value
            }
        }

        public function addCascade(triggerPropName:String, resultPropName:String):void
        {
            if (mCascades[triggerPropName] == null)
                mCascades[triggerPropName] = []

            mCascades[triggerPropName].push(resultPropName)

            localTrace("EOP: Added cascade: " + triggerPropName + " triggers " + resultPropName)
        }

        flash_proxy override function getProperty(name:*):*
        {
            var val:* = internalGet(name)
            localTrace("EOP: getProperty: \"" + name + "\": " + val)
            return val
        }

        flash_proxy override function setProperty(name:*, value:*):void
        {
            //If the prop has a setter, send the propchange event ourselves. Otherwise, let the passthrough handle it.
            var setter:Function = mSetters[name]
            if (setter != null)
            {
                var oldValue:* = internalGet(name)
                mAccessorReentryCount++
                setter(this, value)
                mAccessorReentryCount--
                var newValue:* = internalGet(name)

                localTrace("EOP: Called setter: \"" + name + "\": " + oldValue + "->" + newValue)
                propertyChanged(name, oldValue, newValue)
            }
            else
            {
                localTrace("EOP: Changed value directly: \"" + name + "\": " + value)
                mObject[name] = value
            }
        }

        flash_proxy override function callProperty(name:*, ... rest):*
        {
            var func:Function = mObject[name] as Function
            return func.apply(mObject, rest)
        }

        ///////////////////////////////////////////////////////////////////////
        // Internal Functions

        private function propertyChanged(property:String, oldValue:*, newValue:*):void
        {
            localTrace("EOP: propertyChanged: \"" + property + "\": " + oldValue + "->" + newValue)
            var cascadeStack:Array = []
            cascadeStack.push({prop: property, old: oldValue, val: newValue})

            while (cascadeStack.length > 0)
            {
                var change:Object = cascadeStack.pop()

                for each (var cascadeProp:String in mCascades[change.prop])
                {
                    //We can't know what the pre-change value was easily, so just send the new value twice for now.
                    var cascadeVal:* = internalGet(cascadeProp)
                    localTrace("\tCascade: \"" + cascadeProp + "\": ? -> " + cascadeVal)
                    cascadeStack.push({prop: cascadeProp, old: cascadeVal, val: cascadeVal})
                }

                dispatchPropertyChangeEvent(this, change.prop, change.old, change.val)

                if (cascadeStack.length > 500)
                    throw new Error("Cascade stack overflow")
            }
        }

        private function propertyChangePassthrough(e:PropertyChangeEvent):void
        {
            localTrace("EOP: PropChange event passthrough")
            propertyChanged(e.property as String, e.oldValue, e.newValue)
        }

        private function internalGet(name:*):*
        {
            if (mObject == null)
            {
                Log.log("EOP: Property get with a null object")
                return null
            }

            var getter:Function = mGetters[name]
            if (getter != null)
            {
                mAccessorReentryCount++
                return getter(this)
                mAccessorReentryCount--
            }
            else if (mObject[name] != undefined)
            {
                return mObject[name]
            }
            else
            {
                throw new Error("Attempt to access undefined property \"" + name + "\"")
            }
        }

        private function localTrace(str:String):void
        {
            if (mDebug)
                Log.log(str)
        }

        ///////////////////////////////////////////////////////////////////////
        // eventDispatcher Interface Implementation

        public function hasEventListener(type:String):Boolean
        {
            return mEventDispatcher.hasEventListener(type)
        }

        public function willTrigger(type:String):Boolean
        {
            return mEventDispatcher.willTrigger(type)
        }

        public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0.0, useWeakReference:Boolean=false):void
        {
            mEventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference)
        }

        public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
        {
            mEventDispatcher.removeEventListener(type, listener, useCapture)
        }

        public function dispatchEvent(event:Event):Boolean
        {
            return mEventDispatcher.dispatchEvent(event)
        }
    }
}
