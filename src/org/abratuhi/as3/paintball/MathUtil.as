package org.abratuhi.as3.paintball
{
	import nape.phys.Body;
	import nape.shape.Shape;
	import nape.shape.Edge;
	import nape.shape.EdgeList;
	import nape.shape.Polygon;
	
	/**
	 * ...
	 * @author ...
	 */
	public class MathUtil
	{
		
		public function MathUtil()
		{
		
		}
		
		public static function sign(number:Number):int
		{
			return ((number > 0) ? 1 : (number < 0) ? -1 : 0);
		}
		
		/**
		 * From http://wiki.processing.org/w/Line-Line_intersection.
		 */
		public static function interval2interval(x11:Number, y11:Number, x12:Number, y12:Number, x21:Number, y21:Number, x22:Number, y22:Number):Boolean
		{
			//trace("interval2interval: " + arguments);
			var bx:Number = x12 - x11;
			var by:Number = y12 - y11;
			var dx:Number = x22 - x21;
			var dy:Number = y22 - y21;
			var b_dot_d_perp:Number = bx * dy - by * dx;
			if (b_dot_d_perp == 0)
			{
				//trace("interval2interval: " + "false");
				return false;
			}
			var cx:Number = x21 - x11;
			var cy:Number = y21 - y11;
			var t:Number = (cx * dy - cy * dx) / b_dot_d_perp;
			if (t < 0 || t > 1)
			{
				//trace("interval2interval: " + "false");
				return false;
			}
			var u:Number = (cx * by - cy * bx) / b_dot_d_perp;
			if (u < 0 || u > 1)
			{
				//trace("interval2interval: " + "false");
				return false;
			}
			//trace("interval2interval: " + "true");
			return true;
		}
		
		public static function interval2edge(x11:Number, y11:Number, x12:Number, y12:Number, edge:Edge): Boolean {
			return interval2interval(x11, y11, x12, y12, edge.worldVertex1.x, edge.worldVertex1.y, edge.worldVertex2.x, edge.worldVertex2.y);
		}
		
		public static function interval2poly(x11:Number, y11:Number, x12:Number, y12:Number, poly:Polygon): Boolean {
			//trace("interval2poly: " + arguments);
			var result:Boolean = false;
			var el:EdgeList = poly.edges;
			for (var i:int = 0; !result && i < el.length; i++) {
				var edge:Edge = el.at(i);
				result = interval2edge(x11, y11, x12, y12, edge);
			}
			return result;
		}
		
		public static function interval2shape(x11:Number, y11:Number, x12:Number, y12:Number, shape:Shape): Boolean {
			//trace("interval2shape: " + arguments);
			var result:Boolean = false;
			if (shape.castPolygon != null) {
				result = interval2poly(x11, y11, x12, y12, shape.castPolygon);
			}
			return result;
		}
		
		public static function interval2body(x11:Number, y11:Number, x12:Number, y12:Number, body:Body): Boolean {
			//trace("interval2body: " + arguments);
			var result:Boolean = false;
			for (var i:int = 0; !result && i < body.shapes.length; i++) {
				var shape:Shape = body.shapes.at(i);
				result = interval2shape(x11, y11, x12, y12, shape);
			}
			return result;
		}
	}

}