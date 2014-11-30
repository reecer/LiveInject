import 'dart:html';
import 'dart:async';
import 'dart:convert' show JSON;
import 'package:chrome/chrome_ext.dart' as chrome;

void main() {
    var controller = new Controller();
    chrome.browserAction.onClicked.listen((tab){
        controller.add(tab);
    });
}


class Controller{
    List<ClientConnection> tabs;
    
    Controller(){
        tabs = new List<ClientConnection>();
        chrome.debugger.onDetach.listen(_debugDetach);
        chrome.debugger.onEvent.listen(_debugEvent);
        chrome.tabs.onUpdated.listen((e){
            var cc = clientById(e.tabId);
            if(cc is ClientConnection && cc.connected){
                cc.setState("running");
            }
        });
    }
    

    bool isConnected(chrome.Tab tab) => clientById(tab.id) != null;

    ClientConnection clientById(int tabId){
        ClientConnection cc;
        if(this.tabs.length > 0){
            try{ 
                cc = this.tabs.singleWhere((t) => t.id == tabId);
            }on StateError catch(e){ }
        }
        return cc;
    }

    void add(chrome.Tab tab){
        if(this.isConnected(tab)){
            clientById(tab.id)
                ..detach()
                ..close();
        }else{
            var cc = new ClientConnection(tab);
            cc.onOpen.listen((_){
                cc.setState("running");
                tabs.add(cc);
                print("Client opened ${cc.id}");
            });
            cc.onClose.listen((_){
                cc.setState("stopped");
                tabs.remove(cc);
                print("Client closed ${cc.id}");
            });
        }
    }

    void _debugEvent(chrome.onEventEvent e) => 
        clientById(e.source.tabId).sendMessage({ "method": e.method, "params": e.params });
    void _debugDetach(chrome.OnDetachEvent e){
        var cc = clientById(e.source.tabId);
        if(cc is ClientConnection){
            cc.attached = false;
            cc.close();
        }
    }
}

class ClientConnection{
    final String host = "ws://localhost:4040/";
    final String protocol = "1.0";

    StreamController _closed = new StreamController.broadcast();
    StreamController _opened = new StreamController.broadcast();

    Stream get onClose => _closed.stream;
    Stream get onOpen => _opened.stream;

    // Tab being used
    chrome.Tab tab;

    // Tab's tabId
    int id; 

    // WS client
    WebSocket ws;

    Map<String, int> debuggee;

    bool attached;


    ClientConnection(this.tab){
        this.id = this.tab.id;
        this.debuggee = { "tabId": id };
        try{
            this.ws = new WebSocket(host + this.id.toString())
                ..onOpen.listen((e){
                    attach();
                    _opened.add(null);
                    print('Synced tab $debuggee');
                })
                ..onMessage.listen((e){
                    var msg = JSON.decode(e.data);
                    print("MSG: $msg");
                    try{
                        chrome.debugger.sendCommand(debuggee, msg["method"], msg["params"]).then((e){
                            sendMessage(e, msg["id"]);
                        });
                    }catch(e){}
                })
                ..onClose.listen(_onClose);
        }catch(e){
            close();
        }
    }

    void attach(){
        sendMessage({
            "method": 'Tab.attached', 
            "params": {
                "title": this.tab.title,
                "url"  : this.tab.url,
                "id"   : this.tab.id
            }
        });
        chrome.debugger.attach(this.debuggee, protocol);
        attached = true;
    }

    bool get connected => ws != null && ws.readyState == WebSocket.OPEN;

    void sendMessage(m, [int eventId]){
        if(m.length > 0){
            if(eventId != null)
                m["id"] = eventId;
            m = JSON.encode(m);
            this.ws.sendString(m);
            print("SENT: $m");
        }
    }
    void detach() => chrome.debugger.detach(debuggee);
    
    void close() => ws.close();

    void _onClose(e){
        print('WS closed: $e');
        if(attached) detach();
        _closed.add(null);
    }
    /*
        BADGE SETTINGS
     */
    void setState(String iconName){
        chrome.browserAction.setIcon({"path": "icons/$iconName.png", "tabId": this.id});
    } 
}


