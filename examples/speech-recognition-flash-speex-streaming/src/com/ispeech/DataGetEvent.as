package com.ispeech
{
	import flash.events.Event;
	import flash.utils.ByteArray;

	/**
	 * General class dispatched when the server has returned values.
	 */
	public class DataGetEvent extends Event
	{
		public var data:String = "";
		public var confidence:Number = -1;
		
		/**
		 * Event type that is dispatched when the server has returned values.
		 */
		static public var ENCODE:String = "ISPEECH_SPEEX_ENCODE_COMPLETE2";
		
		public function DataGetEvent(data2:String=null, confidence2:Number=-1)
		{
			super("ISPEECH_SPEEX_ENCODE_COMPLETE2");
			data = data2;
			confidence = confidence2;
		}
	}
}