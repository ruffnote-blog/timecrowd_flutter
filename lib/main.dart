import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_oauth/lib/flutter_auth.dart';
import 'package:flutter_oauth/lib/model/config.dart';
import 'package:flutter_oauth/lib/oauth.dart';
import 'package:flutter_oauth/lib/token.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'task.dart';

Future<void> main() async {
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeCrowd',
      theme: ThemeData(
        primaryColor: const Color(0xFF524545),
      ),
      home: MyHomePage(title: 'TimeCrowd'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  OAuth flutterOAuth;
  List<Task> _tasks = <Task>[];
  String _accessToken = '';

  @override
  void initState() {
    super.initState();
    flutterOAuth = FlutterOAuth(Config(
        'https://timecrowd.net/oauth/authorize',
        'https://timecrowd.net/oauth/token',
        DotEnv().env['TIMECROWD_APP_ID'],
        DotEnv().env['TIMECROWD_SECRET'],
        'http://localhost:8080',
        'code'));

    _signIn();
  }

  Future<void> _signIn() async {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    String accessToken = await storage.read(key: 'timecrowdAccessToken');

    if (accessToken == null) {
      final Token token = await flutterOAuth.performAuthorization();
      accessToken = token.accessToken;
      await storage.write(key: 'timecrowdAccessToken', value: accessToken);
    }

    _accessToken = accessToken;

    _fetchDailyTasks();
  }

  Future<http.Response> _fetch(String path) async {
    return await http.get('https://timecrowd.net/api/v1/$path',
        headers: <String, String>{'Authorization': 'Bearer $_accessToken'});
  }

  Future<void> _fetchDailyTasks() async {
    final http.Response response = await _fetch('user/daily_activity');
    final List<dynamic> decoded = json.decode(response.body)['tasks'];

    setState(() {
      _tasks = decoded.map((dynamic d) => Task.fromJson(d)).toList();
    });
  }

  void _refresh() {
    _fetchDailyTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.separated(
        itemCount: _tasks.length,
        itemBuilder: (BuildContext context, int index) {
          final Task task = _tasks[index];
          return Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(task.title),
                    Text(task.team.name),
                  ],
                ),
                if (!task.url.isEmpty)
                  IconButton(
                    icon: Icon(Icons.link),
                    tooltip: task.url,
                    onPressed: () {
                      launch(task.url);
                    },
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
        backgroundColor: const Color(0xFF4abaa4),
      ),
    );
  }
}
