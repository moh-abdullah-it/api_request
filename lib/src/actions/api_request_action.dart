import 'package:api_request/api_request.dart';

abstract class ApiRequestAction<T> extends RequestAction<T, ApiRequest> {
  ApiRequestAction() : super(null);
}
