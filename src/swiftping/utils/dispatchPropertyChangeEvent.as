package swiftping.utils
{
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	
	public function dispatchPropertyChangeEvent(object:Object, name:String, oldValue:*, newValue:*):void
	{
		var eventKind:String = PropertyChangeEventKind.UPDATE;
		var eventName:String = PropertyChangeEvent.PROPERTY_CHANGE;
		object.dispatchEvent(new PropertyChangeEvent(eventName, false, false, eventKind, name, oldValue, newValue, object));
	}	
}