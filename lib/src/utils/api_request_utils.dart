class ApiRequestUtils {
  static Map<String, dynamic> handleDynamicPathWithData(
      String path, Map<String, dynamic> map) {
    Map<String, dynamic> newData = {};
    map.keys.forEach((key) {
      if (path.contains('{$key}')) {
        path = path.replaceFirst('{$key}', map[key].toString());
      } else {
        newData[key] = map[key];
      }
    });
    return {'path': path, 'data': newData};
  }
}
