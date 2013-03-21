/*
* Copyright(c) 2012 the original author or authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
* either express or implied. See the License for the specific language
* governing permissions and limitations under the License.
*/
package
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.net.LocalConnection;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * @author zhangji
	 */
	public class UIEditiorLib
	{
		private static var _instance:UIEditiorLib;
		
		public static function getInstance():UIEditiorLib
		{
			if(_instance == null)
			{
				_instance = new UIEditiorLib();
			}
			return _instance;
		}
		
		private var swf2airConn:LocalConnection;
		
		private var air2swfConn:LocalConnection;
		
		/**
		 * 被注册的观察者 
		 */		
		private var watcher:DisplayObject; 
		
		private var _initialized:Boolean = false;
		
		public function get initialzed():Boolean
		{
			return _initialized;
		}
		
		private var _isEditior:Boolean;
		
		public function get isEditior():Boolean
		{
			return _isEditior;
		}
		
		public function set isEditior(value:Boolean):void
		{
			if(_isEditior == value)
				return;
			_isEditior = value;
			if(watcher.stage == null)
				return;
			if(value == true)
			{
				watcher.stage.addEventListener(MouseEvent.CLICK,onSelectedCurUIHandler);
				watcher.stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownHandler);
			}
			else
			{
				watcher.stage.removeEventListener(MouseEvent.CLICK,onSelectedCurUIHandler);
				watcher.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownHandler);
			}
			swf2airConn.send("_zhangji_2","swf2airOperationCall",{"type":"isEditior","value":value});
		}
		
		private var _isDrag:Boolean;
		
		public function get isDrag():Boolean
		{
			return _isDrag;
		}
		
		public function set isDrag(value:Boolean):void
		{
			if(_isDrag == value || currentUi == null)
				return;
			_isDrag = value;
			if(value == true)
			{
				if(currentUi.stage)
					currentUi.stage.addEventListener(MouseEvent.MOUSE_DOWN,onDragCurrnetUIHandler);
			}
			else
			{
				if(currentUi.stage)
					currentUi.stage.removeEventListener(MouseEvent.MOUSE_DOWN,onDragCurrnetUIHandler);
			}
			swf2airConn.send("_zhangji_2","swf2airOperationCall",{"type":"isDrag","value":value});
		}
		
		private var _currentUi:DisplayObject;
		
		public function get currentUi():DisplayObject
		{
			return _currentUi;
		}
		
		public function set currentUi(value:DisplayObject):void
		{
			if(value is Stage)
				return;
			if(_currentUi != null)
				_currentUi.filters = [];	
			_currentUi = value;
			if(_currentUi != null)
			{
				var sendParam:Object = packageSendParams(currentUi);
				swf2airConn.send("_zhangji_2","swf2airLocalCall",sendParam);
				var glow:GlowFilter = new GlowFilter();
				glow.blurX = 2;
				glow.blurY = 2;
				glow.strength = 1;
				_currentUi.filters = [glow];
			}
		}
		
		public function UIEditiorLib()
		{
		}
		
		public function register(tempInstance:DisplayObject):void
		{
			if(_initialized == false)
			{
				watcher = tempInstance;
				//初始化localConnenction
				swf2airConn = new LocalConnection();
				swf2airConn.client = _instance;
				swf2airConn.allowDomain("*");
				try
				{
					swf2airConn.connect("_zhangji_1");
				}
				catch(err:ArgumentError)
				{
					trace("Can't connect the connection name is already being used by another SWF");
				}
				air2swfConn = new LocalConnection();
				air2swfConn.addEventListener(StatusEvent.STATUS,onStatusHandler);
				_initialized = true;
			}
		}
		
		private function onStatusHandler(evt:StatusEvent):void
		{
		}
		
		private function onSelectedCurUIHandler(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
			evt.stopPropagation();
			var dis:DisplayObject = evt.target as DisplayObject;
			currentUi = dis;
		}
		
		private function onKeyDownHandler(evt:KeyboardEvent):void
		{
			if (evt.shiftKey)
			{
				var xOffext:int = 0;
				var yOffext:int = 0;
				if (evt.keyCode == Keyboard.LEFT)
					xOffext = -10;
				if (evt.keyCode == Keyboard.RIGHT)
					xOffext = 10;
				if (evt.keyCode == Keyboard.UP)
					yOffext = -10;
				if (evt.keyCode == Keyboard.DOWN)
					yOffext = 10;
			}
			else if (evt.ctrlKey)
			{
				var wOffext:int = 0;
				var hOffext:int = 0;
				if (evt.keyCode == Keyboard.LEFT)
					wOffext = -1;
				if (evt.keyCode == Keyboard.RIGHT)
					wOffext = 1;
				if (evt.keyCode == Keyboard.UP)
					hOffext = -1;
				if (evt.keyCode == Keyboard.DOWN)
					hOffext = 1;
			}
			else if (evt.keyCode == Keyboard.LEFT)
				xOffext = -1;
			else if (evt.keyCode == Keyboard.RIGHT)
				xOffext = 1;
			else if (evt.keyCode == Keyboard.UP)
				yOffext = -1;
			else if (evt.keyCode == Keyboard.DOWN)
				yOffext = 1;
			if(xOffext !=0 || yOffext != 0)
			{
				moveUi(currentUi, xOffext, yOffext);
			}
		}
		
		private var startPoint:Point;
		
		private var startMousePoint:Point;
		
		/**
		 * 拖拉元件 
		 */		
		private function onDragCurrnetUIHandler(evt:MouseEvent):void
		{
			if (currentUi!=null&&currentUi.stage!=null)
			{
				currentUi.stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_moveHandler);
				currentUi.stage.addEventListener(MouseEvent.MOUSE_UP, stage_upHandler);
				startPoint = new Point(currentUi.x, currentUi.y);
				startMousePoint = new Point(evt.stageX, evt.stageY);
			}
		}
		
		private function stage_moveHandler(e:MouseEvent):void
		{
			if (currentUi && currentUi.parent)
			{
				var p:Point = new Point(e.stageX, e.stageY);
				var xpos:Number = p.x - startMousePoint.x;
				var ypos:Number = p.y - startMousePoint.y;
				currentUi.x = startPoint.x + xpos;
				currentUi.y = startPoint.y + ypos
			}
		}
		
		private function stage_upHandler(evt:MouseEvent):void
		{
			if (currentUi!=null&&currentUi.stage!=null)
			{
				currentUi.stage.removeEventListener(MouseEvent.MOUSE_UP, stage_upHandler);
				currentUi.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_moveHandler);
			}
		}
		
		/**
		 * 包装发送连接参数 
		 * @param disObj
		 * @return 
		 * 
		 */		
		private function packageSendParams(disObj:DisplayObject):Object
		{
			var params:Object = {"className":getQualifiedClassName(disObj),"x":disObj.x,"y":disObj.y,"width":disObj.width,"height":disObj.height};
			return params;
		}
		
		/**
		 *移动某个UI
		 */
		private function moveUi(ui:DisplayObject, offextX:int, offextY:int):void
		{
			if (ui)
			{
				ui.x += offextX;
				ui.y += offextY;
				var sendParam:Object = packageSendParams(currentUi);
				swf2airConn.send("_zhangji_2","swf2airLocalCall",sendParam);
			}
		}
		
		/**
		 * 追溯父容器
		 */		
		private function parentUI():void
		{
			if(currentUi.parent != null && (currentUi.parent != watcher ||!(currentUi.parent is Stage)))//父容器非当前swf或者舞台
			{
				currentUi = currentUi.parent;
			}
		}
		
		/**
		 * 开启禁用某元件的鼠标事件
		 */		
		private function unableUI():void
		{
			if(currentUi != null && currentUi.parent != null)
			{
				if(currentUi is Sprite)
				{
					(currentUi as Sprite).mouseChildren = false;
					(currentUi as Sprite).mouseEnabled = false;
				}
			}
		}
		
		/**
		 * 移除元件
		 */		
		private function removeUI():void
		{
			if (currentUi && currentUi.parent)
			{
				currentUi.parent.removeChild(currentUi);
				currentUi = null;
			}
		}
		
		public function air2swfLocalCall(params:*):void
		{
			if(params != null && params is Array)
			{
				var type:int = int(params[0]);
				var value:int = int(params[1]);
				if(currentUi == null)
					return;
				if(type == 0)				
					currentUi.x = value;
				else if(type == 1)
					currentUi.y = value;
				else if(type == 2)
					currentUi.width = value;
				else if(type == 3)
					currentUi.width = value;
			}
		}
		
		public function air2swfOperationCall(params:*):void
		{
			if(params == null||currentUi == null)
				return;
			var typeStr:String;
			if(params is String)
			{
				typeStr = String(params);
				if(typeStr == "chosedParent")
					parentUI();
				else if(typeStr == "unable")
					unableUI();
				else if(typeStr == "removeFromParent")
					removeUI();
			}
			else if(params is Object)
			{
				typeStr = String(params.type);
				if(typeStr == "isDragModel")
				{
					isDrag = Boolean(params.value);
				}
				else if(typeStr == "isEidtiorModel")
				{
					isEditior = Boolean(params.value);
				}
			}
		}
		
	}
}
