# Api Request

⚡ Classes that take care of one specific task.

This package introduces a new way of organising the logic of your flutter api applications
by focusing on the actions your api provide.

Instead of creating service for all api's, it allows you to create a dart class that handles a specific api request
and execute that class.

## Why
* Help developers follow single responsibility principle (SRP)
* Small dedicated classes makes the code easier to test
* Action classes can be callable from multiple places in your app
* Small dedicated classes really pay off in complex apps
* Global Config

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
  /// global config api requests;
  ApiRequestOptions.instance?.config(
    /// set base url for all request
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      /// set token type to 'Bearer '
      tokenType: ApiRequestOptions.bearer,
      /// set token as string api request action will with is if auth is required
      token: '1|test-token',
      /// we will call this method to get token in run time -- method must be return string
      getToken: () => yourMethodToGetToken(),
      /// we will call this method to get token in run time -- method must be return Future<string>
      getAsyncToken: () => yourAysncMethodToGetToken(),
      /// send default query params for all requests
      defaultQueryParameters: {'locale': 'ar'},
      /// send default interceptors for all requests
      interceptors: [],
      /// enableLog for request && response default true
      enableLog: true,
    
  );
  runApp(MyApp());
}

```
* and from any pace of your code you can change config

## ApiRequestAction Action
that is sample call api request by create class extends by `ApiRequestAction<YourHandelResponse>`
```dart
class PostsRequestAction extends ApiRequestAction<PostsResponse> {
  
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

## Call ApiRequestAction
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

## Use ApiRequest with RequestAction
```dart
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
class PostRequestAction extends ApiRequestAction<Post> {
  final int? id;

  PostRequestAction({this.id});
  
  @override
  Map<String, dynamic> toMap() => {
    'id': this.id,
  };

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

## Action Events
listing for action events:
* onInit
* onStart
* onSuccess
* onError

```dart
class PostRequestAction extends ApiRequestAction<Post> {
  /// action implement

  @override
  Function get onInit => () => print('Action Init');

  @override
  Function get onStart => () => print('Action Start');

  @override
  SuccessHandler<Post> get onSuccess =>
          (post) => print('Action Success ${post?.id}');

  @override
  ErrorHandler get onError => (error) => print('Action Error ${error.message}');
}
```

## onQueue
if you don't wait result from action , run action `onQueue` and listen by `subscribe`:
* `onSuccess`
* `OnError`
* `OnDone`
```dart
PostRequestAction action = PostRequestAction(id: id);
// use action events setter
action.onStart = () => print('Action Start Form Ui');
action.onSuccess = (post) => print('Action Success Form Ui ${post?.id}');
action.onError = (error) => print('Action Error Form Ui ${error.message}');

// use action subscribe
action.subscribe(
    onSuccess: (response) {
      print('response Post Id: ${response.id}');
    },
    onError: (error) {
    if (error is ApiRequestError) {
      print("response Error ${error.requestOptions?.uri.toString()}");
    }
    },
    onDone: () {
      print("Hi I done");
    },
);
action.onQueue();
```
## Performance Report
get performance report for all called actions
* print in console log
```dart
  print("${ApiRequestPerformance.instance.toString()}");
```
* Map Reports
```dart
  Map<String?, PerformanceReport?> actionsReport = ApiRequestPerformance.instance?.actionsReport
```