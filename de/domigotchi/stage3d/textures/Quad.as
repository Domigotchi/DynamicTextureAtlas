package de.domigotchi.stage3d.textures 
{
	import flash.sampler.getSize;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class Quad 
	{
		public static const DATA_32_PER_VERTEX:uint = 4;
		public static const NUM_VERTICES:uint = 4;
		public static const NUM_INDICES:uint = 6;
		
		
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _width:Number = 0;
		private var _height:Number = 0;
		
		public function Quad() 
		{
			
		}
		
		public function init(x:Number, y:Number, width:Number, height:Number):Quad
		{
			_height = height;
			_width = width;
			_y = y;
			_x = x;
			return this;
		}
		
		public function fillBytes(vertexBytes:ByteArray, indexBytes:ByteArray):void
		{
			
			if (vertexBytes.endian != Endian.LITTLE_ENDIAN)
				vertexBytes.endian = Endian.LITTLE_ENDIAN;
				
			if (indexBytes.endian != Endian.LITTLE_ENDIAN)
				indexBytes.endian = Endian.LITTLE_ENDIAN;
			
			var currentQuadOffset:int = (indexBytes.position / 12) * 4;	
			var normalizedX:Number = (_x * 2) - 1;
			var normalizedY:Number = -((_y * 2) - 1);
			//Vertex 1
			//pos
			vertexBytes.writeFloat(normalizedX);
			vertexBytes.writeFloat(normalizedY);
			//uv
			vertexBytes.writeFloat(0);
			vertexBytes.writeFloat(0);
			
			//Vertex 2
			//pos
			vertexBytes.writeFloat(normalizedX);
			vertexBytes.writeFloat(normalizedY - _height * 2);
			//uv
			vertexBytes.writeFloat(0);
			vertexBytes.writeFloat(1);
			
			//Vertex 3
			//pos
			vertexBytes.writeFloat(normalizedX + _width * 2);
			vertexBytes.writeFloat(normalizedY - _height * 2);
			//uv
			vertexBytes.writeFloat(1);
			vertexBytes.writeFloat(1);
						
			//Vertex 4
			//pos
			vertexBytes.writeFloat(normalizedX + _width * 2);
			vertexBytes.writeFloat(normalizedY);
			//uv
			vertexBytes.writeFloat(1);
			vertexBytes.writeFloat(0);
			
			//IndexData
			indexBytes.writeShort(currentQuadOffset + 0);
			indexBytes.writeShort(currentQuadOffset + 1);
			indexBytes.writeShort(currentQuadOffset + 2);
			indexBytes.writeShort(currentQuadOffset + 0);
			indexBytes.writeShort(currentQuadOffset + 2);
			indexBytes.writeShort(currentQuadOffset + 3);	
		}
		
		
	}

}