class Team {
  Team.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  String name;
}
