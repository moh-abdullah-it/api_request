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