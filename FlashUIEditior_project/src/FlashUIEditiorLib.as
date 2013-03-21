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
	import flash.display.Sprite;
	import flash.net.LocalConnection;
	
	/**
	 * @author zhangji
	 */
	public class FlashUIEditiorLib extends Sprite
	{
		/**
		 * 本地连接 
		 */		
		private var conn:LocalConnection;
		
		public function FlashUIEditiorLib()
		{
			conn = new LocalConnection();
			conn.client = this;
			conn.allowDomain("*");
			try
			{
				conn.connect("_zhangjiConnection");
			}
			catch(err:ArgumentError)
			{
				trace("Can't connect the connection name is already being used by another SWF");
			}
		}
		
		public function localCall():void
		{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0xFFFFFF*Math.random());
			sp.graphics.drawCircle(0,0,Math.random()*10+20);
			sp.graphics.endFill();
			sp.x = Math.random()*100+100;
			sp.y = Math.random()*100+100;
			this.addChild(sp);
		}
	}
}
