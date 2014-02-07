package swiftping.logcombo.enums 
{
	/**
	* @author Arnaud FOUCAL - afoucal@free.fr - http://afoucal.free.fr
	* @licence
	* http://creativecommons.org/licenses/by/3.0/
	* Just give my name and the url of my blog somewhere where you use the component
	* 
	* @version 1.0
	* 	First release
	* 
	* @usage
	* List the types of logs that are loggued in the LogComboBox component
	* 
	* How to add a new LogType:
	* - add a new type here
	* - find and put an icon in your asset folder
	* - open the LogComboBox component source
	* - go to the section 'Define icon classes'
	* - add an Embed statement + new class to embed the icon of your new log type
	* - go to the IconLabel function
	* - add a new case based on your new type and returning your new class
	*/
	
	public class LogType
	{
		public var text :String;
		{CStringUtils.InitEnumConstants(LogType);} // static ctor

		public static const TEXT		:LogType = new LogType();
		public static const OBJECT		:LogType = new LogType();
		public static const DATA		:LogType = new LogType();
		public static const EVENT		:LogType = new LogType();
	}
}