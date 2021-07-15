import 'package:flutter/material.dart';
import 'package:swipeable_stack/swipeable_stack.dart';

class CardData extends SwipeableStackIdentifiable {
  CardData({
    required this.id,
    required this.path,
    required this.color,
  });

  @override
  final String id;
  final String path;
  final Color color;

  @override
  String toString() {
    return 'CardData('
        '$id'
        ')';
  }

  static List<CardData> initialDeck() {
    const color = Colors.green;
    return [
      CardData(
        id: '1',
        color: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '2',
        color: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '3',
        color: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }

  static List<CardData> newDeck() {
    const color = Colors.red;
    return [
      CardData(
        id: '4',
        color: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '5',
        color: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '6',
        color: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }

  static List<CardData> includesOldCard() {
    const color = Colors.blue;
    return [
      CardData(
        id: '2',
        color: color,
        path: 'images/image_1.jpg',
      ),
      CardData(
        id: '7',
        color: color,
        path: 'images/image_2.jpg',
      ),
      CardData(
        id: '8',
        color: color,
        path: 'images/image_3.jpg',
      ),
    ];
  }
}
