package de.domigotchi.stage3d.dynamicAtlas.extensions 
{
	import de.domigotchi.stage3d.dynamicAtlas.TextureWrapper;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import starling.textures.ConcreteTexture;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class StarlingTextureWrapper extends SubTexture
	{
		private var _textureWrapper:TextureWrapper;
		private var _isUVDataDirty:Boolean = false;
		
		private var _uvChangeCounter:uint = 0;
		private var _uvRegion:Rectangle;
		
		public function StarlingTextureWrapper(textureWrapper:TextureWrapper) 
		{
			_textureWrapper = textureWrapper;
			var texture:ConcreteTexture = new ConcreteTexture(null, Context3DTextureFormat.BGRA, textureWrapper.parent.width, textureWrapper.parent.height, false, false);
			_uvRegion = _textureWrapper.getUVRegion();
			super(texture, _uvRegion);
		}
		
		override public function get region():Rectangle
		{
			return _uvRegion;
		}
		
		override public function get width():Number 
		{
			return _textureWrapper.width;
		}
		
		override public function get height():Number 
		{
			return _textureWrapper.height;
		}
		
		override public function get transformationMatrix():Matrix 
		{
			
			return super.transformationMatrix;
		}
		
		[Inline]
		final override public function get base():TextureBase 
		{
			if (_textureWrapper.uvChangeCounter != _uvChangeCounter)
			{
				
				transformationMatrix.identity();
				transformationMatrix.scale(_uvRegion.width  / _textureWrapper.parent.width,
											_uvRegion.height / _textureWrapper.parent.height);
				transformationMatrix.translate(_uvRegion.x  / _textureWrapper.parent.width,
				_uvRegion.y  / _textureWrapper.parent.height); 
				
				super.region.setTo(_uvRegion.x, _uvRegion.y, _uvRegion.width, _uvRegion.height);
				_uvChangeCounter = _textureWrapper.uvChangeCounter;
				mIsRegionDirty = true;
			
			}
			return _textureWrapper.nativeTexture;
		}
	}

}