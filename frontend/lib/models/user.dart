import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class User {
  final int? id;
  String username;
  String password;
  String token;

  User({required this.username, required this.password, required this.token, this.id});

  User copyWith({
    String? username,
    String? password,
    String? token,
    int? id,
  }){
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      id: id ?? this.id,
    );
  }

  factory User.fromMap(Map<String, dynamic> map){
    return User(
      username: map['username'],
      password: map['password'],
      token: map['token'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'token': token,
      'id': id,
    };
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
  User.fromMap(json.decode(source));

  enc.Encrypted encrypt(String pwd){
    final key = enc.Key.fromLength(32);
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final encrypted = encrypter.encrypt(pwd, iv: iv);
    return encrypted;
  }

  String decrypt(enc.Encrypted pwd){
    final key = enc.Key.fromLength(32);
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final decrypted = encrypter.decrypt(pwd, iv: iv);
    return decrypted;
  }

}