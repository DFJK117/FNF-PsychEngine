package backend.net;

import sys.net.Socket;
import sys.net.Host;
import sys.thread.Thread;
import sys.thread.Mutex;

/**
 * Doubao Engine - minimal LAN (P2P) networking for exactly two players.
 *
 * The HOST listens on a TCP port and accepts a single CLIENT (2-player room).
 * All socket blocking happens on worker threads; the game thread only calls
 * poll() once per frame and send() to push messages. Wire format is one short
 * UTF-8 line per message: "TYPE|key=value|key=value\n". Internal control events
 * use the reserved types __CONNECT__ / __DISCONNECT__.
 *
 * Identifiers are ASCII-only on purpose; localized text lives in the UI layer.
 */
class LanNet
{
	// connection mode (Haxe forbids nested enums, so use integer constants)
	public static inline var NONE:Int = 0;
	public static inline var HOST:Int = 1;
	public static inline var CLIENT:Int = 2;

	public static var mode:Int = NONE;
	public static var selfName:String = 'PLAYER';
	public static var peerName:String = '';
	/** 0 = host, 1 = client */
	public static var selfSlot:Int = 0;
	public static var connected:Bool = false;
	public static var defaultPort:Int = 27301;
	public static var localIP:String = '127.0.0.1';

	static var listener:Socket = null;
	static var conn:Socket = null;
	static var threads:Array<Thread> = [];
	static var mtx:Mutex = new Mutex();
	static var inbound:Array<String> = [];
	static var running:Bool = false;

	public static function setName(n:String)
	{
		n = trim(n);
		selfName = (n.length == 0) ? 'PLAYER' : n.toUpperCase();
	}

	static function trim(s:String):String
	{
		return s.split('\r').join('').split('\n').join('').trim();
	}

	/** Best-effort primary local IPv4 (falls back to loopback). */
	static function detectLocalIP():String
	{
		try
		{
			var h:Host = new Host(Host.localhost());
			if (h.ip != null)
			{
				var s:String = Std.string(h.ip);
				if (s.length > 0 && s != '0.0.0.0') return s;
			}
		}
		catch (e:Dynamic) {}
		return '127.0.0.1';
	}

	// ---------------- HOST ----------------
	public static function host(port:Int):Bool
	{
		reset();
		try
		{
			mode = HOST;
			selfSlot = 0;
			running = true;
			localIP = detectLocalIP();
			listener = new Socket();
			listener.bind(new Host('0.0.0.0'), port);
			listener.listen(1);
			threads.push(Thread.create(acceptLoop));
			return true;
		}
		catch (e:Dynamic)
		{
			reset();
			return false;
		}
	}

	static function acceptLoop()
	{
		while (running)
		{
			var c:Socket = null;
			try { c = listener.accept(); } catch (e:Dynamic) { break; }
			if (c == null) break;
			if (conn != null)
			{
				// room is full (max two players): reject extra joins
				sendRaw(c, 'FULL');
				try { c.close(); } catch (e2:Dynamic) {}
				continue;
			}
			conn = c;
			connected = true;
			pushIn('__CONNECT__');
			sendRaw(c, 'WELCOME|name=' + selfName + '|slot=1');
			readerLoop(c);
			// peer left: allow a fresh client to join afterwards
			conn = null;
			connected = false;
		}
	}

	// ---------------- CLIENT ----------------
	public static function join(ip:String, port:Int):Bool
	{
		reset();
		try
		{
			mode = CLIENT;
			selfSlot = 1;
			running = true;
			localIP = detectLocalIP();
			var s:Socket = new Socket();
			s.connect(new Host(trim(ip)), port);
			conn = s;
			connected = true;
			final captured:Socket = s;
			threads.push(Thread.create(function() readerLoop(captured)));
			send('HELLO|name=' + selfName);
			return true;
		}
		catch (e:Dynamic)
		{
			reset();
			return false;
		}
	}

	// ---------------- receive loop (worker thread) ----------------
	static function readerLoop(s:Socket)
	{
		var alive:Bool = true;
		while (running && alive)
		{
			var line:String = null;
			try { line = s.input.readLine(); }
			catch (e:Dynamic) { alive = false; }
			if (line == null) { alive = false; break; }
			line = trim(line);
			if (line.length > 0) pushIn(line);
		}
		connected = false;
		pushIn('__DISCONNECT__');
	}

	static function pushIn(m:String)
	{
		mtx.acquire();
		inbound.push(m);
		mtx.release();
	}

	/** Game thread: drain queued wire messages. */
	public static function poll():Array<String>
	{
		var out:Array<String> = [];
		mtx.acquire();
		for (m in inbound) out.push(m);
		inbound = [];
		mtx.release();
		return out;
	}

	// ---------------- send ----------------
	public static function send(msg:String)
	{
		if (conn != null) sendRaw(conn, msg);
	}

	static function sendRaw(s:Socket, msg:String)
	{
		try
		{
			s.output.writeString(msg + '\n');
			s.output.flush();
		}
		catch (e:Dynamic) {}
	}

	// ---------------- parsing helpers ----------------
	public static function typeOf(msg:String):String
	{
		var i:Int = msg.indexOf('|');
		return i < 0 ? msg : msg.substring(0, i);
	}

	public static function field(msg:String, key:String, def:String = ''):String
	{
		var parts:Array<String> = msg.split('|');
		var prefix:String = key + '=';
		for (p in parts)
			if (p.indexOf(prefix) == 0)
				return p.substring(prefix.length);
		return def;
	}

	public static function isHost():Bool { return mode == HOST; }
	public static function isActive():Bool { return mode != NONE; }

	public static function reset()
	{
		running = false;
		connected = false;
		peerName = '';
		try { if (conn != null) conn.close(); } catch (e:Dynamic) {}
		try { if (listener != null) listener.close(); } catch (e2:Dynamic) {}
		conn = null;
		listener = null;
		mtx.acquire();
		inbound = [];
		mtx.release();
		mode = NONE;
	}
}
