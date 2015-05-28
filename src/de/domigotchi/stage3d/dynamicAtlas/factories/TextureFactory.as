package de.domigotchi.stage3d.dynamicAtlas.factories 
{
	import de.domigotchi.stage3d.dynamicAtlas.TextureWrapper;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Stage3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class TextureFactory 
	{
		
		public static const FORMAT_IMAGE:uint = 0;
		public static const FORMAT_TEX:uint = 1;
		
		private var _id:String;
		private var _path:String;
		private var _urlRequest:URLRequest;
		private var _stage3D:Stage3D;
		
		private var _onCompleteCallbacks:Vector.<Function> = new Vector.<Function>();
		private var _textureWrapper:TextureWrapper;
		
		static private var _helperPoint:Point = new Point();
		private var _isPreparing:Boolean = false;
		private var _async:Boolean = true;
		
		private var _fileStream:FileStream = new FileStream();
		private var _urlLoader:URLLoader = new URLLoader();
		private var _file:File;
		private var _format:uint;
		
		public function TextureFactory(id:String, format:uint, path:String, stage3D:Stage3D) 
		{
			_format = format;
			_stage3D = stage3D;
			_path = path;
			_urlRequest = new URLRequest(path)
			_id = id;
		}
		
		public function addOnCompleteCallback(callback:Function):void
		{
			if (callback.length != 1)
				throw new Error("requires parameter of type TextureFactory");
			if(_onCompleteCallbacks.indexOf(callback) == -1)
				_onCompleteCallbacks[_onCompleteCallbacks.length] = callback;
		}
		
		public function removeOnCompleteCallback(callback:Function):void
		{
			var currentIndex:int = _onCompleteCallbacks.indexOf(callback);
			if(currentIndex != -1)
				_onCompleteCallbacks.splice(currentIndex, 1);
		}
		
		public function prepare():void 
		{
			if (!_isPreparing)
			{
				_isPreparing = true;
				if(_format == FORMAT_IMAGE)
					loadImageFileAsync(_path);
				if (_format == FORMAT_TEX)
					loadFileAsnc2(_path);
			}
		}
		
		private function loadFileAsnc2(path:String):void 
		{
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_urlLoader.addEventListener(Event.COMPLETE, onTexComplete2);
			_urlLoader.load(new URLRequest(path))
			
		}
		
		private function onTexComplete2(e:Event):void 
		{
			var bytes:ByteArray = _urlLoader.data as ByteArray;
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.position = 0;
			_textureWrapper = TextureWrapper.createFromTexByteArray(_stage3D.context3D, _id, bytes, onUploadComplete);
		}
		
		private function loadFileAsnc(path:String):void 
		{
			_fileStream.addEventListener(Event.COMPLETE, onTexComplete);
			_fileStream.openAsync(_file, FileMode.READ);
		}
		
		private function onTexComplete(e:Event):void 
		{
			var bytes:ByteArray = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			_fileStream.readBytes(bytes);
			_fileStream.close();
			bytes.position = 0;
			_textureWrapper = TextureWrapper.createFromTexByteArray(_stage3D.context3D, _id, bytes, onUploadComplete);
		}
		
		private function loadImageFileAsync(path:String):void 
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
			loader.load(_urlRequest);
		}
		
		private function onComplete(e:Event):void 
		{
			var bitmapData:BitmapData = ((e.target as LoaderInfo).content as Bitmap).bitmapData;
			if (!_async)
			{
				_textureWrapper = TextureWrapper.createFromBitmapData(_stage3D.context3D, _id, bitmapData);
				onUploadComplete(null);
			}
			else
			{
				_textureWrapper = TextureWrapper.createFromBitmapDataAsync(_stage3D.context3D, _id, bitmapData, onUploadComplete);
			}
			
		}
		
		private function onUploadComplete(e:Event):void 
		{
			_isPreparing = false;
			for (var i:int; i < _onCompleteCallbacks.length; i++)
			{
				_onCompleteCallbacks[i](this);
			}
		}
		
		
		public function get id():String 
		{
			return _id;
		}
		
		public function get width():int 
		{
			return 128;
		}
		
		public function get height():int 
		{
			return 128;
		}
		
		public function get textureWrapper():TextureWrapper 
		{
			return _textureWrapper;
		}
		
	}

}