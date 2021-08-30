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

class PostRequestAction extends ApiRequestAction<Post> {
  final int? id;
  PostRequestAction({this.id});

  @override
  bool get authRequired => false;

  @override
  String get path => 'posts/$id';

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<Post> get responseBuilder => (map) => Post.fromMap(map);

  /*@override
  Function get onInit => () => print('Action Init');

  @override
  Function get onStart => () => print('Action Start');

  @override
  SuccessHandler<Post> get onSuccess =>
      (post) => print('Action Success ${post?.id}');

  @override
  ErrorHandler get onError => (error) => print('Action Error ${error.message}');*/
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
    /// set base url for all request
    baseUrl: 'https://jsonplaceholder.typicode.com/',

    /// set token type to 'Bearer '
    tokenType: ApiRequestOptions.bearer,

    /// set token as string api request action will with is if auth is required
    token: '1|hfkf9rfynfuynyf89erfynrfyepiruyfp',

    /// we will call this method to get token in run time -- method must be return string
    getToken: () => yourMethodToGetToken(),

    /// we will call this method to get token in run time -- method must be return Future<string>
    getAsyncToken: () => yourAysncMethodToGetToken(),

    /// send default query params for all requests
    //defaultQueryParameters: {'locale': 'ar'},
  );
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
  final PostsRequestAction? action = PostsRequestAction();

  @override
  initState() {
    super.initState();
    action?.onQueue();
  }

  _getPostData(int? id) {
    PostRequestAction action = PostRequestAction(id: id);
    // use action events setter
    action.onStart = () => print('Action Start Form Ui');
    action.onSuccess = (post) => print('Action Success Form Ui ${post?.id}');
    action.onError = (error) => print('Action Error Form Ui ${error.message}');

    // use action subscribe
    action.subscribe(
      onSuccess: (response) {
        print('response Post Id: ${response?.id}');
      },
      onError: (error) {
        if (error is ApiRequestError) {
          print("response Error ${error.message}");
        }
      },
      onDone: () {
        print("Hi I done");
      },
    );
    action.onQueue();
  }

  getReport() {
    print("${ApiRequestPerformance.instance?.actionsReport}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: StreamBuilder<PostsResponse?>(
        stream: action?.stream,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data?.posts?.length,
                itemBuilder: (_, index) => ListTile(
                      title: Text(snapshot.data?.posts?[index].title ?? ''),
                      onTap: () =>
                          _getPostData(snapshot.data?.posts?[index].id),
                    ));
          }
          return CircularProgressIndicator();
        },
      )
          /*child: (posts?.isNotEmpty ?? false)
            ? ListView.builder(
                itemCount: posts?.length,
                itemBuilder: (_, index) => ListTile(
                      title: Text(posts?[index].title ?? ''),
                      onTap: () => _getPostData(posts?[index].id),
                    ))
            : CircularProgressIndicator(),*/
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: getReport,
        child: Icon(Icons.report),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
