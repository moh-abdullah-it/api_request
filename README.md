# Api Request

Api Request is an how to use api request action in flutter with dio client;

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
``` dart
class PostsRequestAction extends RequestAction<PostsResponse, ApiRequest> {
  @override
  bool get authRequired => false; // or true if this action need to auth we will send access_token

    // one method for this action
  @override
  Future<PostsResponse> execute({ApiRequest? request}) async {
    return PostsResponse.fromList(await get());
  }
  
  // path for this api request
  @override
  String get path => 'posts';
}
```
## Call Request Action
``` dart
PostsResponse response = await PostsRequestAction().execute();
```

## ApiRequest
when need to send data with this request create *ApiRequest*
``` dart
class LoginApiRequest extends ApiRequest{
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
``` dart
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
  @override
  bool get authRequired => false;

  @override
  Future<AuthResponse> execute({LoginApiRequest? request}) async {
    return AuthResponse.fromMap(await post(request));
  }

  @override
  String get path => 'login';
  
}
```
## Call Request Action
``` dart
AuthResponse response = await LoginRequestAction().execute(LoginApiRequest(
email: 'test@test.com',
password: '123123'
));
```
## Dynamic Path
 * example to send data in path you need to add vars in path like this */{var}/*
 * and in your request data add var name with your value like this:
```dart
class PostApiRequest extends ApiRequest {
  final int? id;
  PostApiRequest({this.id});
  @override
  Map<String, dynamic> toMap() => {
        'id': this.id,
      };
}

class PostRequestAction extends RequestAction<Post, PostApiRequest> {
  @override
  bool get authRequired => false;

  @override
  Future<Post> execute({PostApiRequest? request}) async {
    return Post.fromMap(await get(request));
  }

  @override
  String get path => 'posts/{id}';
}
```