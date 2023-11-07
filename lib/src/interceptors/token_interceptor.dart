import 'package:api_request/api_request.dart';

class TokenInterceptor extends ApiInterceptor {
  final String _tag = 'token';
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    String? token = await ApiRequestOptions.instance?.getTokenString();
    print("configAuth token $token");
    if (token != null) {
      options.headers.addAll(
          {"Authorization": "${ApiRequestOptions.instance?.tokenType}$token"});
    }
    super.onRequest(options, handler);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  @override
  int get hashCode => _tag.hashCode;
}
