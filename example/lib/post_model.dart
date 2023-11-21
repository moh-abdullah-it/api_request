import 'package:api_request/api_request.dart';

class PostModel extends ApiResource {

  int? id;
  String? title;

  PostModel.fromMap(Map<String, dynamic> map) {
   id = map['id'];
   title = map['title'];
  }

  @override
  String get path => '/posts';
}
