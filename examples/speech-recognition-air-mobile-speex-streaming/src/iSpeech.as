package 
{
	import flash.events.Event;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.media.Microphone;
	import flash.events.*;
	import flash.text.TextField;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	
	/**
	 * ...
	 * @author iSpeech, Inc.
	 * @see http://www.ispeech.org/developers
	 */
	public class iSpeech extends Canvas 
	{
		var redrawTimer:Timer;
		var micVolume:Label;
		var asr:SpeechRecognizer;
		var micVolumeLabel:Label;
		var eventLog:Label;
		var recognizedText:Label;
				
		public function iSpeech() 
		{
			
			if (Microphone.getMicrophone(0).muted == true)
				Security.showSettings(SecurityPanel.PRIVACY);
				
			if (Microphone.names.length == 0)
				trace('No microphones found');
			
			redrawTimer = new Timer(50, 0);
			redrawTimer.addEventListener(TimerEvent.TIMER, timerEvent);
			redrawTimer.start();

			var micVolumeLabel:Label;
			micVolumeLabel = new Label();
			micVolumeLabel.height = 20;
			micVolumeLabel.width = 120;
			micVolumeLabel.x = 100;
			micVolumeLabel.y = 100;
			micVolumeLabel.text = "Microphone Volume: ";
			addChild(micVolumeLabel);
			
			micVolume = new Label();
			micVolume.height = 20;
			micVolume.width = 50;
			micVolume.x = 220;
			micVolume.y = 100;
			addChild(micVolume);
			
			var recordButton:Button;
			recordButton = new Button();
			recordButton.height = 20;
			recordButton.width = 100;
			recordButton.x = 150;
			recordButton.y = 150;
			recordButton.label = "Capture";
			recordButton.addEventListener(MouseEvent.MOUSE_DOWN, record);
			recordButton.addEventListener(MouseEvent.MOUSE_UP, stopRecord);
			addChild(recordButton);
			
			recognizedText = new Label();
			recognizedText.height = 20;
			recognizedText.width = 250;
			recognizedText.x = 50;
			recognizedText.y = 200;
			recognizedText.text = "Text";
			addChild(recognizedText);
			
			eventLog = new Label();
			eventLog.height = 20;
			eventLog.width = 250;
			eventLog.x = 50;
			eventLog.y = 230;
			eventLog.text = "Log";
			addChild(eventLog);
			
			setApiKey('developerdemokeydeveloperdemokey');
			setFreeformMode(3);
			setLanguage("en-US");
		}

		public function moved(e:Event):void {
			
			if (Microphone.getMicrophone(0).muted == true){				
				Security.showSettings(SecurityPanel.PRIVACY);
			}
			else {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, moved);
			}
		}
		
		public function timerEvent(e:Event):void {
			var mic:Microphone = Microphone.getMicrophone(0);
			micVolume.text = mic.activityLevel.toString();
		}
		
		public function setApiKey(apikey:String) {
			asr = new SpeechRecognizer(apikey, true);
			//var commands:Array = new Array('yes','no');
			//asr.addCommands(commands);
			
			//var names:Array = new Array("jane", "bob", "john");
		    //asr.addAlias("NAMES", names);
		    //asr.addCommand("call %NAMES%");
			//asr.setLanguage("en-US");
			eventLog.text = "API key set to: " + apikey;
		}
		
		public function addAlias(alias:String, aliasArray:Array) {
			asr.addAlias(alias, aliasArray);
			eventLog.text = "Alias added: " + alias + ", " + aliasArray;
		}
		
		public function addCommand(command:String) {
			asr.addCommand(command);
			eventLog.text = "Command added: " + command;
		}
		
		public function checkMicrophone():String {
			return Microphone.getMicrophone(0).muted.toString();
		}
		
		public function setFreeformMode(num:Number):void {
			asr.setFreeForm(num);
			eventLog.text = "Freeform mode set to: " + num;
		}
		
		public function setLanguage(language:String):void {
			asr.setLanguage(language);
			eventLog.text = "Language set to: " + language;
		}
		
		public function clear():void {
			asr.clear();
			eventLog.text = "Aliases and commands cleared";
		}
		
		public function record(e:MouseEvent):void {
			asr.addEventListener(DataGetEvent.ENCODE, onServerResponse);
			asr.startRecordAndNotify(10000); //Stream audio
			//asr.startRecordWithoutStream(10000); //Don't stream audio
			eventLog.text = "Capturing started";
		}
		
		public function stopRecord(e:MouseEvent):void {
			asr.stopRecord();
			eventLog.text = "Capturing stopped";
		}
		
		private function onServerResponse(e:DataGetEvent):void {
			eventLog.text = "Server responded";
			recognizedText.text = "Result: " + e.data + ", Confidence: " + e.confidence;
		}
	}
	
}