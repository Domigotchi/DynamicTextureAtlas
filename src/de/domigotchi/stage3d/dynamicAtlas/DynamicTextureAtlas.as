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
		
		private var _orginalTextureWrappersList:Vector.<TextureWrapper> = new Vector.<TextureWrapper>();
		private var _numTextures:uint = 0;
		private var _program3D:Program3D;
		
		private var _atlasWidth:int;
		private var _atlasHeight:int;
		private var _renderTexture:TextureWrapper;
		private var _renderTextureInitialized:Boolean;
		
		
		private var _drawQuad:DynamicQuad = new DynamicQuad();
		
		private static var _helperVector:Vector.<Number> = new Vector.<Number>();
		
		private var _helperRectangle:Rectangle = new Rectangle();
		
		private var _bIsTextureStreamingEnabled:Boolean = true;
		private var _waitForNextFrame:int;
		private var _padding:uint;
		private var _texturePacker:ITexturePacker;
		
		public function DynamicTextureAtlas(stage3D:Stage3D, width:uint, height:uint, padding:uint = 1, bIsTextureStreamingEnabled = false, texturePacker:ITexturePacker = null) 
		{
			if (texturePacker)
			{
				_texturePacker = texturePacker;
			}
			else
			{
				_texturePacker = new InternalPacker();
			}
			
			_padding = padding;
			_bIsTextureStreamingEnabled = bIsTextureStreamingEnabled;
			_atlasWidth = width;
			_atlasHeight = height;
			
			_texturePacker.setSizes(_atlasWidth, _atlasHeight, padding);
			
			if ((_atlasWidth >= 1024 || _atlasHeight >= 1024) && _bIsTextureStreamingEnabled)
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
				texture = _context3D.createRectangleTexture(_atlasWidth, _atlasHeight, Context3DTextureFormat.BGRA, true);
			}
			catch (e:Error)
			{
				_atlasWidth = TextureWrapper.getNextPowerOf2(_atlasWidth);
				_atlasHeight = TextureWrapper.getNextPowerOf2(_atlasHeight);
				_texturePacker.setSizes(_atlasWidth, _atlasHeight, _padding);
				texture = _context3D.createTexture(_atlasWidth, _atlasHeight, Context3DTextureFormat.BGRA, true);
			}
			_renderTexture.initWithTexture(texture);
			_renderTextureInitialized = false;
			
			if (_isDirty)
				update();
		}
		
		public function addTextureFactory(textureFactory:TextureFactory):TextureWrapper
		{
			var subTexture:TextureWrapper;
			if (_atlasTexturesMap[textureFactory.id] == null)
			{
				subTexture = _renderTexture.getSubTexture(textureFactory.id, 1, 1);
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
			var currentTextureWrapper:TextureWrapper = _atlasTexturesMap[factory.id];
			currentTextureWrapper.initWithTexture(factory.textureWrapper.nativeTexture, factory.textureWrapper.width, factory.textureWrapper.height);
			_texturePacker.insertTexture(factory.textureWrapper);
			_orginalTextureWrappersList[_orginalTextureWrappersList.length] = factory.textureWrapper;
			_isDirty = true;
		}
		
		public function addTextureWrapper(InTexture:TextureWrapper):TextureWrapper
		{
			var subTexture:TextureWrapper;
			if (InTexture.width > _atlasWidth || InTexture.height > _atlasHeight)
				throw new Error(" to big to render");
			if (_atlasTexturesMap[InTexture.id] == null)
			{
				subTexture = _renderTexture.getSubTexture(InTexture.id, InTexture.width, InTexture.height);
				_orginalTextureWrappersList[_orginalTextureWrappersList.length] = InTexture;
				_texturePacker.insertTexture(InTexture);
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
					
					if (_waitForNextFrame != 1)
					{
						_waitForNextFrame ++;
						return;
					}
					_waitForNextFrame = 0;
					_context3D.setRenderToTexture(_renderTexture.nativeTexture, false);
					
					if (!_renderTextureInitialized)
					{
						_context3D.clear(1, 1, 1, 0);
						_renderTextureInitialized = true;
					}
					
					_texturePacker.packTextures();
					
					var texture:TextureWrapper;
					if (_bIsTextureStreamingEnabled)
					{
						var length:uint = _orginalTextureWrappersList.length;
						for (var i:int = length - 1; i >= 0; i--)
						{
							draw(_orginalTextureWrappersList[i]);
						}
						_orginalTextureWrappersList.length = 0;
					}
					else
					{
						_texturePacker.reset();
						_texturePacker.packTextures();
						//_context3D.clear();
						for each(texture in _orginalTextureWrappersList)
						{
							draw(texture);
						}
					}
					
					_isDirty = false;
					_context3D.setRenderToBackBuffer();
					
				}
				if (DEBUG)
				{
					_drawQuad.init(0, 0, 1, 1);
					draw(_renderTexture);
				}
				_context3D.setVertexBufferAt(0, null);
				_context3D.setVertexBufferAt(1, null);
				_context3D.setTextureAt(0, null);
				_context3D.setScissorRectangle(null);
			}

		}
		
		
		
		private function draw(texture:TextureWrapper):void
		{
			var region:Rectangle = texture.getUVRegion();
			var x:Number = region.x/_atlasWidth;
			var y:Number = region.y/_atlasHeight;
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
import de.domigotchi.stage3d.dynamicAtlas.ITexturePacker;
import flash.geom.Rectangle;
import flash.utils.Dictionary;
import de.domigotchi.stage3d.dynamicAtlas.TextureWrapper;
internal class InternalPacker implements ITexturePacker
{
	private var _width:uint;
	private var _height:uint;
	private var _padding:uint;
	private var _textureWrapperMap:Dictionary = new Dictionary();
	private var _textureWrapperList:Vector.<TextureWrapper> = new Vector.<TextureWrapper>();
	
	private var _currentX:int = 0;
	private var _currentHeight:int = 0;
	private var _currentY:int = 0;
	private var _currentMaxY:int = 0;
	
	private var _freeSpaces:Vector.<Space> = new Vector.<Space>();
	private var _packedSpaces:Vector.<Space> = new Vector.<Space>();
	
	public function InternalPacker()
	{
		
	}
	
	/* INTERFACE de.domigotchi.stage3d.dynamicAtlas.ITexturePacker */
	
	public function setSizes(width:uint, height:uint, padding:uint):void
	{
		_padding = padding;
		_height = height;
		_width = width;
		_freeSpaces.length = 0;
		_packedSpaces.length = 0;
		_freeSpaces[0] = new Space(0,0, width, height);
	}
	
	public function insertTexture(textureWrapper:TextureWrapper):void
	{
		_textureWrapperMap[textureWrapper.id] = textureWrapper;
		_textureWrapperList[_textureWrapperList.length] = textureWrapper;
	}
	
	
	public function packTextures():Boolean 
	{
		_textureWrapperList.sort(sortOnSize);
		var textureWrapper:TextureWrapper;
		for (var i:uint = 0; i < _textureWrapperList.length; i++)
		{
			textureWrapper = _textureWrapperList[i];
			var space:Space = findAndConsumeFreeSpace(textureWrapper.width + _padding, textureWrapper.height + _padding);
			if (space)
			{
				textureWrapper.setUVRegion(space.x, space.y, space.width, space.height);
			}
			else
			{
				findAndConsumeFreeSpace(textureWrapper.width + _padding, textureWrapper.height + _padding);
				trace("atlas is full");
			}
		}
		
		return true;
	}
	
	private function findAndConsumeFreeSpace(width:uint, height:uint):Space 
	{
		var bestSpace:Space;
		var bestSpaceIndex:int = -1;
		var currentSpace:Space;
		var diffWidth:int;
		var diffHeight:int;
		for (var i:uint; i < _freeSpaces.length; i++)
		{
			currentSpace = _freeSpaces[i];
			if (currentSpace.width >= width && currentSpace.height >= height)
			{
				if (bestSpace)
				{
					diffWidth =  currentSpace.width - bestSpace.width;
					diffHeight = currentSpace.height - bestSpace.height;
					if (diffWidth + diffHeight < 0)
					{
						bestSpace = currentSpace;
						bestSpaceIndex = i;
					}
				}
				else
				{
					bestSpace = currentSpace;
					bestSpaceIndex = i;
				}
			}
		}
		if (bestSpace)
		{
			_freeSpaces.splice(bestSpaceIndex, 1);
			if (bestSpace.width == width && bestSpace.height == height)
			{
				return bestSpace;
			}
			else
			{
				var offsetXSpace:Space;
				if (bestSpace.width != width)
				{
					offsetXSpace = new Space(bestSpace.x + width, bestSpace.y, bestSpace.width - width, bestSpace.height);
					_freeSpaces[_freeSpaces.length] = offsetXSpace;
				}
				
				if (bestSpace.height != height)
				{
					var offsetYSpace:Space = new Space(bestSpace.x , bestSpace.y + height, bestSpace.width, bestSpace.height - height);
					_freeSpaces[_freeSpaces.length] = offsetYSpace;
					if (offsetXSpace)
					{
						if (offsetXSpace.width * offsetXSpace.height < offsetYSpace.width * offsetYSpace.height)
							offsetXSpace.height = height;
						else
							offsetYSpace.width = width;
					}
				}
				bestSpace = new Space(bestSpace.x, bestSpace.y, width, height);
				return bestSpace;
			}
		}
		
		return bestSpace;
	}
	
	/* INTERFACE de.domigotchi.stage3d.dynamicAtlas.ITexturePacker */
	
	public function getPackedTextureSize(id:String):Rectangle 
	{
		return _textureWrapperMap[id].bounds;
	}
	
	private function sortOnSize(a:TextureWrapper, b:TextureWrapper):int 
	{
		if (a.width * a.height <= b.width * b.height)
			return -1;
		else
			return 1;
	}
	
	public function reset():void
	{
		_currentX = 0;
		_currentY = 0;
		_currentMaxY = 0;
		_currentHeight = 0;
	}
	
}
internal class Space
{
	
	public var x:uint;
	public var y:uint;
	public var width:uint;
	public var height:uint;
	public function Space(x:uint, y:uint, width:uint, height:uint)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
}