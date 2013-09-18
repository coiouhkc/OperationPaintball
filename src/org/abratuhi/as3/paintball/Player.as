package org.abratuhi.as3.paintball
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.text.TextField;
	import nape.callbacks.CbType;
	import nape.constraint.PivotJoint;
	import nape.geom.Geom;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Player
	{
		
		public static const PLAYER_RADIUS:int = 20;
		public static const WEAPON_SIZE:int = 10;
		
		public static const PLAYER_TYPE:CbType = new CbType();
		
		private var stage:Stage = null;
		private var space:Space = null;
		
		public var id:int = -1;
		public var body:Body = new Body();
		
		public var n:int = -1;
		
		public var hp:int = 10;
		public var ammo:int = 100;
		public var isHuman:Boolean = true;
		
		public var movement:PivotJoint = null;
		
		public function Player(st:Stage, sp:Space, x:int, y:int, n:int, isHuman:Boolean)
		{
			super();
			
			this.stage = st;
			this.space = sp;
			this.id = body.id;
			this.n = n;
			this.isHuman = isHuman;
			
			body.type = BodyType.DYNAMIC;
			body.position.setxy(x, y);
			body.space = sp;
			body.cbTypes.add(PLAYER_TYPE);
			
			if (isHuman)
			{
				var vertices:Array = new Array();
				vertices.push(new Vec2(0, 0));
				vertices.push(new Vec2(PLAYER_RADIUS * 2, PLAYER_RADIUS));
				vertices.push(new Vec2(0, PLAYER_RADIUS * 2));
				vertices.push(new Vec2(0, 0));
				body.shapes.add(new Polygon(vertices));
				body.rotation = -Math.PI / 2;
				
				var sprite:Sprite = TextSpriteUtil.text2sprite("" + this.n);
				sprite.x = body.worldCOM.x;
				sprite.y = body.worldCOM.y;
				
				this.body.userData.sprite = sprite;
				
				this.stage.addChild(this.body.userData.sprite);
			}
			else
			{
				body.shapes.add(new Polygon(Polygon.rect(0, 0, PLAYER_RADIUS, PLAYER_RADIUS * 2)));
				body.shapes.add(new Polygon(Polygon.rect(PLAYER_RADIUS, 0, PLAYER_RADIUS, PLAYER_RADIUS * 2)));
			}
			
			this.movement = new PivotJoint(sp.world, body, Vec2.weak(), Vec2.weak());
			this.movement.active = false;
			this.movement.space = sp;
			this.movement.stiff = false;
			this.movement.frequency = 0.1;
			this.movement.damping = 0.1;
		}
		
		public function fire():void
		{
			if (!isDown() && hasAmmo())
			{
				var bullet:Bullet = new Bullet(this.space, this);
				ammo--;
			}
		}
		
		public function updateUserData(x:int, y:int):void
		{
			this.body.userData.sprite.x = body.worldCOM.x;
			this.body.userData.sprite.y = body.worldCOM.y;
		}
		
		public function hit():void
		{
			hp--;
			if (isDown())
			{
				kill();
				trace("player " + n + " was fatally hit.");
			}
		}
		
		public function kill():void
		{
			hp = 0;
			ammo = 0;
			
			this.body.space = null;
			this.body.constraints.foreach(space.constraints.remove);
			this.space.bodies.remove(body);
			
			if (isHuman && this.body.userData.sprite != null)
			{
				try
				{
					this.stage.removeChild(this.body.userData.sprite);
				}
				catch (e:Error)
				{
					if (this.body.userData.sprite.parent != null)
					{
						this.body.userData.sprite.parent.removeChild(this.body.userData.sprite);
					}
				}
			}
		}
		
		public function isDown():Boolean
		{
			trace("isDown: " + " hp(#" + n + ")=" + hp);
			return (hp <= 0);
		}
		
		public function hasAmmo():Boolean
		{
			return (ammo > 0);
		}
		
		public function premove(x:int, y:int):void
		{
			var mousePoint:Vec2 = Vec2.get(x, y);
			this.movement.anchor2.set(body.worldPointToLocal(mousePoint, true));
			mousePoint.dispose();
		}
		
		public function move(x:int, y:int):void
		{
			this.movement.active = true;
			this.movement.anchor1.set(new Vec2(x, y));
			//this.movement.anchor2.set(body.worldPointToLocal(body.position, true));
		}
		
		public function randomAi(w:int, h:int):void
		{
			var new_x:int = Math.random() * w;
			var new_y:int = Math.random() * h;
			
			this.move(new_x, new_y);
		}
		
		public function snipeAi(w:int, h:int, terrains:Array, humans:Array):Boolean
		{
			var result:Boolean = false;
			var player:Player = null;
			if (humans.length > 0)
			{
				for (var i:int = 0; i < humans.length; i++)
				{
					player = humans[i];
					if (!player.isDown() && inSight(player, terrains, humans))
					{
						break;
					}
				}
				if (!player.isDown() && inSight(player, terrains, humans))
				{
					result = true;
					var px:int = player.body.worldCOM.x;
					var py:int = player.body.worldCOM.y;
					var angle:Number = Math.atan2(py - body.worldCOM.y, px - body.worldCOM.x);
					body.rotation = angle;
					trace("ai #" + n + " attacks human #" + player.n);
					fire();
				}
			}
			return result;
		}
		
		public function distTo(player:Player):Number
		{
			return Geom.distanceBody(body, player.body, Vec2.weak(), Vec2.weak());
		}
		
		public function inSight(player:Player, terrains:Array, players:Array):Boolean
		{
			var result:Boolean = true;
			var terrain:Terrain = null;
			var human:Player = null;
			var i:int = -1;
			
			if (result)
			{
				for (i = 0; i < terrains.length; i++)
				{
					terrain = terrains[i];
					if (MathUtil.interval2body(body.worldCOM.x, body.worldCOM.y, player.body.worldCOM.x, player.body.worldCOM.y, terrain.body))
					{
						result = false;
						break;
					}
				}
			}
			
			if (result)
			{
				for (i = 0; i < players.length; i++)
				{
					human = players[i];
					if (player.id != human.id && MathUtil.interval2body(body.worldCOM.x, body.worldCOM.y, player.body.worldCOM.x, player.body.worldCOM.y, human.body))
					{
						result = false;
						break;
					}
				}
			}
			
			return result;
		}
	
	}

}