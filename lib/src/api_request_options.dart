import '../api_request.dart';

typedef GetOption<T> = T Function();
typedef GetAsyncOption<T> = Future<T> Function();

class ApiRequestOptions {
  /// Singleton for ApiRequestOptions by create one instance
  static ApiRequestOptions? _instance;

  /// Singleton for ApiRequestOptions by create one instance
  static ApiRequestOptions? get instance {
    if (_instance == null) {
      _instance = ApiRequestOptions();
    }
    return _instance;
  }

  /// list of global interceptors
  List<ApiInterceptor> interceptors = <ApiInterceptor>[];

  /// to disable log set it to false
  bool enableLog = true;

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioError] with [DioErrorType.connectTimeout] type
  ///  when time out.
  int? connectTimeout = 0;

  /// for Bearer token type.
  static String bearer = 'Bearer ';

  /// set tokenType for types
  String? tokenType = '';

  /// base url for your api
  /// You can set it ApiRequestOptions.instance.baseUrl = 'https://example.com';
  late String baseUrl;

  /// access token
  String? token;

  /// get access token use callback function
  GetOption<String?>? getToken;

  /// write what you wont if your server response unauthenticated with status code 401
  GetOption? unauthenticated;

  /// get access token use async callback function
  GetAsyncOption<String?>? getAsyncToken;

  // set default query parameters to url
  late Map<String, dynamic> defaultQueryParameters = {};

  void config(
      {String? baseUrl,
      String? token,
      GetOption<String?>? getToken,
      GetAsyncOption<String?>? getAsyncToken,
      GetOption? unauthenticated,
      Map<String, dynamic>? defaultQueryParameters,
      String? tokenType,
      int? connectTimeout,
      bool? enableLog,
      List<ApiInterceptor>? interceptors}) async {
    this.baseUrl = baseUrl ?? this.baseUrl;
    this.token = token ?? this.token;
    this.getToken = getToken ?? this.getToken;
    this.getAsyncToken = getAsyncToken ?? this.getAsyncToken;
    this.unauthenticated = unauthenticated ?? this.unauthenticated;

    if (this.defaultQueryParameters.isNotEmpty) {
      this.defaultQueryParameters.addAll(defaultQueryParameters ?? {});
    } else {
      this.defaultQueryParameters =
          defaultQueryParameters ?? this.defaultQueryParameters;
    }

    if (this.interceptors.isNotEmpty) {
      this.interceptors.addAll(interceptors ?? []);
    } else {
      this.interceptors = interceptors ?? this.interceptors;
    }

    this.tokenType = tokenType ?? this.tokenType;
    this.connectTimeout = connectTimeout ?? this.connectTimeout;
    this.enableLog = enableLog ?? this.enableLog;
  }
}
