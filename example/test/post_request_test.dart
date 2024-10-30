import 'package:api_request/api_request.dart';
import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test("test post api", () {
    //setup
    ApiRequestOptions.instance?.config(
      enableLog: true,

      /// set base url for all request
      baseUrl: 'https://jsonplaceholder.typicode.com/',
    );
    //action
    PostRequestAction()
        .test(TestResponse(
          data: {
            "id": 1,
            "title": "title",
            "body": "body",
            "userId": 1,
          },
          statusCode: 200,
        ))
        .execute()
        .then((value) {
      value?.fold((e) {
        print("xxxx ${e.toString()}");
      }, (data) {
        expect(1, data.userId);
        expect("title", data.title);
        expect(1, data.id);
        expect("body", data.body);
      });
    });
  });
}
