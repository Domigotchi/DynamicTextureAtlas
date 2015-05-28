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
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class TexFileFactory 
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
		private var _helperPoint:Point = new Point();
		
		public function TexFileFactory(inFile:File, outFile:File, onComplete:Function) 
		{
			_fileStream = new FileStream();
			_inFile = inFile;
			_outFile = outFile;
			_onComplete = onComplete;
			_bytes.endian = Endian.LITTLE_ENDIAN;
			if (outFile.exists)
				_onComplete(this);
			else
				load();
		}
		
		public function load():void
		{
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadingComplete);
			loader.load(new URLRequest(_inFile.url), loaderContext);
		}
		

		private function onLoadingComplete(e:Event):void 
		{
			_isImageLoaded = true;
			_bitmapData = ((e.target as LoaderInfo).content as Bitmap).bitmapData;
			encode();
		}
		

		private function encode():void
		{
			var orginalWidth:uint = _bitmapData.width;
			var orginalHeight:uint = _bitmapData.height;
			var nextPowerOfTwoWidth:uint = getNextPowerOf2(_bitmapData.width);
			var nextPowerOfTwoHeight:uint = getNextPowerOf2(_bitmapData.height);
			if (_bitmapData.width != nextPowerOfTwoWidth || _bitmapData.height != nextPowerOfTwoHeight)
			{
				var newBitmapData:BitmapData = new BitmapData(nextPowerOfTwoWidth, nextPowerOfTwoHeight, _bitmapData.transparent);
				newBitmapData.copyPixels(_bitmapData, _bitmapData.rect, _helperPoint);
				_bitmapData = newBitmapData;
			}
			_fileStream.endian = Endian.LITTLE_ENDIAN;
			_fileStream.open(_outFile, FileMode.WRITE);
			_fileStream.writeInt(_bitmapData.width);
			_fileStream.writeInt(_bitmapData.height);
			_fileStream.writeInt(orginalWidth);
			_fileStream.writeInt(orginalHeight);
			_fileStream.writeBytes(Encoder.encode(_bitmapData, new EncodingOptions(), null));
			_fileStream.close();
			_onComplete(this);
		}
		
		public static function getNextPowerOf2(n:uint):uint
		{
			var count:uint = 0;
 
			/* First n in the below condition is for the case where n is 0*/
			if (n && !(n&(n-1)))
				return n;
			 
			while( n != 0)
			{
				n  >>= 1;
				count += 1;
			}
			 
			return 1<<count;
		}
		
	}

}