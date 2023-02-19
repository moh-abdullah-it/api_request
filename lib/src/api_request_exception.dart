enum ApiExceptionType { client, server, custom }

@Deprecated('Pleas Use ActionRequestError')
class ApiRequestException {
  String message;
  int? statusCode;
  String? statusMessage;
  ApiExceptionType type;
  dynamic errors;
  ApiRequestException(
      {required this.message,
      required this.type,
      this.statusCode,
      this.statusMessage,
      this.errors});
}
