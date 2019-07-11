import 'team.dart';

class Task {
  Task.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    url = json['url'];
    team = Team.fromJson(json['team']);
  }

  String title;
  String url;
  Team team;
}
