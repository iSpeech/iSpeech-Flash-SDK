package {
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.net.FileReference;
	import flash.net.Socket;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.net.URLRequestMethod;
	
	/**
	 * Contains methods used to synthesize speech from text. 
	 * 
	 * <p>An API key is required to use this class. You may obtain a free key from http://www.ispeech.org</p>
	 *
	 * <p>SpeechRecognizer can be accessed as a Singleton with getInstance(). When you are using SpeechRecognizer to stream packets of audio to the server, 
	 * events will be dispatched upon connection to the server, disconnect, fully comitted data, record cancellation, and server completion.
	 * </p>
	 * 
	 *
     * <p>
	 * Example:
	 * </p>
	 * 
	 * <pre>
	 *  var rec:SpeechRecognizer = SpeechRecognizer.getInstance(&quot;APIKEY&quot;, true);
	 * 	rec.addEventListener(SpeechRecongizer.CONNECTED, onConnect);
	 * 	
	 * 	private function onConnect(e:Event)
	 * {
	 * 	...
	 * }
	 * 
	 * </pre>
	 * 
	 * <p>To grab server responses, listen for a DataGetEvent object. </p>
	 * 
	 * <p>
	 * Example:
	 * </p>
	 * 
	 * <pre>
	 *  var rec:SpeechRecognizer = SpeechRecognizer.getInstance(&quot;APIKEY&quot;, true);
	 * 	rec.addEventListener(DataGetEvent.ENCODE, onServerResponse);
	 * 	
	 * 	private function onServerResponse(e:Event)
	 * {
	 * 	trace("The interpreted text was: ", e.data);
	 * 	trace("The accuracy of the text based on the audio is ", e.conf); //confidence and data are the only properties accessible in DataGetEvent
	 * }
	 * 
	 * </pre>
	 * Additionally, you can choose from a set of different speech models by using the setFreeform() command. These different models are described in the properties description.
	 * <p>By default, freeform is set to 0, which is commands and alias mode.</p>
	 * 
	 * Use startRecordAndNotify() or startRecordWithoutStream() to begin the process.
	 */
	public class SpeechRecognizer extends Socket{
		private var _apiKey:String, _production:Boolean;		
		public var mic:Microphone;
		private var stopTimer:Timer;
		private var output:String="";
		private var host:String="Host: ";
		private var micStopFlag:Boolean=false;
		private var link:String = "";
		
		private var optionalParameters:Object={"freeform":0};
		private var requiredHeaders:String="&action=recognize&content-type=audio/speex HTTP/1.1\r\nX-Stream: http\r\nContent-Type: audio/speex\r\n";
		private var commandIndex:Number=0;
		private var notifyInMillisec2:Number, silencelevel2:Number;
		private var h:Array=new Array(0);
		private var k:Array=new Array(0);
		private var type:Array=new Array(0);
		public var speexEncoder:iSpeechSpeexEncoder=new iSpeechSpeexEncoder();
		private var lastpacket:Boolean=false;
		private var pcmba:ByteArray = new ByteArray();
		private var isRecording:Boolean = false;
		private var gain:Number = 80;
		
		private var request:URLRequest;
		private var streamMode:Boolean = true;
		private var isCallibrating:Boolean = false;		
		
		public var mic2:Microphone;
		public var sum:Number;
		public var samps:Number;
		public var bytesWritten:int = 0;
		public var lastEvent:String = "";
		public var rawResult:String = "";
		
		/**
		 * Event type that is dispatched when connected to the socket server.
		 */
		public static const CONNECTED:String = "ISPEECH_CONNECTED_TO_SERVER";
		
		/**
		 * Event type that is dispatched when disconnected from the socket sever
		 */
		public static const DISCONNECTED:String = "ISPEECH_DISCONNECTED_FROM_SERVER";
		/**
		 * Event type that is dispatched when all of the encoded audio is sent to the server
		 */
		public static const COMMITTED:String = "ISPEECH_COMMITED_DATA_TO_SERVER";
		/**
		 * Event type that is dispatached once a microphone is recognized and the recording process starts
		 */
		public static const RECORDING_INIT:String = "ISPEECH_RECORDING_STARTED";
		/**
		 *Event type that is dispatched when the server is generating a responses, the beginning of the wait. 
		 */
		public static const RECORDING_COMPLETE:String = "ISPEECH_RECORDING_COMPLETE";
		/**
		 * Event type that is dispatched when the user cancels the event, through cancelRecord();
		 */
		public static const RECORDING_CANCELED:String = "ISPEECH_RECORDING_CANCELED";
		
		/**
		 * Disable free form speech recognition.
		 */
		public static const FREEFORM_DISABLED:Number = 0;
		/**
		 * A SMS or TXT message.
		 */
		public static const FREEFORM_SMS:Number = 1;
		/**
		 * A voice mail transcription
		 */
		public static const FREEFORM_VOICEMAIL:Number = 2;
		/**
		 * Free form dictation, such as a written document
		 */
		public static const FREEFORM_DICTATION:Number = 3;
		/**
		 * A message addressed to another person.
		 */
		public static const FREEFORM_MESSAGE:Number = 4;
		/**
		 * A message for an instant message client
		 */
		public static const FREEFORM_INSTANT_MESSAGE:Number = 5;
		/**
		 * General transcription
		 */
		public static const FREEFORM_TRANSCRIPT:Number = 6;
		/**
		 * A memo or a list of items
		 */
		public static const FREEFORM_MEMO:Number = 7;
		
		
		
		public function SpeechRecognizer(api:String, production:Boolean) {
			
			pcmba.endian=Endian.LITTLE_ENDIAN;
			
			_apiKey=api;			
			_production=production;
			if (api == null || api.length != 32)
				throw(new Error("Invalid API key"));
			
			if(production){
				link="api.ispeech.org";
				host+="api.ispeech.org\r\n";
			}else{
				link="dev.ispeech.org";
				host+="dev.ispeech.org\r\n";
			}
			
			var s:Sound=new Sound();
			
			addEventListener(Event.CONNECT,connectionEstablished); 
			addEventListener(Event.CLOSE, disconnect);
			addEventListener(ProgressEvent.SOCKET_DATA, onProg);
		}
		
		private function disconnect(e:Event):void{
			lastEvent = "Last Event: Socket Disconnected";
			dispatchEvent(new Event(DISCONNECTED));
		}
									 
		private function onEncodeComplete(e:SocketResponseEvent):void{
			try {
				writeInt(e.data.length);
				writeBytes(e.data, 0, e.data.length);
				bytesWritten += e.data.length;
				flush();
				if (lastpacket) { 
					//trace("finished encoding");
					writeInt(0);
					flush();
					lastpacket = false;
					speexEncoder.removeEventListener(SocketResponseEvent.ENCODE, onEncodeComplete);
				}
			}catch (e:Error) {
				trace("error occured when sending encoded data to server... onEncodeComplete()");
			}
		}
		
		private function connectionEstablished(e:Event):void{
			lastEvent = "Last event: Socket connected";
			
			var str:String="POST /api/rest/?";
			var commandsandaliases:String="";
			var aliasids:String="&alias=";
			str+="apikey="+_apiKey;
			var isCommand:Boolean=true;
			if(optionalParameters["freeform"]==0 && h.length>0){
				if(h.length>0){
					for(var i:Number=0; i<h.length;i++){
						
						if(type[i]=="c"){
							commandsandaliases+="&"+h[i]+"="+k[i];
							if(i!=0)
								aliasids+="|"+h[i];
							else
								aliasids+=h[i];
						}else{
							if(i!=0)
								aliasids+="|"+h[i];
							else
								aliasids+=h[i];
							commandsandaliases+="&"+h[i]+"=";
							for(var j:Number=0; j<k[i].length;j++){
								if(j!=0)
									commandsandaliases+="|"+k[i][j];
								else
									commandsandaliases+=k[i][j];
							}
						}
						
					}
					str+=aliasids+commandsandaliases+"&output=xml&deviceType=flashSDK";	
				}
			}else if(optionalParameters["freeform"]==0 && h.length<=0){
				throw(new Error("List of command and aliases is null. If you do not wish to use commands and aliases, then use setFreeform() to set freeform to a value not equal to zero"));
			}
			if(optionalParameters["freeform"]!=undefined)
				str+="&freeform="+optionalParameters["freeform"];	
			if(optionalParameters["locale"]!=undefined)
				str += "&locale=" + optionalParameters["locale"];
			if (optionalParameters["model"] != undefined)
				str += "&model=" + optionalParameters["model"];
				
			str += "&speexmode=2";
			str+=requiredHeaders;
			str+="Host: " + link+"\r\n\r\n";
			writeUTFBytes(str);
			bytesWritten += str.length;
			flush();
			
			//trace(str);
			sendPreConnectData();
			
			dispatchEvent(new Event(CONNECTED));
			
			if(mic!=null){
			}else {
				throw(new Error("Microphone not connected but connection to server has been made"));
			}
		}
		
		private function sendPreConnectData():void 
		{
			//trace("sendPreConnectData"); 
			speexEncoder.encode(pcmba);
		}
		/**
		 * Gets an instance of the iSpeech SpeechRecognizer class. The ApiKey
		 * parameter is only required on initial call to this method. Probably not useful
		 * 
		 * @param ApiKey
		 *            Your API key provided by iSpeech.
		 * @param production
		 *            Set to true if you are deploying your application. Set to false if you are using the sandbox environment.
		 * 
		 */
		public static function getInstance(api:String, production:Boolean):SpeechRecognizer{
			return(new SpeechRecognizer(api, production));
		}
		
		/***
		 * Adds a new command phrase. Note: You can only use two aliases per
		 * command. 
		 * @param commandPhrase
		 *            An string containing your command phrase
		 *
		 * @see addCommands
		 */
		public function addCommand(commandPhrase:String):void{
			addCommands(new Array(commandPhrase));
		}
		
		/***
		 * Adds multiple new command phrases. 
		 * Note: You can only use two aliases per command.
		 *
		 * <p>
		 * Example:
		 * </p>
		 * 
		 * <pre>
		 *  var rec:SpeechRecognizer = SpeechRecognizer.getInstance(&quot;APIKEY&quot;);
		 * var commands:Array = new Array(&quot;yes&quot;,&quot;no&quot;);
		 * rec.addCommand(commands);
		 * </pre>
		 * 
		 * The user can now speak "Yes" or "No" and it will be recognized correctly.
		 * 
		 *@param commandPhrase array of strings.
		 */
		public function addCommands(commandPhrase:Array):void{
			if(commandPhrase!=null && commandPhrase.length>0){
				for(var i:Number=0; i<commandPhrase.length;i++){
					h.push("command"+(commandIndex+1));
					k.push(escape(commandPhrase[i]));
					commandIndex++;
					type.push("c");
				}
			}
		}
		
		/**
		 * <p>
		 * Adds an alias to use inside of a command. You can reference the added
		 * alias using %ALIASNAME% from within a command. Alias names are
		 * automatically capitalized. Note: You can only a maximum of two aliases
		 * per command.
		 * </p>
		 * <p>
		 * Example:
		 * </p>
		 * 
		 * <pre>
		 * SpeechRecognizer rec = SpeechRecognizer.getInstance(&quot;APIKEY&quot;);
		 * var names:Array = new Array(&quot;jane&quot;, &quot;bob&quot;, &quot;john&quot;);
		 * rec.addAlias(&quot;NAMES&quot;, names);
		 * rec.addCommand(&quot;call %NAMES%&quot;);
		 * </pre>
		 * <p>
		 * The user can now speak "call john" and it will be recognized correctly.
		 * </p>
		 * 
		 * @param aliasName
		 *            The name of your alias for referencing inside of your
		 *            commands.
		 * @param phrases
		 *            The list of phrases for this alias.
		 */
		public function addAlias(aliasname:String, phrases:Array):void{
			var ali:String=aliasname.toUpperCase();
			h.push(ali);
			k.push(phrases);
			type.push("a");
			commandIndex++;
		}
		
		/**
		 * Clears all commands and aliases from this {@see SpeechRecognizer}
		 * object.
		 */
		public function clear():void{
			h=new Array(0);
			k=new Array(0);
			type=new Array(0);
			commandIndex=0;
		} 
		
		/**
		 * Sets freeform. Default is SpeechRecongizer.FREEFORM_DISABLED.
		 */
		public function setFreeForm(freeformtype:Number):void{
			optionalParameters["freeform"]=freeformtype;
		}
		
		/**
		 * Set the speech recognition locale.
		 * @param localeCode
		 * Visit the iSpeech Developers center at http://www.ispeech.org or contact sales@ispeech.org to obtain a list of valid locale codes enabled for your account.
		 */
		public function setLanguage(localeCode:String):void{
			optionalParameters["locale"]=localeCode;			
		}
		
		/**
		 * Cancels a recording in progress and dismisses the current prompt if one
		 * is visible.
		 */
		public function cancelRecord():void {
			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, sd);
			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, mic_sampleData);
			stopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, stopTock);
			mic.removeEventListener(ActivityEvent.ACTIVITY, activityHandler)
			speexEncoder.removeEventListener(SocketResponseEvent.ENCODE, onEncodeComplete);
			speexEncoder.removeEventListener(SocketResponseEvent.ENCODE, onEncodeWithoutStream);
			dispatchEvent(new Event(RECORDING_CANCELED));
			lastpacket = false;
			isRecording = false;
			if(connected)
				close();
		}
		
		
		/**
		 * Begins recording from microphone. This specific method uses raw socket connections to pass data to iSpeech servers. Flash socket connections allow for fast server response time and should be used whenever possible. However anti-virus software may block iSpeech server responses. In this case, use startRecordWithoutStream.
		 * This method controls the duration of a recording based on a time limit or a silence threshold or both. 
		 *
		 * @param recordBluetooth Record from a connected bluetooth headset instead of the device
		 * @param notifyInMillisec The amount of time in milliseconds to record audio. After this time expires, a RECORDING_COMPLETE event will be triggered within this object.
		 * @param silenceLevel The silence threshold of the microphone. Ranges from 0 to 100, where 0 records all data. 		
		 */
		public function startRecordAndNotify(notifyInMillisec:Number, silencelevel:Number = 0):void {
			sum = 0;
			samps = 0;
			speexEncoder.addEventListener(SocketResponseEvent.ENCODE, onEncodeComplete);
			pcmba = new ByteArray();
			pcmba.endian = Endian.LITTLE_ENDIAN;
			
			//trace("started");
			if (isRecording || isCallibrating) {
				pcmba = new ByteArray();
				pcmba.endian = Endian.LITTLE_ENDIAN;
				stopRecord();
				throw(new Error("callibration taking place, or microphone is already recording, use isRecording to check the status"))
				return;
			}
				
			isRecording = true;
			streamMode = true;
			dispatchEvent(new Event(RECORDING_INIT));
			mic=Microphone.getMicrophone();
			notifyInMillisec2=notifyInMillisec;
			silencelevel2=silencelevel;
			mic.rate=16;
			mic.gain = gain;
			if(mic!=null){
				mic.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
				mic.addEventListener(StatusEvent.STATUS, statusHandler);
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, sd);				
				mic.setSilenceLevel(silencelevel, 1000);
				
				stopTimer=new Timer(notifyInMillisec, 1);
				stopTimer.start();
				stopTimer.addEventListener(TimerEvent.TIMER_COMPLETE, stopTock);
				
				connect(link, 80);
				micStopFlag=false;
				output="";
			}else{
				throw(new Error("Microphone has not been recognized."));
			}
		}
		
		public function startRecordWithoutStream(notifyInMillisec:Number, silencelevel:Number = 0):void {
			
			pcmba = new ByteArray();
			pcmba.endian = Endian.LITTLE_ENDIAN;
			
			//trace("started");
			if (isRecording) {
				pcmba = new ByteArray();
				pcmba.endian = Endian.LITTLE_ENDIAN;
				stopRecord();
				throw(new Error("microphone is already recording, use isRecording to check the status"));
				return;
			}
			
			isRecording = true;
			streamMode = false;
			mic=Microphone.getMicrophone();
			notifyInMillisec2=notifyInMillisec;
			silencelevel2=silencelevel;
			mic.rate=16;
			
			if(mic!=null){
				mic.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
				mic.addEventListener(StatusEvent.STATUS, statusHandler);
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, mic_sampleData);
				mic.setSilenceLevel(silencelevel, 1000);
				
				stopTimer=new Timer(notifyInMillisec, 1);
				stopTimer.start();
				stopTimer.addEventListener(TimerEvent.TIMER_COMPLETE, stopTock);
				
				micStopFlag=false;
				output = "";
				
			}else{
				throw(new Error("Microphone has not been recognized."));
			}
		}
		
		private function sd(e:SampleDataEvent):void{
			try {
				sum+=(mic.activityLevel)
				samps++;
				while(e.data.bytesAvailable>0)
				{
					var floatsample:Number=e.data.readFloat();
					var shortsample:Number=floatsample*(Math.pow(2,15)-1) //downsamples float to a signed short/double
					pcmba.writeShort(shortsample);
					if(connected && pcmba.length >= 4000){
						pcmba.position=0;
						speexEncoder.encode(pcmba);
						pcmba=new ByteArray();
						pcmba.endian=Endian.LITTLE_ENDIAN;
						pcmba.position=0;
					}
				}
			}catch(e:Error){
				mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, sd);
			}
		}
		
		private function mic_sampleData(e:SampleDataEvent):void 
		{
			while(e.data.bytesAvailable>0)
				{
					var floatsample:Number=e.data.readFloat();
					var shortsample:Number=floatsample*(Math.pow(2,15)-1) //downsamples float to a signed short/double
					pcmba.writeShort(shortsample);
				}
				//trace(pcmba.length);
		}
		
		/**
		 * Stops the recording process and sends data to server.
		 * A COMPLETE event is dispatched.
		 */
		public function stopRecord():void {
			
			if(isRecording){	
				isRecording = false;
				
				stopTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, stopTock);
				mic.removeEventListener(ActivityEvent.ACTIVITY, activityHandler);
				mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, mic_sampleData);			
			
				trace("Average mic activity" , sum/samps);
				isRecording = false;				
				if (streamMode) {
					mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, sd);
						if(pcmba.length<250){
							dispatchEvent(new Event(RECORDING_COMPLETE))
							writeInt(0);
							flush();
						}else{
							//trace("encoding tail");
							lastpacket = true;
							speexEncoder.encode(pcmba);
						}
				}else {
					speexEncoder.addEventListener(SocketResponseEvent.ENCODE, onEncodeWithoutStream);
					
					pcmba.position = 0;
					speexEncoder.encode(pcmba);
				}
				
				dispatchEvent(new Event(COMMITTED));
			}else {
				trace("not recording");
			}
		}
		
		private function onEncodeWithoutStream(e:SocketResponseEvent):void 
		{
			//trace("data created from nostream method");
			request = new URLRequest();
			request.contentType = "audio/speex";
			request.data = e.data;
			request.method = URLRequestMethod.POST;
			
			request.url = "http://api.ispeech.org/api/rest";
			request.url += "?apikey=" + _apiKey;
			request.url += "&deviceType=flashSDK&action=recognize";
			
			var commandsandaliases:String="";
			var aliasids:String="&alias=";
			var isCommand:Boolean=true;
			if(optionalParameters["freeform"]==0 && h.length>0){
				if(h.length>0){
					for(var i:Number=0; i<h.length;i++){
						
						if(type[i]=="c"){
							commandsandaliases+="&"+h[i]+"="+k[i];
							if(i!=0)
								aliasids+="|"+h[i];
							else
								aliasids+=h[i];
						}else{
							if(i!=0)
								aliasids+="|"+h[i];
							else
								aliasids+=h[i];
							commandsandaliases+="&"+h[i]+"=";
							for(var j:Number=0; j<k[i].length;j++){
								if(j!=0)
									commandsandaliases+="|"+k[i][j];
								else
									commandsandaliases+=k[i][j];
							}
						}
						
					}
					request.url+=aliasids+commandsandaliases;
				}
			}else if(optionalParameters["freeform"]==0 && h.length<=0){
				throw(new Error("List of command and aliases is null. If you do not wish to use commands and aliases, then use setFreeform() to set freeform to a value not equal to zero"));
			}
			
			if(optionalParameters["freeform"]!=undefined)
				request.url+="&freeform="+optionalParameters["freeform"];	
			if(optionalParameters["locale"]!=undefined)
				request.url += "&locale=" + optionalParameters["locale"];	
				
			var singleLoader:URLLoader = new URLLoader()
			singleLoader.addEventListener(Event.COMPLETE, singleLoader_complete);
			//trace(request.url);
			singleLoader.load(request);
			
		}
		
		private function singleLoader_complete(e:Event):void 
		{
			//ExternalInterface.call('log', e.target.data, 'occured');
			var string:String = e.target.data;
			
			//trace(string + "\n");
			var dataEvent:DataGetEvent = new DataGetEvent();
			//if(optionalParameters["freeform"]!=0){
				try{
					var vars:URLVariables = new URLVariables(string.substr(string.indexOf("text=")));
					trace(unescape(vars.confidence));
				}catch(e:Error){
					throw(new Error(vars.message));
				}
				//obj.text+="Output="+vars.text+"\n";
				output=vars.text;
				dataEvent.data = vars.text;
				dataEvent.confidence = Number(vars.confidence);
			/*}else{
				var dat:String = string.substring(string.indexOf("<text>") + 6, string.indexOf("</text>"));
				var confstr:String = string.substring(string.indexOf("<confidence>" + 12), string.indexOf("</confidence>"));
				dataEvent.data = dat;
				dataEvent.confidence = Number(confstr);
			}*/
			
			dispatchEvent(dataEvent);
			
		}
		
		private function statusHandler(e:StatusEvent):void {
			cancelRecord();
			isRecording = false;
			startRecordAndNotify(notifyInMillisec2, silencelevel2);
			
		}
		
		private function activityHandler(e:ActivityEvent):void{			
			if(!e.activating && !micStopFlag){
				micStopFlag = true;
				stopRecord();
			}else{
				//obj.text+="mic on...\n";
			}
		}
	
		private function stopTock(e:TimerEvent):void{
			stopRecord();
		}
		
		/**
		 * Specify the gain of the microphone.
		 *
		 * @param gain Default is 50. Range is 0 to 100.
		 * 
		 */
		public function setGain(_gain:Number):void {
			gain = _gain;
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
		
		private function onProg(e:ProgressEvent):void {
			
			var dataEvent:DataGetEvent=new DataGetEvent();
			var string:String = readUTFBytes(e.bytesLoaded);
			
			rawResult = string.substr(string.indexOf("\r\n\r\n")+4);
			
			//trace(string+"\n");
			if(optionalParameters["freeform"]!=0){
				try {
					var vars:URLVariables = new URLVariables(string.substr(string.indexOf("text=")));
					//trace(unescape(vars.confidence));
				}catch (e:Error) {
					var vars2:URLVariables = new URLVariables(string.substr(string.indexOf("result=")));
					//trace(vars2.toString());
					trace("iSpeech ASR Error: "+vars2.message);
				}
				
				output=vars.text;
				dataEvent.data = vars.text;
				dataEvent.confidence = Number(vars.confidence);
			}else {
				var dat:String = string.substring(string.indexOf("<text>") + 6, string.indexOf("</text>"));
				var confstr:String = string.substring(string.indexOf("<confidence>" + 12), string.indexOf("</confidence>"));
				dataEvent.data = dat;
				dataEvent.confidence = Number(confstr);
			}
			
			dispatchEvent(dataEvent);
		}
		
		/**
		 * Your mic
		 */
		
		public function calibrate():void {
			trace("Say this: The blue fox jumped over the lazy dog.");
			isCallibrating = true;
			mic2 = Microphone.getMicrophone();
			//mic2.setSilenceLevel(3, 0);
			mic2.addEventListener(SampleDataEvent.SAMPLE_DATA, mic2_sampleData);
			mic2.addEventListener(ActivityEvent.ACTIVITY, mic2_activity);
			sum = 0;
			samps = 0;
		}
		
		public function stopCal() :void {
			isCallibrating = false;
			var ave:Number = sum / samps;
			trace("average", ave);
			gain = 50;
			if(ave<3){
				var gam:Number = gain * (4 / ave);
				setGain(gam);
			}
			if (ave < 1)
				gain=100
			
			
			trace("new gain", gain);
			
			var dge2:DataGetEvent = new DataGetEvent();
			dge2.data = "NEW GAIN IS" + gain;
			dge2.confidence = -1;
			
		}
		private function mic2_activity(e:ActivityEvent):void 
		{
			if (!e.activating) {
				trace("done ", sum / samps);
				mic2.removeEventListener(SampleDataEvent.SAMPLE_DATA, mic2_sampleData);
				mic2.removeEventListener(ActivityEvent.ACTIVITY, mic2_activity);
			}
		}
		
		private function mic2_sampleData(e:SampleDataEvent):void 
		{
			sum += mic2.activityLevel;
			samps++;
		}
		
	}
}