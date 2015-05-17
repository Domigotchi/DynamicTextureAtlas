package de.domigotchi.stage3d.textures 
{
	import de.domigotchi.stage3d.textures.TextureWrapper;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
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
		
		private var _atlasTexturesMap:Dictionary = new Dictionary();
		
		private var _newTextureWrappersMap:Dictionary = new Dictionary();
		private var _numTextures:uint = 0;
		private var _program3D:Program3D;
		
		private var _atlasWidth:int;
		private var _atlasHeight:int;
		private var _renderTexture:TextureWrapper;
		private var _renderTextureInitialized:Boolean;
		private var _currentX:int = 0;
		
		private var _drawQuad:DynamicQuad = new DynamicQuad();
		
		private static var _helperVector:Vector.<Number> = new Vector.<Number>();
		
		public function DynamicTextureAtlas(stage3D:Stage3D, width:int, height:int) 
		{
			_atlasHeight = TextureWrapper.getNextPowerOf2(height);
			_atlasWidth = TextureWrapper.getNextPowerOf2(width);
			_stage3D = stage3D;
			init();	
		}
		
		private function init():void 
		{
			_renderTexture = new TextureWrapper("DynamicTextureAtlas", _atlasWidth, _atlasHeight);
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			if (!_vertexShaderBytes || !_fragmentShaderBytes)
			{
				var assembler:AGALMiniAssembler = new AGALMiniAssembler(false);
				/*var vertexShaderString:String = "mul op, va0, vc0\n" +
												"mul v0, va1.xy, vc1.xy";*/
				var vertexShaderString:String = "mov op, vc[va0.x]\n" +
												"mul v0, va1.xy, vc4.xy";
				var fragmentShaderString:String = "tex oc, v0, fs0 <2d>";
				
				_vertexShaderBytes = assembler.assemble("vertex", vertexShaderString);
				_fragmentShaderBytes  = assembler.assemble("fragment", fragmentShaderString);
			}
			
			if (isContextAvailable)
				onContextCreated();
		}
		
		private function onContextCreated(e:Event=null):void 
		{
			_context3D = _stage3D.context3D;
			_vertexBuffer = _context3D.createVertexBuffer(DynamicQuad.NUM_VERTICES, DynamicQuad.DATA_32_PER_VERTEX);
			_indexBuffer = _context3D.createIndexBuffer(DynamicQuad.NUM_INDICES);
			_program3D = _context3D.createProgram();
			_program3D.upload(_vertexShaderBytes, _fragmentShaderBytes);
			
			_drawQuad.init(0, 0, 1, 1);
			_drawQuad.fillBytes(_vertexBufferBytes, _indexBufferBytes);
			_vertexBuffer.uploadFromByteArray(_vertexBufferBytes, 0, 0, DynamicQuad.NUM_VERTICES);
			_indexBuffer.uploadFromByteArray(_indexBufferBytes, 0, 0, DynamicQuad.NUM_INDICES);
			
			var texture:Texture = _context3D.createTexture(_atlasWidth, _atlasHeight, Context3DTextureFormat.BGRA, true);
			_renderTexture.initWithTexture(texture);
			_renderTextureInitialized = false;
		}
		
		public function addTextureWrapper(InTexture:TextureWrapper):TextureWrapper
		{
			var subTexture:TextureWrapper;
			if (InTexture.width > _atlasWidth || InTexture.height > _atlasHeight)
				throw new Error(" to big to render");
			if (_newTextureWrappersMap[InTexture.id] == null)
			{
				subTexture = _renderTexture.getSubTexture(InTexture.id, InTexture.width, InTexture.height);
				_newTextureWrappersMap[InTexture.id] = InTexture;
				_atlasTexturesMap[InTexture.id] = subTexture;
				_numTextures ++;
				_isDirty = true;
			}
			
			return subTexture;
		}

		
		public function update():void
		{
			if (_isDirty || DEBUG)
			{
				_context3D.setProgram(_program3D);
				_context3D.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_1);
				_context3D.setVertexBufferAt(1, _vertexBuffer, 1, Context3DVertexBufferFormat.FLOAT_2);
		
				if (_isDirty)
				{
					_currentX = 0;
					_context3D.setRenderToTexture(_renderTexture.nativeTexture, false, 1);
					if (!_renderTextureInitialized)
					{
						_context3D.clear();
						_renderTextureInitialized = true;
					}
					
					var x:Number = 0;
					var y:Number = 0;
					var maxY:Number = 0;
					var currentHeight:Number = 0;
					var _currentY:Number = 0;
					for each(var texture:TextureWrapper in _newTextureWrappersMap)
					{
						if (_currentX + texture.width > _atlasWidth)
						{
							_currentX = 0;
							_currentY = maxY;
						}
						x = _currentX / _atlasWidth;
						y = _currentY / _atlasHeight;
						draw(x, y, texture);
						currentHeight = _currentY + texture.height;
						maxY = maxY < currentHeight ? currentHeight : maxY;
						_currentX += texture.width;
						
					}
					_isDirty = false;
					_context3D.setRenderToBackBuffer();
					
				}
				if (DEBUG)
				{
					draw(0, 0, _renderTexture);
				}
				_context3D.setVertexBufferAt(0, null);
				_context3D.setVertexBufferAt(1, null);
				_context3D.setTextureAt(0, null);
			}

		}
		
		private function draw(x:Number, y:Number, texture:TextureWrapper):void
		{
			var width:Number = texture.width / _atlasWidth;
			var height:Number = texture.height / _atlasHeight;
			_drawQuad.init(x, y, width, height);
			
			var subTexture:TextureWrapper = _atlasTexturesMap[texture.id];
			if (subTexture)
				subTexture.setUVRect(x , y, width, height);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _drawQuad.setVertexConstant(0, _helperVector));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 1, _drawQuad.setVertexConstant(1, _helperVector));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 2, _drawQuad.setVertexConstant(2, _helperVector));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 3, _drawQuad.setVertexConstant(3, _helperVector));
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, texture.uvMultiplier);
			
			_context3D.setTextureAt(0, texture.nativeTexture);
			_context3D.drawTriangles(_indexBuffer);
		}
		
		private function get isContextAvailable():Boolean 
		{
			return _stage3D.context3D != null && _stage3D.context3D.driverInfo != "disposed";
		}
		
	}

}