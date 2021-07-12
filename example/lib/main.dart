import 'package:example/card_data.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final _cards = ValueNotifier<List<CardData>>(
    CardData.initialDeck(),
  );

  @override
  void initState() {
    super.initState();
    _cards.addListener(
      () => print(_cards),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text('SwipeableStack'),
              ),
            ),
            Row(
              children: [
                _bottomButton(
                  onPressed: _initDeck,
                  color: Colors.amber,
                  label: 'Initialize',
                ),
                _bottomButton(
                    onPressed: () {
                      _addCards(
                        cards: CardData.newDeck(),
                      );
                    },
                    color: Colors.blue,
                    label: 'add new cards'),
                _bottomButton(
                  onPressed: () {
                    _addCards(
                      cards: CardData.includesOldCard(),
                    );
                  },
                  color: Colors.green,
                  label: 'add new & old cards',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _next() {}

  void _rewind() {}

  void _initDeck() {
    _cards
      ..value = []
      ..value = CardData.initialDeck();
  }

  void _addCards({
    required List<CardData> cards,
  }) {
    _cards.value += cards;
  }

  Widget _bottomButton({
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            primary: color,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
