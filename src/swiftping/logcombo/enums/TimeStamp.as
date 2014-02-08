package swiftping.logcombo.enums
{
    /**
    * @author Arnaud FOUCAL - afoucal@free.fr - http://afoucal.free.fr
    * @licence
    * http://creativecommons.org/licenses/by/3.0/
    * Just give my name and the url of my blog somewhere where you use the component
    *
    * @version 1.0
    *     First release
    */
    public class TimeStamp
    {
        public var text :String
        {CStringUtils.InitEnumConstants(TimeStamp);} // static ctor

        public static const NONE        :TimeStamp = new TimeStamp()
        public static const TIME        :TimeStamp = new TimeStamp()
        public static const DDMMYYYY    :TimeStamp = new TimeStamp()
        public static const MMDDYYYY    :TimeStamp = new TimeStamp()
        public static const FULL        :TimeStamp = new TimeStamp()
        public static const SEMIFULL    :TimeStamp = new TimeStamp()
    }
}