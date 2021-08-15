# Api Request

⚡ Classes that take care of one specific task.

This package introduces a new way of organising the logic of your flutter api applications
by focusing on the actions your api provide.

Instead of creating service for all api's, it allows you to create a dart class that handles a specific api request
and execute that class.

## Adding Api Request to your project

In your project's `pubspec.yaml` file,

* Add *api_request* latest version to your *dependencies*.

```yaml
# pubspec.yaml

dependencies:
  api_request: ^<latest version>

```

## Config
```dart
import 'package:api_request/api_request.dart';

void main() {
  //global config api requests;
  ApiRequestOptions.instance?.config(
    // set base url for all request
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      // set token as string api request action will with is if auth is required
      token: '1|test-token',
      // we will call this method to get token in run time -- method must be return string
      getToken: () => yourMethodToGetToken(),
      // we will call this method to get token in run time -- method must be return Future<string>
      getAsyncToken: () => yourAysncMethodToGetToken(),
      // send default query params for all requests
      defaultQueryParameters: {'locale': 'ar'}
  );
  runApp(MyApp());
}

```
* and from any pace of your code you can change config

## Request Action
that is action  will execute to call api
```dart
class PostsRequestAction extends RequestAction<PostsResponse, ApiRequest> {
  PostsRequestAction() : super();

  @override
  bool get authRequired => false;

  @override
  String get path => 'posts';

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<PostsResponse> get responseBuilder =>
          (list) => PostsResponse.fromList(list);
}
```

## Call PostsRequestAction
```dart
  PostsResponse response = await PostsRequestAction().execute();
```

## ApiRequest
when need to send data with this request mix your class with *ApiRequest*
```dart
class LoginApiRequest with ApiRequest{
  final String email;
  final String password;
  
  LoginApiRequest({required this.email,required this.password});

  @override
  Map<String, dynamic> toMap() => {
    'email': this.email, 'password': this.password
  };
}
```

## Use ApiRequest with Action
```dart
class AuthResponse{
  final int? status;
  final String? message;
  final String? accessToken;

  AuthResponse({this.status, this.message, this.accessToken});

  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      status: map['status'] as int,
      message: map['message'] as String,
      accessToken: map['accessToken'] as String,
    );
  }
}

class LoginRequestAction extends RequestAction<AuthResponse, LoginApiRequest>{
  
  LoginRequestAction(LoginApiRequest request) : super(request);
  
  @override
  bool get authRequired => false;

  @override
  String get path => 'login';

  @override
  RequestMethod get method => RequestMethod.POST;

  @override
  ResponseBuilder<AuthResponse> get responseBuilder => (map) => AuthResponse.fromMap(map);

}
```

## Call LoginRequestAction Action
```dart
  LoginApiRequest request = LoginApiRequest(
    email: 'test@test.com',
    password: '123123'
  );
  AuthResponse response = await LoginRequestAction(request).execute();
```

## Dynamic Path
 * example to send data in path you need to add vars in path like this */{var}/*
 * and in your request data add var name with your value like this:
```dart
class PostApiRequest with ApiRequest {
  final int? id;
  PostApiRequest({this.id});
  @override
  Map<String, dynamic> toMap() => {
        'id': this.id,
      };
}

class PostRequestAction extends RequestAction<Post, PostApiRequest> {
  PostRequestAction(PostApiRequest request) : super(request);

  @override
  bool get authRequired => false;

  @override
  String get path => 'posts/{id}';

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<Post> get responseBuilder => (map) => Post.fromMap(map);
}
```