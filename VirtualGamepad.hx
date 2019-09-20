package arm;

import iron.Trait;
import iron.system.Input;
import iron.math.Vec2;

typedef Pos = { x: Int, y: Int }
typedef Touch = {
	index:Int,
	pos:Pos
}
typedef Button = {
	button:Int,
	pos:Pos
}

@:access(iron.system.Input)
@:access(iron.system.Gamepad)
class VirtualGamepad extends Trait {

	var gamepad:Gamepad;

	var lPad:Pos = {x:0,y:0};
	var rPad:Pos = {x:0,y:0};

	var lStick:Pos = {x:0,y:0};
	var rStick:Pos = {x:0,y:0};
	var lStickLast:Pos = {x:0,y:0};
	var rStickLast:Pos = {x:0,y:0};

	var leftLocked = -1;
	var rightLocked = -1;

	var button_pos:Pos = {x:0,y:0};

	public var buttonOffset = 120;
	public var buttonRadius = 50;
	@prop
	public var stickRadius = 100; // stickRadius
	@prop
	public var stickOffset = 40; // stickOffset

	var touches:Array<Touch> = [];
	var buttons:Array<Button> = [];

	public function new() {
		super();

		notifyOnInit(function() {

			gamepad = new Gamepad(0, true);
			Input.gamepads.push(gamepad);

			var surface = kha.input.Surface.get();
			if (surface != null) surface.notify(touchStart, touchEnd, touchMove);

			for (i in 0...4)
			{
				var button:Button = { button:i, pos:{x:0, y:0} };
				buttons.push(button);
			}

			notifyOnUpdate(update);
			notifyOnRender2D(render2D);
		});
	}

	function touchStart(index:Int, x:Int, y:Int) {
		var touch:Touch = {
			index: index,
			pos: {x: x, y: y}
		}

		touches.push(touch);
		// check for pad
		checkForPads(x,y,index);
		// check for button
		checkForButtons(x,y,1);
	}

	function touchEnd(index:Int, x:Int, y:Int) {
		for(touch in touches){
			if(touch.index == index){
				touches.remove(touch);
				break;
			}
		}
		checkForPads(x,y,-1);

		checkForButtons(x,y,0);

		if(leftLocked == index) leftLocked = -1;
		if(rightLocked == index) rightLocked = -1;
	}

	function touchMove(index:Int, x:Int, y:Int) {
		for(touch in touches){
			if(touch.index == index){
				touch.pos.x = x;
				touch.pos.y = y;
				break;
			}
		}
		checkForButtons(x,y,1);
	}

	function checkForPads(x:Int,y:Int,index:Int){
		if (Vec2.distancef(x, y, lPad.x, lPad.y) <= stickRadius) {
			leftLocked = index;
			return;
		}
		
		if (Vec2.distancef(x, y, rPad.x, rPad.y) <= stickRadius) {
			rightLocked = index;
			return;
		}
	}

	function checkForButtons(x:Int,y:Int,value:Int){
		for (button in buttons){
			if (Vec2.distancef(x, y, button.pos.x, button.pos.y) <= buttonRadius) {
				gamepad.buttonListener(button.button, value);
				break;
			}
		}
	}

	function getTouch(index:Int):Touch{
		for(touch in touches)
		{
			if(touch.index == index)
				return touch;
		}
		return null;
	}

	function moveStick(padValue:Int, padX:Int, padY:Int):Pos{
		var stick:Pos = {x:0,y:0};
		if (padValue != -1) {
			var touch = getTouch(padValue);

			stick.x = Std.int(touch.pos.x - padX);
			stick.y = Std.int(touch.pos.y - padY);

			var l = Math.sqrt(stick.x * stick.x + stick.y * stick.y);
			if (l > stickRadius) {
				var x = stickRadius * (stick.x / l);
				var y = stickRadius * (stick.y / l);
				stick.x = Std.int(x);
				stick.y = Std.int(y);
			}
		}
		return stick;
	}

	function update() {
		lPad.x = stickRadius + stickOffset;
		rPad.x = iron.App.w() - stickRadius - stickOffset;
		lPad.y = rPad.y = iron.App.h() - stickRadius - stickOffset;

		button_pos.x = iron.App.w() - buttonRadius - buttonOffset;
		button_pos.y = iron.App.h() - buttonRadius - buttonOffset - 150;

		var bindex = 0;
		for (button in buttons){
			button.pos.x = button_pos.x - (120 * bindex);
			button.pos.y = button_pos.y;
			bindex++;
		}

		lStick = moveStick(leftLocked,lPad.x,lPad.y);
		rStick = moveStick(rightLocked,rPad.x,rPad.y);

		if (lStick.x != lStickLast.x)
			gamepad.axisListener(0, lStick.x / stickRadius);
		if (lStick.y != lStickLast.y)
			gamepad.axisListener(1, lStick.y / stickRadius);
		if (rStick.x != rStickLast.x)
			gamepad.axisListener(2, rStick.x / stickRadius);
		if (rStick.y != rStickLast.x)
			gamepad.axisListener(3, rStick.y / stickRadius);

		lStickLast = lStick;
		rStickLast = rStick;
	}

	function render2D(g:kha.graphics2.Graphics) {
		g.color = 0xffaaaaaa;

		kha.graphics2.GraphicsExtension.fillCircle(g, lPad.x, lPad.y, stickRadius);
		kha.graphics2.GraphicsExtension.fillCircle(g, rPad.x, rPad.y, stickRadius);

		g.color = 0xffaaaaaa;

		for (button in buttons)
			kha.graphics2.GraphicsExtension.fillCircle(g, button.pos.x, button.pos.y, buttonRadius);

		var r2 = Std.int(stickRadius / 2.2);
		g.color = 0xffffff44;
		kha.graphics2.GraphicsExtension.fillCircle(g, lPad.x + lStick.x, lPad.y + lStick.y, r2);
		kha.graphics2.GraphicsExtension.fillCircle(g, rPad.x + rStick.x, rPad.y + rStick.y, r2);

		g.color = 0xffffffff;
	}
}
