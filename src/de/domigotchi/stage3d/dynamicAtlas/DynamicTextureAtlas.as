package de.domigotchi.stage3d.dynamicAtlas 
{
	import com.adobe.utils.AGALMiniAssembler;
	import de.domigotchi.stage3d.dynamicAtlas.factories.TextureFactory;
	import de.domigotchi.stage3d.dynamicAtlas.TextureWrapper;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Dominik Saur
	 */
	public class DynamicTextureAtlas 
	{
		static public const DEBUG:Boolean = false;
		
		
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
		private var _currentHeight:Number = 0;
		private var _currentY:Number = 0;
		private var _currentMaxY:Number = 0;
		private var _helperRectangle:Rectangle = new Rectangle();
		
		private var _bIsTextureStreamingEnabled:Boolean = true;
		
		public function DynamicTextureAtlas(stage3D:Stage3D, width:int, height:int, bIsTextureStreamingEnabled = false) 
		{
			_bIsTextureStreamingEnabled = bIsTextureStreamingEnabled;
			_atlasHeight = TextureWrapper.getNextPowerOf2(height);
			_atlasWidth = TextureWrapper.getNextPowerOf2(width);
			
			if (_atlasWidth >= 1024 || _atlasHeight >= 1024 && bIsTextureStreamingEnabled)
			{
				trace("warning: drawing on big renderTextures can be slow on mobile devices")
			}
			
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
			
			var texture:TextureBase;
			try
			{
				texture = _context3D.createRectangleTexture(_atlasWidth, _atlasHeight, Context3DTextureFormat.BGRA_PACKED, true);
			}
			catch (e:Error)
			{
				texture = _context3D.createTexture(_atlasWidth, _atlasHeight, Context3DTextureFormat.BGRA_PACKED, true);
			}
			_renderTexture.initWithTexture(texture);
			_renderTextureInitialized = false;
			
			if (_isDirty)
				update();
		}
		
		public function addTextureFactory(textureFactory:TextureFactory):TextureWrapper
		{
			var subTexture:TextureWrapper;
			if (textureFactory.width > _atlasWidth || textureFactory.height > _atlasHeight)
				throw new Error(" to big to render");
			if (_newTextureWrappersMap[textureFactory.id] == null)
			{
				subTexture = _renderTexture.getSubTexture(textureFactory.id, textureFactory.width, textureFactory.height);
				subTexture.initWithFactory(textureFactory);
				textureFactory.addOnCompleteCallback(onFactoryTextureCreationComplete);
				_atlasTexturesMap[textureFactory.id] = subTexture;
				_numTextures ++;
				
				if (!_bIsTextureStreamingEnabled)
				{
					subTexture.nativeTexture;
					_isDirty = true;
				}
			}
			
			return subTexture;
		}
		
		private function onFactoryTextureCreationComplete(factory:TextureFactory):void 
		{
			_newTextureWrappersMap[factory.id] = factory.textureWrapper;
			_isDirty = true;
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
			if (!_context3D) return;
			
			if (_isDirty || DEBUG)
			{
				_context3D.setProgram(_program3D);
				_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
				_context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				_context3D.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_1);
				_context3D.setVertexBufferAt(1, _vertexBuffer, 1, Context3DVertexBufferFormat.FLOAT_2);
		
				if (_isDirty)
				{

					_context3D.setRenderToTexture(_renderTexture.nativeTexture, false);
					//_context3D.clear();
					if (!_renderTextureInitialized)
					{
						_context3D.clear();
						_renderTextureInitialized = true;
					}
					
					var x:Number = 0;
					var y:Number = 0;
					for(var key:String in _newTextureWrappersMap)
					{
						var texture:TextureWrapper = _newTextureWrappersMap[key];
						if (_currentX + texture.width > _atlasWidth)
						{
							_currentX = 0;
							_currentY = _currentMaxY;
						}
						x = _currentX / _atlasWidth;
						y = _currentY / _atlasHeight;
						draw(x, y, texture);
						_currentHeight = _currentY + texture.height;
						_currentMaxY = _currentMaxY < _currentHeight ? _currentHeight : _currentMaxY;
						_currentX += texture.width;
						delete(_newTextureWrappersMap[key]);
						
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
				_context3D.setScissorRectangle(null);
			}

		}
		
		private function draw(x:Number, y:Number, texture:TextureWrapper):void
		{
			var width:Number = texture.width / _atlasWidth;
			var height:Number = texture.height / _atlasHeight;
			_drawQuad.init(x, y, width, height);
			_helperRectangle.setTo(x * _atlasWidth, y * _atlasHeight, texture.width, texture.height);
			if(_helperRectangle.x < _atlasWidth && _helperRectangle.y < _atlasHeight)
				_context3D.setScissorRectangle(_helperRectangle);
			else
				_context3D.setScissorRectangle(null);
			var subTexture:TextureWrapper = _atlasTexturesMap[texture.id];
			if (subTexture)
				subTexture.setUVRegion(x * _atlasWidth , y * _atlasHeight, width * _atlasWidth, height * _atlasHeight);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _drawQuad.setVertexConstant(_helperVector), 4);
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