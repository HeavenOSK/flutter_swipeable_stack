import 'package:flutter/material.dart';
import 'package:swipeable_stack/swipeable_stack.dart';

class CardData extends Identifiable {
  CardData({
    required this.id,
    required this.path,
    required this.overlayColor,
  });

  @override
  final String id;
  final String path;
  final Color overlayColor;

  static List<CardData> initialDeck() {
    final color = Colors.transparent;
    return [
      CardData(
        id: '1',
        overlayColor: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '2',
        overlayColor: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '3',
        overlayColor: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }

  static List<CardData> newDeck() {
    final color = Colors.green;
    return [
      CardData(
        id: '4',
        overlayColor: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '5',
        overlayColor: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '6',
        overlayColor: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }

  static List<CardData> includesOldCard() {
    final color = Colors.blue;
    return [
      CardData(
        id: '1',
        overlayColor: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '8',
        overlayColor: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '9',
        overlayColor: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }
}
