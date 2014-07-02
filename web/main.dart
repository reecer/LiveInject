import 'dart:html';
import 'dart:convert';
import 'package:chrome/chrome_ext.dart' as chrome;

void main() {
  print("Initializing LiveInject...");
  var controller = new Controller();
  chrome.browserAction.onClicked.listen(controller.add);
}

class WS extends WebSocket{
  get connected() => return this.readyState === this.OPEN;
  
}

class Controller{
  WebSocket ws;
  List<chrome.Tab> tabs;
  
  void add(chrome.Tab tab){
    if(this.connected)
      this.tabs.add(tab);
    else 
      print("No server connected");
  }
}