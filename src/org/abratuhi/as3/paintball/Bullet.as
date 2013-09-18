package org.abratuhi.as3.paintball
{
	import nape.callbacks.CbType;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.space.Space;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Bullet
	{
		
		public static const BULLET_RADIUS:int = 1;
		public static const BULLET_SPEED:int = 200;
		
		public static const BULLET_TYPE:CbType = new CbType();
		
		public var player:Player = null;
		
		public var body:Body = new Body();
		
		public function Bullet(sp:Space, pl:Player)
		{
			super();
			
			this.player = pl;
			
			body.shapes.add(new Circle(BULLET_RADIUS));
			body.type = BodyType.DYNAMIC;
			body.space = sp;
			
			body.position.setxy(pl.body.worldCOM.x + (Player.PLAYER_RADIUS + Player.WEAPON_SIZE) * Math.cos(pl.body.rotation), pl.body.worldCOM.y + (Player.PLAYER_RADIUS + Player.WEAPON_SIZE) * Math.sin(pl.body.rotation));
			body.velocity = new Vec2(BULLET_SPEED * Math.cos(pl.body.rotation), BULLET_SPEED * Math.sin(pl.body.rotation));
			
			body.cbTypes.add(BULLET_TYPE);
		}
	
	}

}