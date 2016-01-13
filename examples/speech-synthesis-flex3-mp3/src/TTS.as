package  
{
	/**
	 * ...
	 * @author iSpeech, Inc.
	 * @see http://www.ispeech.org/developers
	 */
	 
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.HSlider;
	import mx.controls.Image;
	import mx.controls.Label;
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
	import flash.display.MovieClip;
	import mx.controls.Text;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.collections.ArrayCollection;
	import flash.media.SoundMixer;
	import mx.controls.VSlider;
	import flash.net.navigateToURL;
	import flash.net.URLLoaderDataFormat;
	import flash.external.ExternalInterface;
	
	public class TTS extends Canvas
	{
		var recordToFile:Boolean = false;
		var timer:Timer;
		var mic:Microphone;
		var sock:Socket;
		var str:String;
		
		var apikeyLabel:Label;
		var apikeyTextInput:TextInput;
		var voiceLabel:Label;
		var voiceDropDown:ComboBox;
		var speedLabel:Label;
		var speedSlider:HSlider;
		var pitchLabel:Label;
		var pitchSlider:HSlider;
		var convertButton:Button;
		var downloadButton:Button;
		var textLabel:Label;
		var textArea:TextArea;
		var eventLogLabel:Label;
		var eventLog:TextArea;
		
		var volumeField:Label;
		var socketConnectedField:Label;
		var bytesWrittenField:Label;
		var currentActionField:Label;
		var speechRecognitionResultField:Label;
		var parsedResultField:Label;
		var recordButtonField:Button;
		var conversionTimeField:Label;
		var snd:Sound;
		var keyProperties:XMLList;
		var keyPropertyGrid:DataGrid;
		var keyPropertiesLabel:Label;
		var updateKeyButton:Button;
		var logoLoader:Loader;
		
		public function TTS() 
		{
			var y:int = 0;
			
			apikeyLabel = new Label();
			apikeyLabel.x = 0;
			apikeyLabel.y = y;
			apikeyLabel.text = "API Key: ";
			apikeyLabel.visible = true;
			addChild(apikeyLabel);
			
			apikeyTextInput = new TextInput();
			apikeyTextInput.x = 100;
			apikeyTextInput.y = y;
			apikeyTextInput.width = 410;
			apikeyTextInput.text = "developerdemokeydeveloperdemokey";
			apikeyTextInput.addEventListener(FocusEvent.FOCUS_OUT, getInformation);
			addChild(apikeyTextInput);
			
			updateKeyButton = new Button();
			updateKeyButton.x = 530;
			updateKeyButton.y = y;
			updateKeyButton.label = "Update";
			updateKeyButton.addEventListener(MouseEvent.CLICK, getInformation);
			addChild(updateKeyButton);
			
			y += 50;
			
			voiceLabel = new Label();
			voiceLabel.x = 0;
			voiceLabel.y = y;
			voiceLabel.text = "Voice: ";
			voiceLabel.visible = true;
			addChild(voiceLabel);
			
			voiceDropDown = new ComboBox();
			var array:ArrayCollection = new ArrayCollection([ { label:"usenglishfemale" } ]);
			voiceDropDown.dataProvider = array;
			voiceDropDown.x = 100;
			voiceDropDown.y = y;
			addChild(voiceDropDown);
			
			y += 50;
			speedLabel = new Label();
			speedLabel.x = 0;
			speedLabel.y = y;
			speedLabel.text = "Speed: ";
			speedLabel.visible = true;
			addChild(speedLabel);
			
			speedSlider = new HSlider();
			speedSlider.minimum = -10;
			speedSlider.maximum = 10;
			speedSlider.value = 0;
			//speedSlider.tickInterval = 1;
			speedSlider.snapInterval = 1;
			addChild(speedSlider);
			speedSlider.x = 100;
			speedSlider.y = y;
			speedSlider.width = 500;
			speedSlider.labels = [ 'slow', 'regular', 'fast'];
			
			y += 50;
			pitchLabel = new Label();
			pitchLabel.x = 0;
			pitchLabel.y = y;
			pitchLabel.text = "Pitch: ";
			pitchLabel.visible = true;
			addChild(pitchLabel);
			
			pitchSlider = new HSlider();
			pitchSlider.minimum = 0;
			pitchSlider.maximum = 200;
			pitchSlider.value = 100;
			//pitchSlider.tickInterval = 1;
			pitchSlider.snapInterval = 1;
			addChild(pitchSlider);
			pitchSlider.x = 100;
			pitchSlider.y = y;
			pitchSlider.width = 500;
			
			pitchSlider.labels = [ 'low', 'regular', 'high'];
			
			y += 70;
			textLabel = new Label();
			textLabel.x = 0;
			textLabel.y = y;
			textLabel.text = "Text: ";
			textLabel.visible = true;
			addChild(textLabel);
			
			textArea = new TextArea();
			textArea.x = 100;
			textArea.y = y;
			textArea.width = 500;
			textArea.height = 60;
			textArea.htmlText = "Hello World";
			addChild(textArea);
			
			y += 70;
			eventLogLabel = new Label();
			eventLogLabel.x = 0;
			eventLogLabel.y = y;
			eventLogLabel.text = "Error Log: ";
			eventLogLabel.visible = true;
			addChild(eventLogLabel);
			
			eventLog = new TextArea();
			eventLog.x = 100;
			eventLog.y = y;
			eventLog.width = 500;
			eventLog.height = 60;
			addChild(eventLog);
			
			y += 80;
			keyPropertiesLabel = new Label();
			keyPropertiesLabel.x = 0;
			keyPropertiesLabel.y = y;
			keyPropertiesLabel.text = "Key Properties: ";
			keyPropertiesLabel.visible = true;
			addChild(keyPropertiesLabel);
			
			keyPropertyGrid = new DataGrid();
			keyPropertyGrid.x = 100;
			keyPropertyGrid.y = y;
			
			var columnOne:DataGridColumn;
			columnOne = new DataGridColumn(); 
			columnOne.headerText = 'Property';
			columnOne.dataField = "Property";
			columnOne.width = 150;
			
			var columnTwo:DataGridColumn;
			columnTwo = new DataGridColumn(); 
			columnTwo.headerText = 'Value';  
			columnTwo.dataField = "Value";
			columnTwo.width = 350;
			
			var cols:Array = new Array;
			cols.push(columnOne); 
			cols.push(columnTwo); 
			keyPropertyGrid.columns = cols;
			addChild(keyPropertyGrid);
		
			y += 200;
			convertButton = new Button();
			convertButton.label = "Play";
			convertButton.x = 100;
			convertButton.y = y;
			convertButton.addEventListener(MouseEvent.CLICK, convert);
			addChild(convertButton);
			
			downloadButton = new Button();
			downloadButton.label = "Download";
			downloadButton.x = 180;
			downloadButton.y = y;
			downloadButton.addEventListener(MouseEvent.CLICK, download);
			addChild(downloadButton);
			
			var logo:Image = new Image();
			logo.width = 75;
			logo.x = 520;
			logo.y = y-8;
			logo.addEventListener(MouseEvent.CLICK, openWebsite);
			logo.source = "http://www.ispeech.org/images/logo.png";
			addChild(logo);
			
			getInformation();
		}
		
		public function openWebsite(e:MouseEvent) {
			navigateToURL(new URLRequest("http://www.ispeech.org"), "_blank");
		}
		
		public function makeURL():String {
			var string:String = new String();
			string = "http://api.ispeech.org/api/rest?action=convert&apikey=" + apikeyTextInput.text + "&voice=" + voiceDropDown.selectedLabel + "&speed=" + speedSlider.value + "&pitch=" + pitchSlider.value + "&text=" + unescape(textArea.text);
			return string;
		}
		
		public function getInformation(event:Object=null):void {
			var url:String = "http://api.ispeech.org/api/rest?action=information&apikey="+apikeyTextInput.text+"&output=rest";
			//trace(url);
			var urlRequest:URLRequest = new URLRequest(url);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, parseInformation);
			urlLoader.load(urlRequest);
		}
		
		public function parseInformation(e:Event):void {
			
			var regex:RegExp = /voice-[0-9]+/;
			var parameter:String;
			
			var array1:Array = new Array();
			var array2:Array = new Array();
			
			var urlVariables:URLVariables = new URLVariables(e.target.data);
			for (parameter in urlVariables) {
				if (regex.test(parameter))
					array1.push(urlVariables[parameter]);
				
				array2.push({Property:parameter, Value:urlVariables[parameter]});
			}		
			array1.sort();
			array2.sortOn("Property");
			var newArrayCollection:ArrayCollection = new ArrayCollection();
			newArrayCollection.source = array1;
			voiceDropDown.dataProvider = newArrayCollection;
			if (array1.indexOf("usenglishfemale") != -1)
				voiceDropDown.selectedIndex = array1.indexOf("usenglishfemale");
			
			keyPropertyGrid.dataProvider = array2;
		}
		
		public function convert(e:MouseEvent):void
		{
			eventLog.text = "";
			var url:String = makeURL();
			var urlRequest:URLRequest = new URLRequest(url);
			var urlLoader:URLLoader = new URLLoader();
			
			urlLoader.addEventListener(Event.COMPLETE, onComp);
			urlLoader.load(urlRequest);
			
			SoundMixer.stopAll();
			snd = new Sound();
			snd.load(urlRequest);
			snd.play();
		}
		
		public function download(e:MouseEvent):void {
			eventLog.text = "";
			
			var url:String = makeURL();
			var request:URLRequest = new URLRequest(url);
			var fileRef:FileReference = new FileReference();
			fileRef.download(request, "ispeech.mp3");
		}
		
		public function onComp(e:Event):void {
			var result:String = null;
			try {
				var vars:URLVariables = new URLVariables(e.target.data);
				result = "Error Code " + vars.code + ": " + vars.message;
			}
			catch (e:Error) {}
			if (result != null)
				showEvent(result);
		}
		
		public function showEvent(s:String):void {
			eventLog.text = s + "\n" + eventLog.text;
		}
	}
}