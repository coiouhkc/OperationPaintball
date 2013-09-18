package org.abratuhi.as3.paintball {
	import nape.callbacks.CbEvent;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.constraint.PivotJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	
	public class Main extends Sprite
	{
		
		public static const N:int = 5;
		public static const OFFSET:int = 10;
		
		private var space:Space;
		private var debug:Debug;
		private var handJoint:PivotJoint;
		
		private var prevTimeMS:int;
		private var simulationTime:Number;
		
		private var terrains:Array = new Array();
		private var humans:Array = new Array();
		private var bots:Array = new Array();
		private var mapIdPlayer:Object = new Object();
		private var mapNumberPlayer:Object = new Object();
		
		private var paused:Boolean = false;
		
		private var selected:Array = new Array();
		
		private var message:Sprite = null;
		
		public function Main():void
		{
			super();
			
			if (stage != null)
			{
				initialise(null);
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, initialise);
			}
		}
		
		private function initialise(ev:Event):void
		{
			if (ev != null)
			{
				removeEventListener(Event.ADDED_TO_STAGE, initialise);
			}
			
			space = new Space();
			
			debug = new BitmapDebug(stage.stageWidth, stage.stageHeight, 0xffffff);
			addChild(debug.display);
			debug.drawConstraints = true;
			
			setUp();
		}
		
		private function collisionWithTerrainCallback(cb:InteractionCallback):void
		{
			var bullet:Body = cb.int1.castBody;
			var terrain:Body = cb.int2.castBody;
			
			if (bullet != null && bullet.shapes != null && bullet.shapes.at(0).castCircle != null && bullet.shapes.at(0).castCircle.radius == Bullet.BULLET_RADIUS)
			{
				bullet.space = null;
				bullet.constraints.foreach(space.constraints.remove);
				space.bodies.remove(bullet);
			}
		}
		
		private function collisionWithPlayerCallback(cb:InteractionCallback):void
		{
			var bullet:Body = cb.int1.castBody;
			var body:Body = cb.int2.castBody;
			
			var player:Player = mapIdPlayer[body.id];
			
			if (bullet != null && bullet.shapes != null && bullet.shapes.at(0).castCircle != null && bullet.shapes.at(0).castCircle.radius == Bullet.BULLET_RADIUS)
			{
				bullet.space = null;
				bullet.constraints.foreach(space.constraints.remove);
				space.bodies.remove(bullet);
			}
			
			if (player != null)
			{
				trace("collisionWithPlayerCallback: " + "player #" + player.n + " was hit");
				player.hit();
			}
		}
		
		private function setUp():void
		{
			trace("setUp");
			terrains = new Array();
			humans = new Array();
			bots = new Array();
			mapIdPlayer = new Object();
			mapNumberPlayer = new Object();
			
			paused = false;
			
			selected = new Array();
			
			var w:uint = stage.stageWidth;
			var h:uint = stage.stageHeight;
			var i:uint = 0;
			var player:Player = null;
			
			// Create a static border around stage.
			var border:Terrain = Terrain.createBorder(space, w, h);
			
			// Generate some random objects!
			var piles:Array = Terrain.createLevel1(space, w, h);
			terrains = piles;
			
			// Generate some human controlled players
			for (i = 1; i <= N; i++)
			{
				player = new Player(stage, space, w / 2 / N * (i + 1), h * 8 / 9, i, true);
				mapIdPlayer[player.id] = player;
				mapNumberPlayer[player.n] = player;
				humans.push(player);
				trace("setUp: " + "# humans = " + humans.length);
			}
			
			// Generate some AI controlled players
			for (i = OFFSET + 1; i <= OFFSET + N; i++)
			{
				player = new Player(stage, space, w / 2 / N * (i - OFFSET + 1), h * 1 / 9, i, false);
				mapIdPlayer[player.id] = player;
				mapNumberPlayer[player.n] = player;
				bots.push(player);
			}
			
			handJoint = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
			handJoint.space = space;
			handJoint.active = false;
			handJoint.stiff = false;
			handJoint.frequency = 0.1;
			handJoint.damping = 0.1;
			
			// Set up fixed time step logic.
			prevTimeMS = getTimer();
			simulationTime = 0.0;
			
			// Add key, mouse and frame listeners
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			
			// Add custom collision listeners
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, Bullet.BULLET_TYPE, Terrain.TERRAIN_TYPE, collisionWithTerrainCallback));
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, Bullet.BULLET_TYPE, Player.PLAYER_TYPE, collisionWithPlayerCallback));
		}
		
		private function tearDown():void
		{
			trace("tearDown");
			var player:Player = null;
			var i:uint = 0;
			
			space.clear();
			if (message != null)
			{
				stage.removeChild(message);
				message = null;
			}
			
			trace("tearDown: " + "# humans = " + humans.length);
			for (i = 0; i < humans.length; i++) // for each player
			{
				player = humans[i];
				player.kill();
			}
			trace("tearDown: " + "# humans = " + humans.length);
		}
		
		private function pause():void
		{
			paused = !paused;
		}
		
		private function enterFrameHandler(ev:Event):void
		{
			
			var curTimeMS:uint = getTimer();
			if (curTimeMS == prevTimeMS)
			{
				// No time has passed!
				return;
			}
			
			// Amount of time we need to try and simulate (in seconds).
			var deltaTime:Number = (curTimeMS - prevTimeMS) / 1000;
			// We cap this value so that if execution is paused we do
			// not end up trying to simulate 10 minutes at once.
			if (deltaTime > 0.05)
			{
				deltaTime = 0.05;
			}
			prevTimeMS = curTimeMS;
			
			if (!paused)
			{
				simulationTime += deltaTime;
			}
			
			while (!paused && space.elapsedTime < simulationTime)
			{
				space.step(1 / stage.frameRate);
				bodyMovedHandler();
				gameOverHandler();
			}
			
			if (!paused)
			{
				var i:int = -1;
				var player:Player = null;
				
				if (Math.random() > 0.95)
				{
					for (i = 1; i <= N; i++) // for AI each player
					{
						player = mapNumberPlayer[OFFSET + i];
						if (!player.snipeAi(stage.stageWidth, stage.stageHeight, terrains, humans))
						{
							player.randomAi(stage.stageWidth, stage.stageHeight);
						}
						
					}
				}
			}
			
			// Render Space to the debug draw.
			//   We first clear the debug screen,
			//   then draw the entire Space,
			//   and finally flush the draw calls to the screen.
			debug.clear();
			debug.draw(space);
			debug.flush();
		}
		
		private function mouseDownHandler(ev:MouseEvent):void
		{
			// Allocate a Vec2 from object pool.
			var mousePoint:Vec2 = Vec2.get(mouseX, mouseY);
			
			// Determine the set of Body's which are intersecting mouse point.
			// And search for any 'dynamic' type Body to begin dragging.
			var bodies:BodyList = space.bodiesUnderPoint(mousePoint);
			trace("mouseDownHandler: " + bodies.length + " bodies found");
			for (var i:int = 0; i < bodies.length; i++)
			{
				var body:Body = bodies.at(i);
				
				if (!body.isDynamic())
				{
					trace("mouseDownHandler: " + "skip static body");
					continue;
				}
				
				var player:Player = mapIdPlayer[body.id];
				trace("mouseDownHandler: " + "player #" + player.n);
				if (player != null && !player.isHuman)
				{
					trace("mouseDownHandler: " + "skip ai player");
					continue;
				}
				
				player.premove(mouseX, mouseY);
				player.movement.anchor2.set(body.worldPointToLocal(mousePoint));
				selected.push(player);
				
				break;
			}
			
			// Release Vec2 back to object pool.
			mousePoint.dispose();
		}
		
		private function mouseUpHandler(ev:MouseEvent):void
		{
			//handJoint.active = false;
			if (selected.length > 0)
			{
				var player:Player = selected.pop();
				player.move(ev.stageX, ev.stageY);
			}
		}
		
		private function keyDownHandler(ev:KeyboardEvent):void
		{
			//trace("keyDownHandler: " + ev.keyCode);
			var i:int = -1;
			var player:Player = null;
			
			if (ev.keyCode == 82)
			{ // 'R'
				tearDown();
				setUp();
			}
			
			if (ev.keyCode == 80)
			{ // 'P'
				pause();
			}
			
			for (i = 1; i <= N; i++) // for each player
			{
				if (ev.keyCode == 48 + i) // if number corresponding to this player has been pressed ('48' ~ 0)
				{
					player = mapNumberPlayer[i];
					player.fire();
				}
			}
		}
		
		private function bodyMovedHandler():void
		{
			trace("bodyMoveHandler");
			var player:Player = null;
			var i:int = 0;
			for (i = 1; i <= N; i++)
			{
				player = mapNumberPlayer[i];
				if (player != null && player.isHuman && !player.isDown())
				{
					player.body.userData.sprite.x = player.body.worldCOM.x;
					player.body.userData.sprite.y = player.body.worldCOM.y;
				}
			}
		}
		
		private function gameOverHandler():void
		{
			trace("gameOverHandler");
			var aiWin:Boolean = true;
			var humanWin:Boolean = true;
			var player:Player = null;
			var i:uint = 0;
			
			trace("gameOverHandler: " + "#humans = " + humans.length);
			for (i = 1; i <= N; i++)
			{
				player = mapNumberPlayer[i];
				if (player != null && !player.isDown())
				{
					aiWin = false;
					break;
				}
			}
			
			trace("gameOverHandler: " + "#bots = " + bots.length);
			for (i = 1 + OFFSET; i <= N + OFFSET; i++)
			{
				player = mapNumberPlayer[i];
				if (player != null && !player.isDown())
				{
					humanWin = false;
					break;
				}
			}
			
			if (humanWin)
			{
				trace("gameOverHandler: " + "humanWin");
				message = TextSpriteUtil.text2sprite("Human Wins!");
			}
			else if (aiWin)
			{
				trace("gameOverHandler: " + "aiWin");
				message = TextSpriteUtil.text2sprite("AI Wins!");
			}
			
			if (message != null)
			{
				message.x = stage.width / 2;
				message.y = stage.height / 2;
				stage.addChild(message);
				paused = true;
			}
		}
	}
}