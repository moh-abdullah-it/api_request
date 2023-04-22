import 'package:api_request/api_request.dart';

abstract class ApiRequestAction<T, E> extends RequestAction<T, E, ApiRequest> {
  ApiRequestAction() : super(null);
}
