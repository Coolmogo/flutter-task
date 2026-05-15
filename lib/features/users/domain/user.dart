class User {
  final String id;
  final String name;
  final String? email;

  const User({required this.id, required this.name, this.email});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], name: json['name'], email: json['email']);
}
