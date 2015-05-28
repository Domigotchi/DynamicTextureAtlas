package de.domigotchi.stage3d.dynamicAtlas 
{
	import atf.Encoder;
	import atf.EncodingOptions;
	import de.domigotchi.stage3d.dynamicAtlas.factories.TextureFactory;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class TextureWrapper
	{
		private var _parent:TextureWrapper;
		private var _texture:TextureBase;
		
		private var _textureWidth:uint;
		private var _textureHeight:uint;
		private var _id:String;
		
		private var _uMultiplier:Number;
		private var _vMultiplier:Number;
		private var _uvMultiplier:Vector.<Number>;
		
		private var _uvRegion:Rectangle = new Rectangle();
		
		private var _isInUse:Boolean = false;
		private var _isAvailable:Boolean = false;
		
		static private var _helperPoint:Point = new Point();
		
		private var _uvChangeCounter:uint = 0;
		
		private var _textureFactory:TextureFactory;
		
		
		
		public function TextureWrapper(id:String, width:uint, height:uint, uMultiplier:Number = 1, vMultiplier:Number = 1) 
		{
			_id = id;
			_uvMultiplier = Vector.<Number>([uMultiplier, vMultiplier, 1,  1]);
			_textureWidth = width;
			_textureHeight = height;
		}
		
		internal function initWithTexture(texture:TextureBase, width:uint = 0, height:uint = 0):TextureWrapper
		{
			if (width)
				_textureWidth = width;
			if (height)
				_textureHeight = height;
				
			_texture = texture;
			_isAvailable = true;
			return this;
		}
		
		protected function initWithParent(parent:TextureWrapper):TextureWrapper
		{
			_parent = parent;
			_isAvailable = true;
			return this;
		}
		
		internal function initWithFactory(factory:TextureFactory):TextureWrapper
		{
			_isAvailable = false;
			_textureFactory = factory;
			return this;
		}
		
		public function get uvMultiplier():Vector.<Number> 
		{
			return _uvMultiplier;
		}
		[Inline]
		final public function get nativeTexture():TextureBase 
		{
			if (!_isInUse)
			{
				if(!_isAvailable && _textureFactory)
					_textureFactory.prepare();
				
				_isInUse = true;
			}
			return _parent ? _parent.nativeTexture : _texture;
		}
		
		public function get id():String 
		{
			return _id;
		}
		
		public function get width():uint 
		{
			return _textureWidth;
		}
		
		public function get height():uint 
		{
			return _textureHeight;
		}
		
		public function get parent():TextureWrapper 
		{
			return _parent;
		}
		
		public function get uvChangeCounter():uint 
		{
			return _uvChangeCounter;
		}
		
		public function get isAvailable():Boolean 
		{
			return _isAvailable;
		}
		
		public function getSubTexture(id:String, width:int, height:int):TextureWrapper 
		{
			return new TextureWrapper(id, width, height).initWithParent(this);
		}
		
		public static function createFromBitmapData(context3D:Context3D, id:String, bitmapData:BitmapData):TextureWrapper
		{
			var orginalWidth:uint = bitmapData.width;
			var orginalHeight:uint = bitmapData.height;
			var nextPowerOfTwoWidth:uint = getNextPowerOf2(bitmapData.width);
			var nextPowerOfTwoHeight:uint = getNextPowerOf2(bitmapData.height);
			if (bitmapData.width != nextPowerOfTwoWidth || bitmapData.height != nextPowerOfTwoHeight)
			{
				var newBitmapData:BitmapData = new BitmapData(nextPowerOfTwoWidth, nextPowerOfTwoHeight, true);
				newBitmapData.copyPixels(bitmapData, bitmapData.rect, _helperPoint);
				bitmapData = newBitmapData;
			}
			var texture:Texture = context3D.createTexture(nextPowerOfTwoWidth, nextPowerOfTwoHeight, Context3DTextureFormat.BGRA, false);
			texture.uploadFromBitmapData(bitmapData);
			return new TextureWrapper(id, orginalWidth, orginalHeight, orginalWidth/nextPowerOfTwoWidth, orginalHeight/nextPowerOfTwoHeight).initWithTexture(texture);
		}
		
		static public function createRenderTextureFromSize(context3D:Context3D, width:int, height:int):TextureWrapper 
		{
			var texture:TextureBase;
			try
			{
				texture = context3D.createRectangleTexture(width, height, Context3DTextureFormat.COMPRESSED_ALPHA, true);
			}
			catch (e:Error)
			{
				width = getNextPowerOf2(width);
				height = getNextPowerOf2(height);
				texture = context3D.createTexture(width, height, Context3DTextureFormat.COMPRESSED_ALPHA, true);
			}
			
			return new TextureWrapper("rendertexture", width, height).initWithTexture(texture);
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
		
		static public function createFromBitmapDataAsync(context3D:Context3D, id:String, bitmapData:BitmapData, onComplete:Function):TextureWrapper 
		{
			var orginalWidth:uint = bitmapData.width;
			var orginalHeight:uint = bitmapData.height;
			var nextPowerOfTwoWidth:uint = getNextPowerOf2(bitmapData.width);
			var nextPowerOfTwoHeight:uint = getNextPowerOf2(bitmapData.height);
			if (bitmapData.width != nextPowerOfTwoWidth || bitmapData.height != nextPowerOfTwoHeight)
			{
				var newBitmapData:BitmapData = new BitmapData(nextPowerOfTwoWidth, nextPowerOfTwoHeight, true);
				newBitmapData.copyPixels(bitmapData, bitmapData.rect, _helperPoint);
				bitmapData = newBitmapData;
			}
			var texture:Texture = context3D.createTexture(nextPowerOfTwoWidth, nextPowerOfTwoHeight, Context3DTextureFormat.BGRA, false);
			texture.addEventListener(Event.TEXTURE_READY, onComplete);
			var encodingOptions:EncodingOptions = new EncodingOptions();
			encodingOptions.quantization = 0;
			encodingOptions.mipmap = false;
			texture.uploadCompressedTextureFromByteArray(Encoder.encode(bitmapData, encodingOptions, null), 0, true);
			return new TextureWrapper(id, nextPowerOfTwoWidth, nextPowerOfTwoHeight).initWithTexture(texture);
		}
		
		static public function createFromTexByteArray(context3D:Context3D, id:String, bytes:ByteArray, onComplete:Function):TextureWrapper 
		{
			var nextPowerOfTwoWidth:uint = bytes.readInt();
			var nextPowerOfTwoHeight:uint = bytes.readInt();
			var orginalWidth:uint = bytes.readInt();
			var orginalHeight:uint = bytes.readInt();
			
			var texture:Texture = context3D.createTexture(nextPowerOfTwoWidth, nextPowerOfTwoHeight, Context3DTextureFormat.BGRA, false);
			texture.addEventListener(Event.TEXTURE_READY, onComplete);
			texture.uploadCompressedTextureFromByteArray(bytes, bytes.position, true);
			return new TextureWrapper(id, nextPowerOfTwoWidth, nextPowerOfTwoHeight, orginalWidth/nextPowerOfTwoWidth, orginalHeight/nextPowerOfTwoHeight).initWithTexture(texture);
		}
		
		public function getUVRegion():Rectangle 
		{
			return _uvRegion;
		}
		
		internal function setUVRegion(x:Number, y:Number, width:Number, height:Number):void 
		{
			_uvRegion.setTo(x, y, width, height);
			_uvChangeCounter++;
		}
	}

}