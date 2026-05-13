import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/constants.dart';
import 'package:flutter/material.dart';

class Comment {
  final String id;
  final String text;
  final DateTime createdAt;
  final String colorHex;

  Comment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.colorHex,
  });

  Color get color => AdepaColors.fromHex(colorHex);

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      colorHex: map['colorHex'] ?? '#006B3F',
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
    'colorHex': colorHex,
  };
}

class Post {
  final String id;
  final String text;
  final String tag;
  final DateTime createdAt;
  final String colorHex;
  final int votes;
  final int commentCount;
  final Map<String, int> reactions;

  Post({
    required this.id,
    required this.text,
    required this.tag,
    required this.createdAt,
    required this.colorHex,
    this.votes = 1,
    this.commentCount = 0,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};

  Color get accentColor => AdepaColors.fromHex(colorHex);

  factory Post.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      text: data['text'] ?? '',
      tag: data['tag'] ?? 'accra',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      colorHex: data['colorHex'] ?? '#006B3F',
      votes: data['votes'] ?? 1,
      commentCount: data['commentCount'] ?? 0,
      reactions: Map<String, int>.from(data['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'tag': tag,
    'createdAt': Timestamp.fromDate(createdAt),
    'colorHex': colorHex,
    'votes': votes,
    'commentCount': commentCount,
    'reactions': reactions,
  };
}
