package swiftping.logcombo.formatters 
{
	
	/**
	* From http://www.flex-tutorial.fr - fnicollet
	*/
	
	import mx.formatters.Formatter;

	public class zeroFillFormatter extends Formatter
	{
		
		// Number of 0 to add
		private var _count:int;
		public function set count(value:int):void{
			_count = value;
		}
		public function get count():int{
			return _count;
		}

		/**
		 * CONSTRUCTOR
		 */
		public function zeroFillFormatter(){
			super();
			_count = -1;
		}
		
		// méthode format() à surcharger
		override public function format(value:Object):String{
			// si nécessaire, on convertit le paramètre en une String, sinon on le cast en String
			var stringValue:String;
			if(!(value is String)){
				stringValue = value.toString();
			} else {
				stringValue = String(value);
			}

			// si la longueur de la chaîne est inférieure à _count,
			// on la précède par des zéros
			while (_count > stringValue.length){
				stringValue = "0" + stringValue;
			}
			return stringValue;
		}
	}
}