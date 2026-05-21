import 'dart:html' as html;

String getLocalStorage(String key) => html.window.localStorage[key] ?? '';
void setLocalStorage(String key, String value) =>
    html.window.localStorage[key] = value;
