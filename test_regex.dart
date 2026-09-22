void main() {
  String val = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNzJiMWMzMTMwOWEzMmEzMGQ4NmE1ZCIsImVTYWlsIjoicmFuYTY0MjRzaGVpaXg';
  String formatted = val.replaceAllMapped(RegExp(r'.{1,60}'), (match) => '${match.group(0)}\n').trim();
  print(formatted);
}
