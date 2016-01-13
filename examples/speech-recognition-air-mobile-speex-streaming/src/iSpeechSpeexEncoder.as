package 
{
	import cmodule.iSpeechSpeexEncoderBeta.CLibInit;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.net.FileReference;

	/**Interfaces with speex encoder, not to be touched
	 * */
	public class iSpeechSpeexEncoder extends EventDispatcher
	{	
		private var isReady:Boolean=true;
		private var pcmba:ByteArray=new ByteArray();
		private var speexba:ByteArray=new ByteArray();
		private var output:ByteArray;
		private var loader:CLibInit=new CLibInit;
		private var lib:Object=loader.init();
		private var flag:Boolean=true;
		public var obj:Object;
		public var startEncodeTime:Date;
		public var encodeTime:int;
		public var events:String = "";
		
		public function iSpeechSpeexEncoder()
		{
			speexba.endian=Endian.LITTLE_ENDIAN;
			speexba.position=0;
			pcmba.position=0;
		}
		
		/** 
		 * 
		 **/		
		public function encode(pcm:ByteArray):Boolean{
			
			if(isReady){
				//output=speexba;
				speexba=new ByteArray();
				speexba.endian=Endian.LITTLE_ENDIAN;
				speexba.position=0;
				//must be 16-bit, little endian, @ 16000 hz
				startEncodeTime = new Date();
				lib.encode(encodeComplete, pcm, speexba);
				isReady = false;
				events = startEncodeTime.time + ": Speex encode started, "+pcm.length+" bytes \n" + events;
			}else{
				//don't want to compile 
			}
			return isReady;
		}
		
		/**Encoding is asynchronous, grab the encoded byte array via e.data.
		 **/
		private function encodeComplete(result:*):void{
			speexba.position=0;
			trace("Done encoding packet, packet length: " + speexba.length);
			var e:SocketResponseEvent =new SocketResponseEvent(speexba);
			trace("written", speexba.length);
			dispatchEvent(e);
			
			/*
			if (speexba.length > 248){
				var fileRef:FileReference = new FileReference();
				fileRef.save(speexba, "filename.spx");
			}
			*/
			
			var currentDate:Date = new Date();
			encodeTime = currentDate.time - startEncodeTime.time;
			events = currentDate.time + ": Speex encode finished, "+speexba.length+" bytes, " +encodeTime+" ms \n" + events;
			
			isReady=true;
		}
	}
}