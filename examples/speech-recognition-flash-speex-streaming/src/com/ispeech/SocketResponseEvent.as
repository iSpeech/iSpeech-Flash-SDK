package com.ispeech
{
	import flash.events.Event;
	import flash.utils.ByteArray;

	public class SocketResponseEvent extends Event
	{
		public var data:ByteArray;
		static public var ENCODE:String="ISPEECH_SPEEX_ENCODE_COMPLETE";
		public function SocketResponseEvent(data2:ByteArray=null)
		{
			super("ISPEECH_SPEEX_ENCODE_COMPLETE");
			data=data2;
		}
	}
}