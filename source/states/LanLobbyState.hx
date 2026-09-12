package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ClientPrefs;
import backend.net.LanNet;

/**
 * Doubao Engine LAN lobby. Flow:
 *   MENU  -> HOST ROOM / JOIN ROOM / PLAYER NAME / BACK
 *   JOIN  -> type the host IPv4, ENTER to connect
 *   NAME  -> type your player name
 *   ROOM  -> two-player room; host starts, client waits.
 * All on-screen text is English; identifiers are ASCII only.
 */
class LanLobbyState extends MusicBeatState
{
	enum Page { MENU; JOIN; NAME; ROOM; }

	var page:Page = MENU;
	var menuItems:Array<String> = ['HOST ROOM', 'JOIN ROOM', 'PLAYER NAME', 'BACK'];
	var curSelected:Int = 0;

	var titleTxt:FlxText;
	var listTxt:FlxText;
	var hintTxt:FlxText;
	var statusTxt:FlxText;

	var ipBuffer:String = '';
	var nameBuffer:String = '';
	var errorMsg:String = '';

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		titleTxt = new FlxText(0, 70, FlxG.width, 'LAN MULTIPLAYER', 48);
		titleTxt.screenCenter(X);
		titleTxt.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(titleTxt);

		listTxt = new FlxText(0, 210, FlxG.width, '', 32);
		listTxt.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(listTxt);

		statusTxt = new FlxText(0, 480, FlxG.width, '', 26);
		statusTxt.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, flixel.text.FlxTextAlign.CENTER, flixel.text.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(statusTxt);

		hintTxt = new FlxText(0, 630, FlxG.width, '', 22);
		hintTxt.setFormat(Paths.font('vcr.ttf'), 22, 0xFFcfcfcf, flixel.text.FlxTextAlign.CENTER);
		add(hintTxt);

