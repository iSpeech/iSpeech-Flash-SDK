package com.ispeech
{
	import flash.display.Bitmap;
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
	 */
	public class Main extends Sprite 
	{
		var instructions:Loader;
		var timer:Timer;
		var micActivityLevel:TextField;
		var field3:TextField;
		var asr:SpeechRecognizer;
				
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moved);
			stage.align = StageAlign.TOP_LEFT;
			
			loadLogo();
			
			timer = new Timer(100, 0);
			timer.addEventListener(TimerEvent.TIMER, timerEvent);
			timer.start();
			
			micActivityLevel = new TextField();
			micActivityLevel.type = flash.text.TextFieldType.INPUT;
			micActivityLevel.border = true;
			micActivityLevel.background = true;
			micActivityLevel.height = 20;
			micActivityLevel.width = 50;
			micActivityLevel.x = 220;
			micActivityLevel.y = 100;
			addChild(micActivityLevel);
			
			var micVolumeLabel:TextField;
			micVolumeLabel = new TextField();
			micVolumeLabel.background = true;
			micVolumeLabel.height = 20;
			micVolumeLabel.width = 120;
			micVolumeLabel.x = 100;
			micVolumeLabel.y = 100;
			micVolumeLabel.text = "Microphone Volume: ";
			addChild(micVolumeLabel);
			
			var recordLabel:TextField;
			recordLabel = new TextField();
			recordLabel.border = true;
			recordLabel.autoSize;
			recordLabel.background  = true;
			recordLabel.backgroundColor = 0xEBEBEB;
			recordLabel.height = 20;
			recordLabel.width = 50;
			recordLabel.x = 150;
			recordLabel.y = 150;
			recordLabel.text = "Record";
			recordLabel.addEventListener(MouseEvent.MOUSE_DOWN, record);
			recordLabel.addEventListener(MouseEvent.MOUSE_UP, stopRecord);
			addChild(recordLabel);
			
			if (Microphone.getMicrophone(0).muted == true){
				Security.showSettings(SecurityPanel.PRIVACY);
			}
			else
				ExternalInterface.call('log', 'security', 'allowed');
				
			if (Microphone.names.length == 0)
				ExternalInterface.call('log', 'error', 'microphone not found');
				
			ExternalInterface.addCallback("record", recordFromJavascript);
			ExternalInterface.addCallback("stopRecord", stopRecordFromJavascript);
			ExternalInterface.addCallback("setApiKey", setApiKeyFromJavascript);
			ExternalInterface.addCallback("setLanguage", setLanguageFromJavascript);
			ExternalInterface.addCallback("setFreeformMode", setFreeformModeFromJavascript);
			ExternalInterface.addCallback("addAlias", addAliasFromJavascript);
			ExternalInterface.addCallback("addCommand", addCommandFromJavascript);
			ExternalInterface.addCallback("clearAliasesAndCommands", clearFromJavascript);
			
			//ExternalInterface.addCallback("objectFromJS", objectFromJavascriptTest);
			
			ExternalInterface.call('isReady');
		}
		
		/*public function objectFromJavascriptTest(array:Array):void {
			ExternalInterface.call('log', array[0], 'occured');
		}*/
		
		public function loadLogo():void {
			var loader:Loader = new Loader;
			loader.load(new URLRequest("http://www.ispeech.org/images/ispeech-logo-dark.png"));
			addChild(loader);
			loader.x = 100;
			loader.y = 0;
		}

		public function loadSecurityInstructions():void {
			instructions = new Loader;
			instructions.load(new URLRequest("http://www.ispeech.org/temp/asr-flash-next-step.png"));
			addChild(instructions);
			instructions.x = 15;
			instructions.y = 225;
		}
		
		public function removeSecurityInstructions():void {
			ExternalInterface.call('log', 'security_instructions', 'ocurred');
			instructions.x = -1000;
		}

		public function moved(e:Event):void {
			ExternalInterface.call('log', 'mouse_moved_event', 'occured');
			
			if (Microphone.getMicrophone(0).muted == true){
				Security.showSettings(SecurityPanel.PRIVACY);
				loadSecurityInstructions();
				ExternalInterface.call('log', 'security', 'denied');
			}
			else {
				ExternalInterface.call('log', 'security', 'allowed');
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, moved);
				removeSecurityInstructions();
			}
		}
		
		public function timerEvent(e:Event):void {
			var m:Microphone = Microphone.getMicrophone(0);
			micActivityLevel.text = m.activityLevel.toString();
		}
		
		public function recordFromJavascript():void {
			ExternalInterface.call('log', 'started_recording', 'occured');
			asr.setFreeForm(3);
			asr.addEventListener(DataGetEvent.ENCODE, onServerResponse);
			asr.startRecordWithoutStream(20000, 0);
		}
		
		public function setApiKeyFromJavascript(apikey:String) {
			asr = new SpeechRecognizer(apikey, true);
			//var commands:Array = new Array('yes','no');
			//s.addCommands(commands);
			
			//var names:Array = new Array("jane", "bob", "john");
		    //s.addAlias("NAMES", names);
		    //s.addCommand("call %NAMES%");
			//s.setLanguage("en-US");
			
			ExternalInterface.call('log', 'api_key_set', apikey);
		}
		
		public function addAliasFromJavascript(alias:String, aliasArray:Array) {
			asr.addAlias(alias, aliasArray);
			ExternalInterface.call('log', 'alias_list_added', alias + "=" + aliasArray);
		}
		
		public function addCommandFromJavascript(command:String) {
			asr.addCommand(command);
			ExternalInterface.call('log', 'command_added', command);
		}
		
		public function checkMicrophoneFromJavascript():String {
			return Microphone.getMicrophone(0).muted.toString();
		}
		
		public function stopRecordFromJavascript():void {
			ExternalInterface.call('log', 'stopped_recording', 'occured');
			asr.stopRecord();
		}
		
		public function setFreeformModeFromJavascript(num:Number):void {
			asr.setFreeForm(num);
			ExternalInterface.call('log', 'freeform_mode_set_to', num);
		}
		
		public function setLanguageFromJavascript(language:String):void {
			asr.setLanguage(language);
			ExternalInterface.call('log', 'language_set_to', language);
		}
		
		public function clearFromJavascript():void {
			asr.clear();
			ExternalInterface.call('log', 'commands_and_alises_cleared', "occured");
		}
		
		public function record(e:MouseEvent):void {
			ExternalInterface.call('log', 'started_recording', 'occured');
			asr.addEventListener(DataGetEvent.ENCODE, onServerResponse);
			asr.startRecordWithoutStream(20000, 0);
		}
		
		public function stopRecord(e:MouseEvent):void {
			ExternalInterface.call('log', 'stopped_recording', 'occured');
			asr.stopRecord();
		}
		
		private function onServerResponse(e:DataGetEvent):void {
			ExternalInterface.call('log', 'speech_result', e.data);
			ExternalInterface.call('log', 'speech_result_confidence', e.confidence);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
		}
		
	}
	
}