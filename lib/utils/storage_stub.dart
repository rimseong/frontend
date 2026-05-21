final _map = <String, String>{};

String getLocalStorage(String key) => _map[key] ?? '';
void setLocalStorage(String key, String value) => _map[key] = value;
