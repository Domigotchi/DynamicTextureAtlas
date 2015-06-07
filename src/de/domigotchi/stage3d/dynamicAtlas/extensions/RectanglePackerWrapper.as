package de.domigotchi.stage3d.dynamicAtlas.extensions 
{
	import de.domigotchi.stage3d.dynamicAtlas.ITexturePacker;
	import de.domigotchi.stage3d.dynamicAtlas.TextureWrapper;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import org.villekoskela.utils.RectanglePacker;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class RectanglePackerWrapper implements ITexturePacker
	{
		private var _width:uint;
		private var _height:uint;
		private var _packer:RectanglePacker;
		private var _padding:uint;
		private var _count:uint = 0;
		
		private var _textureIndexMap:Dictionary = new Dictionary();
		private var _textureWrapperList:Vector.<TextureWrapper> = new Vector.<TextureWrapper>();
		
		public function RectanglePackerWrapper() 
		{
			
		}
		
		/* INTERFACE de.domigotchi.stage3d.dynamicAtlas.ITexturePacker */
		
		public function setSizes(width:uint, height:uint, padding:uint):void
		{
			_height = height;
			_width = width;
			_padding = padding;
			if (!_packer)
				_packer = new RectanglePacker(_width, _height, padding);
			else
				reset();
		}
		
		

		public function packTextures():Boolean 
		{
			var numPackedRects:uint = _packer.packRectangles(true);
			for (var i:int; i < numPackedRects; i++)
			{
				var textureWrapper:TextureWrapper = _textureWrapperList[i];
				var rect:Rectangle =  textureWrapper.getUVRegion();
				_packer.getRectangle(int(_textureIndexMap[textureWrapper.id]), rect);
				textureWrapper.setUVRegion(rect.x, rect.y, textureWrapper.width, textureWrapper.height);
				
			}
			return numPackedRects == _textureWrapperList.length;
		}
		
		/* INTERFACE de.domigotchi.stage3d.dynamicAtlas.ITexturePacker */
		
		public function insertTexture(textureWrapper:TextureWrapper):void 
		{
			var id:String = textureWrapper.id;
			if (_textureIndexMap[id] != null)
				return;
				
			_textureIndexMap[id] = _count = _textureWrapperList.length;
			_textureWrapperList[_count] = textureWrapper;
			_packer.insertRectangle(textureWrapper.width, textureWrapper.height, _count);
		}
		
		/* INTERFACE de.domigotchi.stage3d.dynamicAtlas.ITexturePacker */
		
		public function getPackedTextureSize(id:String):Rectangle 
		{
			return null;
		}

		public function reset():void
		{
			_packer.reset(_width, _height, _padding);
			for each(var textureWrapper:TextureWrapper in _textureWrapperList)
			{
				_packer.insertRectangle(textureWrapper.width, textureWrapper.height, _textureIndexMap[textureWrapper.id]);
			}
		}
		
	}

}