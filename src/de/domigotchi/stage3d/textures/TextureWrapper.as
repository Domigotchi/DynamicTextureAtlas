package de.domigotchi.stage3d.textures 
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class TextureWrapper
	{
		private var _texture:TextureBase;
		private var _textureWidth:uint;
		private var _textureHeight:uint;
		private var _id:String;
		
		private var _uMultiplier:Number;
		private var _vMultiplier:Number;
		private var _uvMultiplier:Vector.<Number>;
		
		static private var _helperPoint:Point = new Point();
		
		public function TextureWrapper(id:String) 
		{
			_id = id;
			
		}
		protected function init(texture:TextureBase, width:uint, height:uint, uMultiplier:Number = 1, vMultiplier:Number = 1):TextureWrapper
		{
			_uvMultiplier = Vector.<Number>([uMultiplier, vMultiplier, 1,  1]);
			_textureWidth = width;
			_textureHeight = height;
			_texture = texture;
			return this;
		}
		
		public function get uvMultiplier():Vector.<Number> 
		{
			return _uvMultiplier;
		}
		
		public function get nativeTexture():TextureBase 
		{
			return _texture;
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
			return new TextureWrapper(id).init(texture, orginalWidth, orginalHeight, orginalWidth/nextPowerOfTwoWidth, orginalHeight/nextPowerOfTwoHeight);
		}
		
		static public function createRenderTextureFromSize(context3D:Context3D, width:int, height:int):TextureWrapper 
		{
			var nextPowerOfTwoWidth:uint = getNextPowerOf2(width);
			var nextPowerOfTwoHeight:uint = getNextPowerOf2(height);
			var texture:Texture = context3D.createTexture(nextPowerOfTwoWidth, nextPowerOfTwoHeight, Context3DTextureFormat.BGRA, true);
			return new TextureWrapper("rendertexture").init(texture, nextPowerOfTwoWidth, nextPowerOfTwoHeight);
		}
		
		private static function getNextPowerOf2(n:uint):uint
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