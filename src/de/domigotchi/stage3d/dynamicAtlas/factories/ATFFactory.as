package de.domigotchi.stage3d.dynamicAtlas.factories 
{
	import atf.Encoder;
	import atf.EncodingOptions;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class ATFFactory 
	{
		private var _bytes:ByteArray = new ByteArray();
		private var _onComplete:Function;
		private var _outFile:File;
		private var _inFile:File;
		private var _fileStream:FileStream;
		
		private var _isFileStreamOpened:Boolean = false;
		private var _isImageLoaded:Boolean = false;
		private var _bitmapData:BitmapData;
		private var _encodingOptions:EncodingOptions;
		
		public function ATFFactory(inFile:File, outFile:File, encodingOptions:EncodingOptions, onComplete:Function) 
		{
			_encodingOptions = encodingOptions;
			_fileStream = new FileStream();
			_inFile = inFile;
			_outFile = outFile;
			_onComplete = onComplete;
			_bytes.endian = Endian.LITTLE_ENDIAN;
			load();
		}
		
		public function load():void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadingComplete);
			loader.load(new URLRequest(_inFile.url));
			
			
		}
		

		private function onLoadingComplete(e:Event):void 
		{
			_isImageLoaded = true;
			_bitmapData = ((e.target as LoaderInfo).content as Bitmap).bitmapData;
			encode();
		}
		

		private function encode():void
		{
			_fileStream.open(_outFile, FileMode.WRITE);
			Encoder.encode(_bitmapData, _encodingOptions, _bytes);
			_fileStream.writeBytes(_bytes);
			_fileStream.close();
			_onComplete(this);
		}
		
	}

}