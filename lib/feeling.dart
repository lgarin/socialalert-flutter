
import 'package:flutter/material.dart';

class Feeling {

  static final Feeling veryGood = Feeling._init(2, 'very good', Icons.sentiment_very_satisfied_rounded, Color.fromARGB(255, 86, 205, 105));
  static final Feeling good = Feeling._init(1, 'good', Icons.sentiment_satisfied_rounded, Color.fromARGB(255, 86, 205, 105));
  static final Feeling neutral = Feeling._init(0, 'neutral', Icons.sentiment_neutral_rounded, Color.fromARGB(255, 9, 114, 236));
  static final Feeling bad = Feeling._init(-1, 'bad', Icons.sentiment_dissatisfied_rounded, Color.fromARGB(255, 220, 53, 69));
  static final Feeling veryBad = Feeling._init(-2, 'very bad', Icons.sentiment_very_dissatisfied_rounded, Color.fromARGB(255, 220, 53, 69));

  static final List<Feeling> allAscending = [veryBad, bad, neutral, good, veryGood];
  static final List<Feeling> allDescending = [veryGood, good, neutral, bad, veryBad];

  static Feeling fromValue(int value) => value == null ? null : allAscending[value + 2];

  final int value;
  final String description;
  final IconData icon;
  final Color color;

  Feeling._init(this.value, this.description, this.icon, this.color);
}