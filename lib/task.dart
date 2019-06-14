import 'team.dart';

class Task {
  Task.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    team = Team.fromJson(json['team']);
  }

  String title;
  Team team;
}
