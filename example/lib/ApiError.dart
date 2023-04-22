class ApiError {
  String? message;
  ErrorMessage? errorMessage;
  List<ErrorMessage>? errorsMessages;

  ApiError.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if(json['errors'] is Map) {
      errorMessage = ErrorMessage.fromJson(json['errors']);
    }
    if(json['errors'] is List) {
      errorsMessages = <ErrorMessage>[];
      json['errors'].forEach((item) {
        errorsMessages?.add(ErrorMessage.fromJson(item));
      });
    }
  }
}

class ErrorMessage {
  String? message;
  String? error;

  ErrorMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    error = json['error'];
  }
}