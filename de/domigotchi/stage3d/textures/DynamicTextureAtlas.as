package de.domigotchi.stage3d.textures 
{
	import de.domigotchi.stage3d.textures.TextureWrapper;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class DynamicTextureAtlas 
	{
		static public const DEBUG:Boolean = true;
		
		
		private var _vertexBufferBytes:ByteArray = new ByteArray();
		private var _indexBufferBytes:ByteArray = new ByteArray();
		private var _stage3D:Stage3D;
		private var _context3D:Context3D;
		
		private var _isDirty:Boolean = false;
		
		
		
		private static var _vertexShaderBytes:ByteArray;
		private static var _fragmentShaderBytes:ByteArray;
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		
		private var _newTextureWrappersMap:Dictionary = new Dictionary();
		private var _numTextures:uint = 0;
		private var _program3D:Program3D;
		
		private var _width:int;
		private var _height:int;
		private var _renderTexture:de.domigotchi.stage3d.textures.TextureWrapper;
		private var _renderTextureInitialized:Boolean;
		private var _currentX:int = 0;
		
		public function DynamicTextureAtlas(stage3D:Stage3D, width:int, height:int) 
		{
			_height = height;
			_width = width;
			_stage3D = stage3D;
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			init();
			
			if (isContextAvailable)
				onContextCreated();
			
		}
		
		private function init():void 
		{
			if (!_vertexShaderBytes || !_fragmentShaderBytes)
			{
				var assembler:AGALMiniAssembler = new AGALMiniAssembler(false);
				var vertexShaderString:String = "mov op, va0\n" +
												"mul v0, va1.xy, vc0.xy";
				var fragmentShaderString:String = "tex oc, v0, fs0 <2d>";
				
				_vertexShaderBytes = assembler.assemble("vertex", vertexShaderString);
				_fragmentShaderBytes  = assembler.assemble("fragment", fragmentShaderString);
			}
		}
		
		private function onContextCreated(e:Event=null):void 
		{
			_context3D = _stage3D.context3D;
			_vertexBuffer = _context3D.createVertexBuffer(de.domigotchi.stage3d.textures.Quad.NUM_VERTICES, de.domigotchi.stage3d.textures.Quad.DATA_32_PER_VERTEX);
			_indexBuffer = _context3D.createIndexBuffer(de.domigotchi.stage3d.textures.Quad.NUM_INDICES);
			_program3D = _context3D.createProgram();
			_program3D.upload(_vertexShaderBytes, _fragmentShaderBytes);
			_renderTexture = de.domigotchi.stage3d.textures.TextureWrapper.createRenderTextureFromSize(_context3D, _width, _height);
			_renderTextureInitialized = false;
		}
		
		public function addTextureWrapper(textureWrapper:de.domigotchi.stage3d.textures.TextureWrapper):void
		{
			if (textureWrapper.width > _width || textureWrapper.height > _height)
				throw new Error(" to big to render");
			if (_newTextureWrappersMap[textureWrapper.id] == null)
			{
				_newTextureWrappersMap[textureWrapper.id] = textureWrapper;
				_numTextures ++;
			}
			_isDirty = true;
			
		}
		
		private function createGeometryForTexture(textureWrapper:de.domigotchi.stage3d.textures.TextureWrapper):void 
		{
			
			var quad:de.domigotchi.stage3d.textures.Quad;
			_vertexBufferBytes.length = 0;
			_indexBufferBytes.length = 0;
			var x:Number = _currentX/_width;
			var y:Number = 0;
			var width:Number = textureWrapper.width/_width;
			var height:Number = textureWrapper.height/_height;
			quad = new de.domigotchi.stage3d.textures.Quad();
			quad.init(x, y, width, height);
			quad.fillBytes(_vertexBufferBytes, _indexBufferBytes);

			_vertexBuffer.uploadFromByteArray(_vertexBufferBytes, 0, 0, de.domigotchi.stage3d.textures.Quad.NUM_VERTICES);
			_indexBuffer.uploadFromByteArray(_indexBufferBytes, 0, 0, de.domigotchi.stage3d.textures.Quad.NUM_INDICES);
			
			_currentX += textureWrapper.width;
			
		}
		
		public function update():void
		{
			if (_isDirty)
			{
				_currentX = 0;
				_context3D.setRenderToTexture(_renderTexture.nativeTexture, false, 1);
				if (!_renderTextureInitialized)
				{
					_context3D.clear();
					_renderTextureInitialized = true;
				}
				
				for each(var texture:de.domigotchi.stage3d.textures.TextureWrapper in _newTextureWrappersMap)
				{
					createGeometryForTexture(texture);
					_context3D.setProgram(_program3D);
					_context3D.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
					_context3D.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
					
					_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, texture.uvMultiplier);
					_context3D.setTextureAt(0, texture.nativeTexture);
					_context3D.drawTriangles(_indexBuffer);
				}
				_isDirty = false;
				_context3D.setRenderToBackBuffer();
				_context3D.setVertexBufferAt(0, null);
				_context3D.setVertexBufferAt(1, null);
				_context3D.setTextureAt(0, null);
			}
			if (DEBUG)
			{
				
					_vertexBufferBytes.length = 0;
					_indexBufferBytes.length = 0;
					var quad:de.domigotchi.stage3d.textures.Quad = new de.domigotchi.stage3d.textures.Quad();
					quad.init(0, 0, 1, 1);
					quad.fillBytes(_vertexBufferBytes, _indexBufferBytes);
					_vertexBuffer.uploadFromByteArray(_vertexBufferBytes, 0, 0, de.domigotchi.stage3d.textures.Quad.NUM_VERTICES);
					_indexBuffer.uploadFromByteArray(_indexBufferBytes, 0, 0, de.domigotchi.stage3d.textures.Quad.NUM_INDICES);
					
					_context3D.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
					_context3D.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
					
					_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _renderTexture.uvMultiplier);
					_context3D.setTextureAt(0, _renderTexture.nativeTexture);
					_context3D.drawTriangles(_indexBuffer);
				
				_context3D.setVertexBufferAt(0, null);
				_context3D.setVertexBufferAt(1, null);
				_context3D.setTextureAt(0, null);
			}

		}
		
		private function get isContextAvailable():Boolean 
		{
			return _stage3D.context3D != null && _stage3D.context3D.driverInfo != "disposed";
		}
		
	}

}