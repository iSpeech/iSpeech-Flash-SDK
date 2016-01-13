package com.ispeech
{
	import flash.display.Bitmap;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.media.Microphone;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.display.StageAlign;
	
	/**
	 * ...
	 * @author iSpeech, Inc.
	 * @see http://www.ispeech.org/developers
	 */
	public class Main extends Sprite 
	{
		var redrawTimer:Timer;
		var micActivityLevel:TextField;
		var captureResult:TextField;
		var asr:SpeechRecognizer;
		var resultLabel:TextField;
		var eventLog:TextField;
				
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moved);
			stage.align = StageAlign.TOP_LEFT;
			
			loadLogo();
			
			redrawTimer = new Timer(50, 0);
			redrawTimer.addEventListener(TimerEvent.TIMER, timerEvent);
			redrawTimer.start();
			
			var offset:int = 125;
			
			micActivityLevel = new TextField();
			micActivityLevel.type = flash.text.TextFieldType.INPUT;
			micActivityLevel.border = true;
			micActivityLevel.background = true;
			micActivityLevel.height = 20;
			micActivityLevel.width = 50;
			micActivityLevel.x = 220;
			micActivityLevel.y = 100+offset;
			addChild(micActivityLevel);
			
			var micVolumeLabel:TextField;
			micVolumeLabel = new TextField();
			micVolumeLabel.background = true;
			micVolumeLabel.height = 20;
			micVolumeLabel.width = 120;
			micVolumeLabel.x = 100;
			micVolumeLabel.y = 100+offset;
			micVolumeLabel.text = "Microphone Volume: ";
			addChild(micVolumeLabel);
			
			var captureButton:TextField;
			captureButton = new TextField();
			captureButton.border = true;
			captureButton.autoSize;
			captureButton.background  = true;
			captureButton.backgroundColor = 0xEBEBEB;
			captureButton.height = 20;
			captureButton.width = 50;
			captureButton.x = 150;
			captureButton.y = 230+offset;
			captureButton.text = "Capture";
			captureButton.addEventListener(MouseEvent.MOUSE_DOWN, record);
			captureButton.addEventListener(MouseEvent.MOUSE_UP, stopRecord);
			addChild(captureButton);
			
			captureResult = new TextField();
			captureResult.background = true;
			captureResult.height = 20;
			captureResult.width = 250;
			captureResult.border = true;
			captureResult.x = 50;
			captureResult.y = 150+offset;
			captureResult.text = "Text";
			addChild(captureResult);
			
			eventLog = new TextField();
			eventLog.background = true;
			eventLog.height = 20;
			eventLog.width = 250;
			eventLog.border = true;
			eventLog.x = 50;
			eventLog.y = 180+offset;
			eventLog.text = "Log";
			addChild(eventLog);
			
			if (Microphone.getMicrophone(0).muted == true)
				Security.showSettings(SecurityPanel.PRIVACY);
				
			if (Microphone.names.length == 0)
				eventLog.text = "No microphones detected";
				
			setApiKey('developerdemokeydeveloperdemokey');
			setFreeformMode(3);
			setLanguage("en-US");
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
		}
		
		public function loadLogo():void
		{
			var loader:Loader = new Loader;
			loader.load(new URLRequest("http://www.ispeech.org/images/logo.png"));
			addChild(loader);
			loader.x = 0;
			loader.y = 0;
		}

		public function moved(e:Event):void
		{
			
			if (Microphone.getMicrophone(0).muted == true)			
				Security.showSettings(SecurityPanel.PRIVACY);
			
			else 
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, moved);
		}
		
		public function timerEvent(e:Event):void
		{
			var m:Microphone = Microphone.getMicrophone(0);
			micActivityLevel.text = m.activityLevel.toString();
		}
		
		public function setApiKey(apikey:String):void
		{
			asr = new SpeechRecognizer(apikey, true);
			//var commands:Array = new Array('yes','no');
			//s.addCommands(commands);
			
			//var names:Array = new Array("jane", "bob", "john");
		    //s.addAlias("NAMES", names);
		    //s.addCommand("call %NAMES%");
			//s.setLanguage("en-US");
			eventLog.text = "API key set to: " + apikey;
		}
		
		public function addAlias(alias:String, aliasArray:Array):void
		{
			asr.addAlias(alias, aliasArray);
			eventLog.text = "Alias added: " + alias + ", " + aliasArray;
		}
		
		public function addCommand(command:String):void
		{
			asr.addCommand(command);
			eventLog.text = "Command added: " + command;
		}
		
		public function checkMicrophone():String
		{
			return Microphone.getMicrophone(0).muted.toString();
		}
		
		public function setFreeformMode(num:Number):void
		{
			asr.setFreeForm(num);
			eventLog.text = "Freeform mode set to: " + num;
		}
		
		public function setLanguage(language:String):void
		{
			asr.setLanguage(language);
			eventLog.text = "Language set to: " + language;
		}
		
		public function clear():void
		{
			asr.clear();
			eventLog.text = "Aliases and commands cleared";
		}
		
		public function record(e:MouseEvent):void
		{
			asr.addEventListener(DataGetEvent.ENCODE, onServerResponse);
			asr.startRecordWithoutStream(20000, 0);
			eventLog.text = "Recording started";
		}
		
		public function stopRecord(e:MouseEvent):void
		{
			asr.stopRecord();
			eventLog.text = "Recording stopped";
		}
		
		private function onServerResponse(e:DataGetEvent):void
		{
			eventLog.text = "Server responded";
			captureResult.text = "Result: " + e.data + ", Confidence: " + e.confidence;
		}
		
	}
	
}