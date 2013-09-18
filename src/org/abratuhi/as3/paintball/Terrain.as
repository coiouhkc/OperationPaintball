package org.abratuhi.as3.paintball
{
	
	import nape.callbacks.CbType;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Terrain
	{
		public static const TERRAIN_TYPE:CbType = new CbType();
		
		public var body:Body = new Body(BodyType.STATIC);
		
		private var space:Space = null;
		
		public function Terrain(sp:Space)
		{
			this.space = sp;
			
			body.cbTypes.add(TERRAIN_TYPE);
		}
		
		public static function createBorder(sp:Space, w:int, h:int):Terrain
		{
			var terrain:Terrain = new Terrain(sp);
			terrain.body.shapes.add(new Polygon(Polygon.rect(0, 0, w, -1)));
			terrain.body.shapes.add(new Polygon(Polygon.rect(0, h, w, 1)));
			terrain.body.shapes.add(new Polygon(Polygon.rect(0, 0, -1, h)));
			terrain.body.shapes.add(new Polygon(Polygon.rect(w, 0, 1, h)));
			terrain.body.space = sp;
			return terrain;
		}
		
		public static function createLevel1(sp:Space, w:int, h:int):Array
		{
			var result:Array = new Array();
			for (var i:int = 0; i < 2; i++)
			for (var j:int = 0; j < 2; j++) {
			{
				var terrain:Terrain = new Terrain(sp);
				terrain.body.shapes.add(new Polygon(Polygon.regular(w/8, h/8, 6)));
				terrain.body.position.setxy(w/4 + i*w/2, h/4 + j*h/2);
				terrain.body.space = sp;
				result.push(terrain);
			}
			}
			return result;
		}
	
	}

}