		LanNet.setName(ClientPrefs.data.lanPlayerName);
		redraw();
	}

	function redraw()
	{
		switch (page)
		{
			case MENU:
				var s:String = '';
				for (i => item in menuItems)
					s += (i == curSelected ? '> ' : '  ') + item + '\n';
				listTxt.text = s;
				titleTxt.text = 'LAN MULTIPLAYER';
				statusTxt.text = 'YOU: ' + LanNet.selfName;
				hintTxt.text = 'UP/DOWN select   ENTER confirm   ESC back';

			case JOIN:
				titleTxt.text = 'JOIN ROOM';
				listTxt.text = 'HOST IP: ' + ipBuffer + '_';
				statusTxt.text = (errorMsg.length > 0 ? errorMsg : 'type host IPv4 (example 192.168.1.10)');
				hintTxt.text = '0-9 and . to type   BACKSPACE delete   ENTER join   ESC back';

			case NAME:
				titleTxt.text = 'PLAYER NAME';
				listTxt.text = 'NAME: ' + nameBuffer + '_';
				statusTxt.text = 'A-Z / 0-9, max 10 chars';
				hintTxt.text = 'type your name   ENTER save   ESC back';

			case ROOM:
				titleTxt.text = LanNet.isHost() ? 'ROOM (HOST)' : 'ROOM (CLIENT)';
				var r:String = 'YOU (' + LanNet.selfName + ')\n';
				r += (LanNet.connected ? 'PEER: ' + (LanNet.peerName.length > 0 ? LanNet.peerName : 'connected') : 'WAITING FOR PEER...') + '\n';
				if (LanNet.isHost())
				{
					r += '\nROOM IP: ' + LanNet.localIP + '   PORT: ' + ClientPrefs.data.lanPort;
					r += '\n\n' + (LanNet.connected ? 'ENTER -> SELECT SONG AND START' : 'waiting for the other player to join...');
				}
				else
					r += '\n\nWAITING FOR HOST TO PICK A SONG...';
				listTxt.text = r;
				statusTxt.text = errorMsg;
				hintTxt.text = 'ESC leave room';
		}
	}

	function keyToChar(code:Int, allowDot:Bool):String
	{
		if (code >= 65 && code <= 90) return String.fromCharCode(code);  // A-Z
		if (code >= 48 && code <= 57) return String.fromCharCode(code);  // top row 0-9
		if (code >= 96 && code <= 105) return Std.string(code - 96);     // numpad 0-9
		if (allowDot && (code == 190 || code == 110)) return '.';
		return '';
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		handleNet();

		switch (page)
		{
			case MENU: updateMenu();
			case JOIN: updateTyping(true);
			case NAME: updateTyping(false);
			case ROOM: updateRoom();
		}
	}

	function updateMenu()
	{
		if (controls.UI_UP_P) { curSelected = (curSelected + menuItems.length - 1) % menuItems.length; FlxG.sound.play(Paths.sound('scrollMenu')); redraw(); }
		else if (controls.UI_DOWN_P) { curSelected = (curSelected + 1) % menuItems.length; FlxG.sound.play(Paths.sound('scrollMenu')); redraw(); }

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			switch (curSelected)
			{
				case 0:
					errorMsg = '';
					if (LanNet.host(ClientPrefs.data.lanPort)) page = Page.ROOM;
					else errorMsg = 'FAILED TO HOST (port in use?)';
					redraw();
				case 1:
					errorMsg = ''; ipBuffer = ''; page = Page.JOIN; redraw();
				case 2:
					nameBuffer = LanNet.selfName; page = Page.NAME; redraw();
				case 3: MusicBeatState.switchState(new MainMenuState());
			}
		}
		if (controls.BACK) MusicBeatState.switchState(new MainMenuState());
	}

	function updateTyping(allowDot:Bool)
	{
		var code:Int = FlxG.keys.firstJustPressed();
		if (code >= 0)
		{
			var ch:String = keyToChar(code, allowDot);
			var maxLen:Int = allowDot ? 20 : 10;
			var buf:String = allowDot ? ipBuffer : nameBuffer;
			if (ch.length > 0 && buf.length < maxLen)
			{
				buf += ch;
				if (allowDot) ipBuffer = buf; else nameBuffer = buf;
				redraw();
			}
		}
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			if (allowDot) { if (ipBuffer.length > 0) ipBuffer = ipBuffer.substring(0, ipBuffer.length - 1); }
			else { if (nameBuffer.length > 0) nameBuffer = nameBuffer.substring(0, nameBuffer.length - 1); }
			redraw();
		}
		if (controls.ACCEPT)
		{
			if (allowDot)
			{
				if (ipBuffer.length > 0 && LanNet.join(ipBuffer, ClientPrefs.data.lanPort))
				{
					errorMsg = ''; page = Page.ROOM;
				}
				else errorMsg = 'CANNOT CONNECT TO ' + ipBuffer;
				redraw();
			}
			else
			{
				LanNet.setName(nameBuffer);
				ClientPrefs.data.lanPlayerName = LanNet.selfName;
				ClientPrefs.saveSettings();
				page = Page.MENU; redraw();
			}
		}
		if (controls.BACK) { page = Page.MENU; errorMsg = ''; redraw(); }
	}

	function updateRoom()
	{
		if (LanNet.isHost() && LanNet.connected && controls.ACCEPT)
		{
			// host picks the song in Freeplay; song choice is sent to the client there
			ClientPrefs.data.lanEnabled = true;
			ClientPrefs.data.doubaoTwoPlayer = true;
			backend.DoubaoConfig.syncFromPrefs();
			MusicBeatState.switchState(new FreeplayState());
		}
		if (controls.BACK)
		{
			LanNet.reset();
			ClientPrefs.data.lanEnabled = false;
			page = Page.MENU; redraw();
		}
	}

	function handleNet()
	{
		if (!LanNet.isActive()) return;
		var changed:Bool = false;
		for (msg in LanNet.poll())
		{
			switch (LanNet.typeOf(msg))
			{
				case '__CONNECT__': changed = true;
				case '__DISCONNECT__':
					errorMsg = 'PEER DISCONNECTED';
					LanNet.connected = false; changed = true;
				case 'HELLO':
					LanNet.peerName = LanNet.field(msg, 'name', 'PLAYER');
					if (LanNet.isHost()) LanNet.send('PEER|name=' + LanNet.selfName);
					changed = true;
				case 'WELCOME':
					LanNet.peerName = LanNet.field(msg, 'name', 'HOST'); changed = true;
				case 'PEER':
					LanNet.peerName = LanNet.field(msg, 'name', 'PEER'); changed = true;
				case 'FULL':
					errorMsg = 'ROOM IS FULL'; changed = true;
				default:
			}
		}
		if (changed && page == Page.ROOM) redraw();
	}
}
