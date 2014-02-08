package swiftping.utils
{
    public function shallowCopyObject(sourceObject:Object, destinationObject:Object):void
    {
        for each (var property:String in enumerateObjectProperties(sourceObject))
        {
            if (sourceObject[property] != null)
            {
                if (destinationObject.hasOwnProperty(property))
                {
                    destinationObject[property] = sourceObject[property]
                }
            }
        }
    }
}