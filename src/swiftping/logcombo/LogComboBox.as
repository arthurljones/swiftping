/**
* @author Arnaud FOUCAL - afoucal@free.fr - http://afoucal.free.fr
* @licence
* http://creativecommons.org/licenses/by/3.0/
* Just give my name and the url of my blog somewhere where you use the component
* 
* @version 1.0
*     First release
* 
* @version 1.1
*     Added :
*         - Icon in the ComboBox, on the left of the textInput
*     Changed :
*         - text and value are overriden
*         - the definition of the icon classes and the function 'Icon' have been moved from the LogRenderer class
* 
* @version 1.2
*     - Interface no more needed
*     - Fixed performance issue with functions clear(), commitProperties() (commitProperties() is removed)
*     - Fixed bug when the combo is refreshed : showLastLog(), setComboText() and updateDisplayList() functions are modified
* 
* @version 1.2.1
* Some cleaning of code and comments improvements
* 
* Known issues:
* 1. The use of percentWidth to size the component may lead to "over" size with long strings
*     Workaround : use width property if you face this issue
* 2. The resizing of the Combo doesn't behave correctly if you use icon with different size. The droplist has strange behavior also (size, can't reach the last loggued item)
*     Workaround : use icons with same size to illustrate each log type.
*/

package swiftping.logcombo
{
    import flash.display.DisplayObject
    import flash.events.Event
    import mx.controls.ComboBox
    import mx.core.ClassFactory
    import mx.core.UIComponent
    import mx.events.DropdownEvent
    import mx.events.ListEvent
    import mx.core.IFlexDisplayObject

    import swiftping.logcombo.enums.TimeStamp
    import swiftping.logcombo.enums.LogType
    import swiftping.logcombo.formatters.zeroFillFormatter
    import swiftping.logcombo.renderers.LogRenderer

    public class LogComboBox extends ComboBox
    {
        /**
         * @private
         * Used as dataprovider of the ComboBox
         */
        private var _logs:Array = new Array()

        /**
         * @private
         * Formatter used to display numbers as 00
         * Used to format dates
         */
        private var formatter:zeroFillFormatter = new zeroFillFormatter()


        /**
         * CONSTRUCTOR
         */
        public function LogComboBox()
        {
            super()

            dataProvider = _logs
            editable = false
            prompt = "Log history..."

            itemRenderer = new ClassFactory(LogRenderer)

            // Set to 2 the formatter for date parts in timestamps
            formatter.count = 2

            // Avoid the selection of any item
            //     Only the last log can be shown using the showLastLogs property
            //     The droplist keeps clear when the user opens it
            addEventListener( 'change', function(e:ListEvent) :void
            {
                e.preventDefault()
            })

            // Make the dropdown list of the combo non selectable
            addEventListener( DropdownEvent.OPEN,
                    function ( e:DropdownEvent ):void
                    {
                        dropdown.selectable = false
                        dropdown.variableRowHeight = true
                        dropdown.scrollToIndex( (_logs.length>0) ? _logs.length-1 : 0 )
                    })
        }


        // An holder to embed the icon to display in the combo
        private var iconHolder:UIComponent

        override protected function createChildren():void
        {
            super.createChildren()

            iconHolder = new UIComponent()
            addChild(iconHolder)
        }


        /*
         * Adapted from http://blogs.adobe.com/aharui/2007/04/
         */
        override protected function measure():void
        {
            super.measure()

            if (iterator)
            {
                var iconClass:Class = Icon( _logs[ _logs.length-1 ] )
                var icon:IFlexDisplayObject = new iconClass() as IFlexDisplayObject

                while (iconHolder.numChildren > 0)
                    iconHolder.removeChildAt(0)

                iconHolder.addChild(icon as DisplayObject)
                measuredWidth += icon.measuredWidth
                measuredHeight = Math.max(measuredHeight, icon.measuredHeight + borderMetrics.top + borderMetrics.bottom)
            }
        }
        /*
         * END
         */

        /*
         * Adapted from http://blogs.adobe.com/aharui/2007/04/
         */
        override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
        {
            super.updateDisplayList(unscaledWidth, unscaledHeight)

            // The icon to be displayed in the combo depends on the value of _showLastLog property.
            // Then iconClass call the function Icon() with a null paramater to get the icon shown with the prompt
            // instead of the icon corresponding to a log type
            var iconClass:Class = ( _showLastLog) ? Icon( _logs[ _logs.length-1 ] ) : Icon(null)
            var icon:IFlexDisplayObject = new iconClass() as IFlexDisplayObject

            while ( iconHolder.numChildren > 0 )
                iconHolder.removeChildAt(0)

            iconHolder.addChild(icon as DisplayObject)
            iconHolder.y = ( unscaledHeight - icon.measuredHeight ) / 2 + getStyle('paddingTop')
            iconHolder.x = borderMetrics.left + getStyle('paddingLeft')
            textInput.x = icon.x + icon.measuredWidth + getStyle('horizontalGap')
            textInput.setActualSize( textInput.width - icon.measuredWidth, textInput.height )
            /*
             * END
             */

            // update the text that is displayed in the combo
            setComboText()
        }


        /**
         * @private
         * Update the text that is displayed in the combo
         */
        private function setComboText() :void
        {
            // only if there is something to show
            if (_logs.length > 0 && _showLastLog)
            {
                textInput.text = FormatLabel( _logs[_logs.length - 1] )
            }
            else if (_logs.length > 0 && !_showLastLog)
            {
                // show prompt
                selectedIndex = -1
            }
        }


        /**
         * As the LogComboBox avoid selecting items, some function as 'text' won't return any result.
         * So it need to be overriden
         */
        override public function get text() :String
        {
            if ( _logs.length > 0 )
            {
                return _logs[_logs.length-1].label
            }
            else
            {
                return prompt
            }
        }


        /**
         * As the LogComboBox avoid selecting items, some function as 'value' won't return any result.
         * So it need to be overriden.
         * selectedItem is replaced by _logs[_logs.length-1] which get the last log item
         */
        override public function get value():Object
        {
            if ( _logs.length > 0 )
            {
                // Always point to the last log
                var item:Object = _logs[_logs.length-1]

                if (item == null || typeof(item) != "object")
                    return item

                // Note: the explicit comparison with null is important, because otherwise when
                // the data is zero, the label will be returned.  See bug 183294 for an example.
                return item.data != null ? item.data : item.label
            }
            else
            {
                return text
            }
        }


        /**
         * @private
         * Format the displayed label in the combo by adding a timestamp, empty or not
         *
         * @param    item
         */
        private function FormatLabel ( item:Object ) :String
        {
            var s:String = new String()

            s = item.timelog + item.label

            return s
        }


        /**
         * Define the format of the timestamp to show in the logs
         * Possible values : TimeStamp.NONE, TimeStamp.TIME, TimeStamp.DDMMYYYY, TimeStamp.MMDDYYYY, TimeStamp.FULL, TimeStamp.SEMIFULL
         * @default TimeStamp.NONE
         */
        private var _timeStamp:TimeStamp = TimeStamp.NONE
        public function get timeStampFormat() :String
        {
            return _timeStamp.text
        }
        public function set timeStampFormat( ts:String ) :void
        {
            _timeStamp.text = ts

            // if there is something to update...
            if (_logs.length > 0)
            {
                // reformat all logs
                _logs.forEach(formatAllStamps)
                invalidateDisplayList()

                // and update the text displayed in the combo if the option showLastLog is true
                if (_showLastLog)
                {
                    setComboText()
                }
            }
        }


        /**
         * @private
         * Reformat all logs in the combo according to the defined TimeStampType
         * To be deleted if an itemRenderer is used in the Combo
         *
         * @param    element
         * @param    index
         * @param    arr
         */
        private function formatAllStamps ( element:*, index:int, arr:Array ) :void
        {
            element.timelog = formatStamp( element.rawtimelog as Date )
        }


        /**
         * @private
         * Format a Date according to a specific schema
         *
         * @param    d as Date
         *
         * @return String
         *
         */
        private function formatStamp ( d:Date ) :String
        {
            var timestring:String = formatter.format( d.getHours() ) + ":" + formatter.format( d.getMinutes() ) + ":" + formatter.format( d.getSeconds() )

            switch ( _timeStamp.text )
            {
                case TimeStamp.FULL.text :
                    return d + " > "
                    break

                case TimeStamp.SEMIFULL.text :
                    return d.toLocaleDateString() + ", " + timestring + " > "
                    break

                case TimeStamp.DDMMYYYY.text :
                    return formatter.format( d.getDate() ) + "/" + formatter.format( d.getMonth() + 1 ) + "/" + d.getFullYear() + " : "
                    break

                case TimeStamp.MMDDYYYY.text :
                    return formatter.format( d.getMonth() + 1 ) + "-" + formatter.format( d.getDate() )  + "-" + d.getFullYear() + ": "
                    break

                case TimeStamp.TIME.text :
                    return timestring + " - "
                    break

                default:
                    return ""
                    break
            }
        }

        /**
         * Define the maximum number of items in the log
         *
         * @default 25
         */
        private var _maxLogNumber:Number = 25
        public function get maxLogNumber() :Number
        {
            return _maxLogNumber
        }
        public function set maxLogNumber( n:Number ) :void
        {
            _maxLogNumber = n

            // remove additional logs
            if (n > 0)
            {
                while (_logs.length > n)
                {
                    _logs.shift()
                }
            }
            else
            {
                clear()
            }

            // and refresh the list
            invalidateDisplayList()
        }


        /**
         * Define if the last log item is displayed in the ComboBox.
         * If false, the ComboBox will display the default prompt
         */
        private var _showLastLog :Boolean = true
        public function get showLastLog() :Boolean
        {
            return _showLastLog
        }
        public function set showLastLog( b:Boolean ) :void
        {
            _showLastLog = b
            invalidateDisplayList()
        }


        /**
         * Add the given log value to the ComboBox
         * The obj parameters has the following attributes:
         *         label         : the text
         *         type        : the type of log as LogType.TEXT, LogType.DATA, LogType.EVENT. New types can be added into enums.LogType class and adding new icon classes. Use the syntax LogType.TEXT.text.
         *         logicon        : the icon corresponding to the type of log
         *         rawtimelog     : the full date at the log action
         *         timelog     : the rawtimelog formatted according to the TimeStamp value
         *
         * @param    obj
         */
        public function logThis ( obj:Object, type:String = null) :void
        {
            obj = obj.toString()

            if (type == null)
                type = LogType.TEXT.text

            if (obj.length > 0)
            {
                var newlog:Object = new Object()
                var t:Date = new Date()

                newlog.label = obj
                newlog.rawtimelog = t
                newlog.timelog = formatStamp( t )
                newlog.type = type
                newlog.logicon = Icon( newlog )

                // Shift the dataprovider if it is full, in order to free the last position
                if ( _logs.length >= _maxLogNumber )
                {
                    _logs.shift()
                }

                // Add the log to the dataprovider
                _logs.push( newlog )

                // Update the displayed log in the combobox if the option _showLastLog is true
                if (_showLastLog)
                {
                    // Use the TextInput member to avoid item selection
                    textInput.text = FormatLabel( newlog )
                }

                // Refresh the component
                invalidateDisplayList()
            }
        }

         /*
         * Define icon classes
         */
        [Embed(source='assets/text_icon.png')]        private var iconText:Class
        [Embed(source='assets/object_icon.png')]    private var iconObject:Class
        [Embed(source='assets/data_icon.png')]        private var iconData:Class
        [Embed(source='assets/event_icon.png')]        private var iconEvent:Class
        [Embed(source='assets/front_icon.png')]        private var iconPrompt:Class

        /**
         * @private
         * Assign the icon corresponding to the LogType
         *
         * @param    item
         *
         * @return icon class
         */
        private function Icon(obj:Object):Class
        {
            if ( obj )
            {
                switch (obj.type)
                {
                    case LogType.TEXT.text:
                        return iconText
                        break

                    case LogType.OBJECT.text:
                        return iconObject
                        break

                    case LogType.DATA.text:
                        return iconData
                        break

                    case LogType.EVENT.text:
                        return iconEvent
                        break

                    default:
                        return iconPrompt
                        break
                }
            }
            else
            {
                return iconPrompt
            }
        }


        /**
         * Clear the content of the LogComboBox
         */
        public function clear() :void
        {
            _logs = new Array()
            dataProvider = _logs
        }
    }
}