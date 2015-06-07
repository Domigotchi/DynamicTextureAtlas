package de.domigotchi.stage3d.dynamicAtlas 
{
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public interface ITexturePacker 
	{
		function setSizes(width:uint, height:uint, padding:uint):void;
		function insertTexture(textureWrapper:TextureWrapper):void;
		function getPackedTextureSize(id:String):Rectangle;
		function packTextures():Boolean;
		
		function reset():void;
	}
	
}