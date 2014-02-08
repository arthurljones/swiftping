package swiftping.logcombo.enums
{
    /**
    * @author Scott Bilas - http://scottbilas.com/2008/06/01/faking-enums-in-as3/
    */

    import flash.utils.describeType

    public class CStringUtils
    {
        public static function InitEnumConstants(inType :*) :void
        {
            var type :XML = describeType(inType)
            for each (var constant :XML in type.constant)
                inType[constant.@name].text = constant.@name
        }
    }

}