import 'package:api_request/api_request.dart';
import 'package:flutter/material.dart';

class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  @override
  String toString() {
    return 'Post{' +
        ' id: $id,' +
        ' userId: $userId,' +
        ' title: $title,' +
        ' body: $body,' +
        '}';
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      body: map['body'],
    );
  }
}

class PostsResponse {
  List<Post>? posts;
  PostsResponse({this.posts});

  PostsResponse.fromList(List<dynamic>? data) {
    if (data is List) {
      this.posts = <Post>[];
      data.forEach((item) => this.posts?.add(Post.fromMap(item)));
    }
  }
}

class PostsRequestAction extends RequestAction<PostsResponse, ApiRequest> {
  PostsRequestAction() : super(null);

  @override
  void onError(ApiRequestError error) {
    print("Hi I Error On ${error.requestOptions?.uri.toString()}");
    super.onError(error);
  }

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
  String get path => 'postskjhlkjhlkh/{id}';

  @override
  void onError(ApiRequestError error) {
    print("Hi I Error On ${error.requestOptions?.uri.toString()}");
    super.onError(error);
  }

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<Post> get responseBuilder => (map) => Post.fromMap(map);
}

String yourMethodToGetToken() {
  return '1|hfkf9rfynfuynyf89erfynrfyepiruyfp';
}

Future<String> yourAysncMethodToGetToken() async {
  return '1|hfkf9rfynfuynyf89erfynrfyepiruyfp';
}

void main() {
  //config api requests;
  ApiRequestOptions.instance?.config(
      // set base url for all request
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      // set token as string api request action will with is if auth is required
      token: '1|hfkf9rfynfuynyf89erfynrfyepiruyfp',
      // we will call this method to get token in run time -- method must be return string
      getToken: () => yourMethodToGetToken(),
      // we will call this method to get token in run time -- method must be return Future<string>
      getAsyncToken: () => yourAysncMethodToGetToken(),
      // send default query params for all requests
      defaultQueryParameters: {'locale': 'ar'});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Api Request Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Api Request Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Post>? posts = <Post>[];

  @override
  initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    PostsResponse response = await PostsRequestAction().execute();
    setState(() {
      posts = response.posts;
    });
  }

  _getPostData(int? id) async {
    PostRequestAction action = PostRequestAction(PostApiRequest(id: id));
    action.onChange(onSuccess: (response) {
      print('response Post $response');
    }, onError: (error) {
      if (error is ApiRequestError) {
        print("response Error ${error.requestOptions?.uri.toString()}");
      }
    });
    action.onQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: (posts?.isNotEmpty ?? false)
            ? ListView.builder(
                itemCount: posts?.length,
                itemBuilder: (_, index) => ListTile(
                      title: Text(posts?[index].title ?? ''),
                      onTap: () => _getPostData(posts?[index].id),
                    ))
            : CircularProgressIndicator(),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
