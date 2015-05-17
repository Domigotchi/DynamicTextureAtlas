package de.domigotchi.stage3d.textures 
{
	import flash.sampler.getSize;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class DynamicQuad 
	{
		public static const DATA_32_PER_VERTEX:uint = 3;
		public static const NUM_VERTICES:uint = 4;
		public static const NUM_INDICES:uint = 6;
		
		
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _width:Number = 0;
		private var _height:Number = 0;
		
		public function DynamicQuad() 
		{
			
		}
		
		public function init(x:Number, y:Number, width:Number, height:Number):DynamicQuad
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
			
			//Vertex 1
			//id
			vertexBytes.writeFloat(0);
			//uv
			vertexBytes.writeFloat(0);
			vertexBytes.writeFloat(0);
			
			//Vertex 2
			//id
			vertexBytes.writeFloat(1);
			//uv
			vertexBytes.writeFloat(0);
			vertexBytes.writeFloat(1);
			
			//Vertex 3
			//id
			vertexBytes.writeFloat(2);
			//uv
			vertexBytes.writeFloat(1);
			vertexBytes.writeFloat(1);
						
			//Vertex 4
			//id
			vertexBytes.writeFloat(3);
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
		
		public function setVertexConstant(index:uint, outVector:Vector.<Number>):Vector.<Number>
		{
			outVector.length = 4;
			
			var normalizedX:Number = (_x * 2) - 1;
			var normalizedY:Number = -((_y * 2) - 1);
			var normalizedWidth:Number = normalizedX + _width * 2;
			var normalizedHeight:Number = normalizedY - _height * 2;
			
			if (index == 0)
			{
				outVector[0] = normalizedX;
				outVector[1] = normalizedY;
			} 
			else if (index == 1)
			{
				outVector[0] = normalizedX;
				outVector[1] = normalizedHeight;
			}
			else if (index == 2)
			{
				outVector[0] = normalizedWidth;
				outVector[1] = normalizedHeight;
			}
			else if (index == 3)
			{
				outVector[0] = normalizedWidth;
				outVector[1] = normalizedY;
			}
			else throw new Error("invalid vertex Index");
			
			outVector[2] = 0;
			outVector[3] = 1;
			
			return outVector;
		}
	
		
		
	}

}