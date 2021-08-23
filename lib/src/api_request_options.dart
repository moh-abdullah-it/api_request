typedef GetOption<T> = T Function();
typedef GetAsyncOption<T> = Future<T> Function();

class ApiRequestOptions {
  static String bearer = 'Bearer ';
  String? tokenType = '';
  static ApiRequestOptions? get instance {
    if (_instance == null) {
      _instance = ApiRequestOptions();
    }
    return _instance;
  }

  static ApiRequestOptions? _instance;

  /// base url for your api
  /// You can set it ApiRequestOptions.instance.baseUrl = 'https://example.com';
  late String baseUrl;

  /// access token
  String? token;

  /// get access token use callback function
  GetOption<String?>? getToken;

  /// get access token use callback function
  GetOption? unauthenticated;

  /// get access token use async callback function
  GetAsyncOption<String?>? getAsyncToken;

  late Map<String, dynamic> defaultQueryParameters = {};

  void config(
      {String? baseUrl,
      String? token,
      GetOption<String?>? getToken,
      GetAsyncOption<String?>? getAsyncToken,
      GetOption? unauthenticated,
      Map<String, dynamic>? defaultQueryParameters,
      String? tokenType}) async {
    this.baseUrl = baseUrl ?? this.baseUrl;
    this.token = token ?? this.token;
    this.getToken = getToken ?? this.getToken;
    this.getAsyncToken = getAsyncToken ?? this.getAsyncToken;
    this.unauthenticated = unauthenticated ?? this.unauthenticated;
    this.defaultQueryParameters =
        defaultQueryParameters ?? this.defaultQueryParameters;
    this.tokenType = tokenType ?? this.tokenType;
  }
}
