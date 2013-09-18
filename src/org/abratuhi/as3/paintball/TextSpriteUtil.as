package org.abratuhi.as3.paintball
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author ...
	 */
	public class TextSpriteUtil
	{
		
		public static function text2sprite(text:String):Sprite
		{
			var tf:TextField = new TextField();
			tf.text = text;
			
			var bitmapdata:BitmapData = new BitmapData(tf.width, tf.height, true, 0x000000ff);
			bitmapdata.draw(tf);
			
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginBitmapFill(bitmapdata);
			sprite.graphics.drawRect(0, 0, tf.width, tf.height);
			sprite.graphics.endFill();
			
			return sprite;
		}
	
	}

}