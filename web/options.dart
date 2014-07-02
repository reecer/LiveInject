
import 'dart:html';
import 'package:chrome/chrome_ext.dart' as chrome;


void main(){
  var form = querySelector('#opt-form');
  var hostEl = querySelector('#host');

  hostEl.value = "foobar";
  print(form); print(hostEl);
}