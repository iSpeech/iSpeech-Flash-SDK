package 
{
	import SpeechRecognizer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.media.Microphone;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.display.StageAlign;
	import flash.net.Socket;
	import flash.utils.Endian;
	/**
	 *
	 * @author iSpeech, Inc.
	 *
	 */
	public class Main extends Sprite 
	{
		var timer:Timer;
		var mic:Microphone;
		var sock:Socket;
		var str:String;
		
		var volumeField:TextField;
		var socketConnectedField:TextField;
		var bytesWrittenField:TextField;
		var currentActionField:TextField;
		var speechRecognitionResultField:TextField;
		var parsedResultField:TextField;
		var recordButtonField:TextField;
		var conversionTimeField:TextField;
		var speexEncodeTimeField:TextField;
		var speexEncodeEventsField:TextField;
		
		var bytesWritten:int;
		var pcmba:ByteArray;
		var startTime:Date;
		var recordToFile:Boolean;
		var asr:SpeechRecognizer;
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		public function Main():void 
		{	
			recordToFile = false;
			
			recordButtonField = new TextField();
			recordButtonField.text = "Capture";
			recordButtonField.background =  true;
			recordButtonField.backgroundColor = 0xEBEBEB;
			recordButtonField.border = true;
			recordButtonField.height = 150;
			recordButtonField.width = 150;
			recordButtonField.x = 0;
			recordButtonField.y = 590;
			
			recordButtonField.addEventListener(MouseEvent.MOUSE_DOWN, startRecording);
			recordButtonField.addEventListener(MouseEvent.MOUSE_UP, stopRecording);
			addChild(recordButtonField);
			
			mic = Microphone.getMicrophone(0);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moved);
			
			if (mic.muted == true){
				Security.showSettings(SecurityPanel.PRIVACY);
			}
			
			mic.rate = 8;
			mic.gain = 50;
			mic.setSilenceLevel(0);
						
			volumeField = new TextField();
			volumeField.border = true;
			volumeField.height = 20;
			volumeField.width = 400;
			volumeField.x = 0;
			volumeField.y = 80;
			addChild(volumeField);
			
			socketConnectedField = new TextField();
			socketConnectedField.border = true;
			socketConnectedField.height = 20;
			socketConnectedField.width = 400;
			socketConnectedField.x = 0;
			socketConnectedField.y = 100;
			addChild(socketConnectedField);
			
			bytesWrittenField = new TextField();
			bytesWrittenField.border = true;
			bytesWrittenField.height = 20;
			bytesWrittenField.width = 400;
			bytesWrittenField.x = 0;
			bytesWrittenField.y = 120;
			addChild(bytesWrittenField);
			
			currentActionField = new TextField();
			currentActionField.border = true;
			currentActionField.height = 20;
			currentActionField.width = 400;
			currentActionField.x = 0;
			currentActionField.y = 140;
			addChild(currentActionField);
			
			speechRecognitionResultField = new TextField();
			speechRecognitionResultField.border = true;
			speechRecognitionResultField.height = 20;
			speechRecognitionResultField.width = 400;
			speechRecognitionResultField.x = 0;
			speechRecognitionResultField.y = 160;
			addChild(speechRecognitionResultField);
			
			parsedResultField = new TextField();
			parsedResultField.border = true;
			parsedResultField.height = 20;
			parsedResultField.width = 400;
			parsedResultField.x = 0;
			parsedResultField.y = 180;
			addChild(parsedResultField);
			
			conversionTimeField = new TextField();
			conversionTimeField.border = true;
			conversionTimeField.height = 20;
			conversionTimeField.width = 400;
			conversionTimeField.x = 0;
			conversionTimeField.y = 200;
			addChild(conversionTimeField);
			
			speexEncodeTimeField = new TextField();
			speexEncodeTimeField.border = true;
			speexEncodeTimeField.height = 20;
			speexEncodeTimeField.width = 400;
			speexEncodeTimeField.x = 0;
			speexEncodeTimeField.y = 220;
			addChild(speexEncodeTimeField);
			
			speexEncodeEventsField = new TextField();
			speexEncodeEventsField.addEventListener(MouseEvent.CLICK, clearSpeexEvents);
			speexEncodeEventsField.border = true;
			speexEncodeEventsField.height = 350;
			speexEncodeEventsField.width = 400;
			speexEncodeEventsField.x = 0;
			speexEncodeEventsField.y = 240;
			addChild(speexEncodeEventsField);
			
			var loader:Loader = new Loader;
			loader.load(new URLRequest("http://www.ispeech.org/images/ispeech-logo-dark.png"));
			addChild(loader);
			loader.x = 0;
			loader.y = 0;
				
			if (Microphone.names.length == 0)
				currentActionField.text = "Last event: No microphones detected";

			
			timer = new Timer(50, 0);
			timer.addEventListener(TimerEvent.TIMER, timerEvent);
			timer.start();
			
			asr = new SpeechRecognizer("developerdemokeydeveloperdemokey", true);
			asr.addEventListener(DataGetEvent.ENCODE, onServerResponse);
		}
		
		public function moved(e:Event):void {
			
			if (mic.muted == true)
				Security.showSettings(SecurityPanel.PRIVACY);
			else
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, moved);
		}
		
		public function clearSpeexEvents(e:MouseEvent=null):void {
			asr.speexEncoder.events = "";
		}
		
		private function startRecording(e:Event = null) {
			asr.setFreeForm(3);
			asr.startRecordAndNotify(10000);
			recordButtonField.text = "Capturing";
			recordButtonField.backgroundColor = 0xB1FFA3;
			startTime = new Date();
			asr.rawResult = "";
			parsedResultField.text = "";
			conversionTimeField.text = "";
			clearSpeexEvents();
		}	
		
		public function onServerResponse(e:DataGetEvent):void {
			parsedResultField.text = "Parsed Result: Text: " + e.data + ", Confidence: " + e.confidence;
			var currentDate:Date = new Date();
			conversionTimeField.text = "Conversion took: " + (currentDate.time-startTime.time) + " milliseconds";
		}
		
		public function timerEvent(e:Event):void {
			volumeField.text = "Microphone activity level: " + mic.activityLevel.toString();
			bytesWrittenField.text = "Bytes written: " + asr.bytesWritten;
			socketConnectedField.text = "Socket connected: " + asr.connected;
			currentActionField.text = asr.lastEvent;
			speechRecognitionResultField.text = "Raw result: " + asr.rawResult;
			speexEncodeTimeField.text = "Speex encode duration: " + asr.speexEncoder.encodeTime + " ms";
			speexEncodeEventsField.text = asr.speexEncoder.events;
		}
		
		public function stopRecording(e:MouseEvent):void {
			asr.stopRecord();
			recordButtonField.text = "Capture";
			recordButtonField.backgroundColor = 0xEBEBEB;
		}	
	}
	
}