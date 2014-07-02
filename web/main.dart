import 'dart:html';
import 'package:chrome/chrome_ext.dart' as chrome;

void main() {
  print('FOOBAR');
  window.alert(10);
  chrome.browserAction.onClick.listen(print);
}
