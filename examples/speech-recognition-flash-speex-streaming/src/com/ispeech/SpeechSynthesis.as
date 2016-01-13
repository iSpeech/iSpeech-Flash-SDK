package  com.ispeech{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.events.HTTPStatusEvent;
	/**
	 * Contains methods used to synthesize speech from text. 
	 * <p> An API key is required to use this class. You may obtain a free key from http://www.ispeech.org</p>
	 *
	 * <p>Example:</p>
	 * <pre>
	 * 			var obj:SpeechSynthesis=new SpeechSynthesis(&quot;APIKEY&quot;, true);
	 * 			obj.speak(&quot;apples&quot;);
	 * </pre>
	 */
	public class SpeechSynthesis extends EventDispatcher{
		/***
		 * Stores credits of corresponding apikey. You must call information() to receive data
		 */
		public var credits:Number=-1;
		private var link:String="http://";
		private var api:String;
		private var vars:URLVariables=new URLVariables(), req:URLRequest, loader:URLLoader=new URLLoader(), loader2:URLLoader=new URLLoader();
		private var optionalParameters:Object={voice: "usenglishfemale1"};
		private var s:Sound;	
		public function SpeechSynthesis(ApiKey:String, production:Boolean=false) {
			// constructor code
			 if (ApiKey == null || ApiKey.length!= 32)
	         	throw(new Error("API key is invalid"));
			 else
			 	api=ApiKey;
			
			if(production)
				link+="api.ispeech.org/api/rest";
			else
				link+="debug.ispeech.org/api/rest";
		}
		
		/**
		 * Gets an instance of the iSpeech SpeechSynthesis class. The ApiKey
		 * parameter is only required on initial call to this method.
		 * 
		 * @param ApiKey
		 *            Your API key provided by iSpeech.
		 * @param production
		 *            Set to true if you are deploying your application. Set to false if you are using the sandbox environment.
		 * 
		 */
		public static function getInstance(api:String, production:Boolean):SpeechSynthesis{
			return(new SpeechSynthesis(api, production));
		}
		
		/**
		 * Specify additional parameters to send to the server.
		 *
		 * @param command A valid command
		 * @param parameter A valid setting for the command
		 */								   
		public function setOptionalCommand(command:String, parameter:String):void{
			optionalParameters[command]=parameter;
		}
		
		/**
		 * Clears all optional parameters that were set.
		 */
		public function clearMetaAndOptionalCommands():void{
			optionalParameters={voice: "usenglishfemale1"}
		}
		
		/***
		 * Converts text into speech.
		 * Audio begins to stream through this object. 
		 * 
		 * @param text
		 *            The text you wish to have converted into audio.
		 */
		public function speak(text:String/*,speechSynthesisEvent:SpeechSynthesisEvent*/):void{
			if (text == null || text.length == 0)
				throw (new Error("Invalid Text"));
			vars=new URLVariables();
			vars.apikey=api;
			vars.text=text; 
			vars.voice=optionalParameters.voice;
			vars.action="convert";
			if(optionalParameters.format!=undefined)
				vars.format=optionalParameters.format;
			if(optionalParameters.speed!=undefined)
				vars.speed=optionalParameters.speed;
			if(optionalParameters.bitrate!=undefined)
				vars.bitrate=optionalParameters.bitrate;
			if(optionalParameters.startpadding)
				vars.startpadding=optionalParameters.startpadding;
			if(optionalParameters.endpadding!=undefined)
				vars.endpadding = optionalParameters.endpadding;
			if (optionalParameters.model != undefined)
				vars.model = optionalParameters.model;
			
			req=new URLRequest(link)
			req.method="POST";
			req.data=vars;
			trace(req.url+"&"+req.data);
			s=new Sound();
			s.load(req);
			s.play();
			loader.load(req);
			loader.addEventListener(Event.COMPLETE, onComp);
			loader.addEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, prog);
		}
		
		private function httpStatusHandler(e:HTTPStatusEvent):void 
		{
			//trace(e);
		}

		private function prog(e:ProgressEvent):void{
			//trace(e);
		}
		private function onComp(e:Event):void{
			var str:String;
			//trace(e.target.data);
			//var obj:URLVariables=new URLVariables(e.target.data);
			//trace(obj.contentType);
			try{
				var vars2:URLVariables=new URLVariables(e.target.data);
				str=vars2.message;
			}catch(e:Error){}
			if(str!=null)
				throw(new Error(str));
			
		}
		
		/**
		 * Finds amount of credits for your apikey. since flash is event-driven this value cannot be returned in this function. Instead, it is stored in the credits property of the class.
		 * A datagetevent is dispatched, the value of credits is stored in it's data property.
		 */
		public function information():void{
			vars=new URLVariables();
			vars.apikey=api;
			vars.action="information";
			req=new URLRequest(link)
			req.method="POST";
			req.data=vars;
			loader2=new URLLoader();
			loader2.load(req);
			loader2.addEventListener(Event.COMPLETE, onInformationComplete);
		}
		
		private function onInformationComplete(e:Event):void{
			var vars2:URLVariables=new URLVariables(e.target.data);
			if(vars2.result=="error"){
				throw(new Error(vars2.message));
			}else{
				credits=Number(vars2.credits);
				var dge:DataGetEvent=new DataGetEvent();
				dge.data=""+credits;
				dispatchEvent(dge);
			}
		}
		/**
		 * Sets the voice, default is usfemaleenglish1
		 * 
		 */
		public function setVoice(voice:String):void{
			optionalParameters.voice=voice;
		}

	}
	
}
