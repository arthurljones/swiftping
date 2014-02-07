package swiftping.utils
{
	import flash.utils.describeType;
	public function enumerateObjectProperties(object:Object):Array
	{
		var sourceInfo:XML = describeType(object);
		var objectProperty:XML;
		var propName:String;
		var props:Array = [];
		
		for each (objectProperty in sourceInfo.variable)
		props.push(objectProperty.@name);
		
		for each (objectProperty in sourceInfo.accessor)
		props.push(objectProperty.@name);
		
		for (propName in object)
			props.push(propName);
		
		return props;
	}
}