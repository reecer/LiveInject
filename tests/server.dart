import 'dart:io';
import 'dart:async';
import 'wip.dart';

void main(){
	Debugger.create().then((s){
		print('Serving');
		s.onConnection.listen((WipConnection wip){
			print("New debug connection");
			wip.debugger.enable();
			
			
			// wip.runtime.enable();
			// wip.runtime.evaluate("1+1").then((e){
			// 	print('Evaluation: ');
			// 	print(e);
			// });
		});
	});
}


class Debugger{
	HttpServer server;
	Map<int, WipConnection>	conns;

	StreamController<WipConnection> _onConnection = new StreamController.broadcast();

	Stream<WipConnection> get onConnection => _onConnection.stream;

	static int port = 4040;
	

	static Future<Debugger> create(){
		Completer comp = new Completer();
		var ip = '127.0.0.1';

		HttpServer.bind(ip, port).then((s) {
			Debugger dbg = new Debugger(s);
     		comp.complete(dbg);
	      	s.listen((HttpRequest req) {
	         	WebSocketTransformer.upgrade(req).then((ws){
	         		String route = req.uri.path;
	         		int tabId = int.parse(route.substring(1,route.length));
	         		dbg.add(tabId, ws);
	          	});
			});
	    });
		return comp.future;
	}

	Debugger(this.server) {
		conns = new Map<int, WipConnection>();
	}

	void add(int tabId, WebSocket ws){
 		print('Tab $tabId connected');
 		WipConnection wc = new WipConnection(ws);
 		wc.onClose.listen((e) {
 			conns.remove(tabId);
 			print('Removed tab $tabId');
		});
 		// Add to Map
 		conns[tabId] = wc;
 		// Emit stream
 		_onConnection.add(wc);		
	}

	void _onError(err){
		print('Error!\n$err');
	}
}