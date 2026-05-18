// Stub classes for dart:html to avoid compilation errors on non-web platforms.

class Blob {
  Blob(List<dynamic> parts, String type);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  String? href;
  void setAttribute(String name, String value) {}
  void click() {}
}
