import 'package:example/card_data.dart';
import 'package:flutter/material.dart';
import 'package:swipeable_stack/swipeable_stack.dart';

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

  String? _inputText;

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
      appBar: AppBar(
        actions: [
          Center(
            child: _button(
              onPressed: () {
                _cards.value = [];
              },
              color: Colors.red,
              label: 'reset',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: constraints,
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SwipeableStack<CardData>(
                        dataSet: _cards,
                        builder: (context, data, constraints) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: constraints,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      data.path,
                                      height: constraints.maxHeight,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      data.id,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        backgroundColor: data.overlayColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          _button(
                            onPressed: () {
                              _addCards(
                                cards: CardData.initialDeck(),
                              );
                            },
                            color: Colors.amber,
                            label: 'add [1,2,3]',
                          ),
                          _button(
                            onPressed: () {
                              _addCards(
                                cards: CardData.newDeck(),
                              );
                            },
                            color: Colors.blue,
                            label: 'add [4,5,6]',
                          ),
                          _button(
                            onPressed: () {
                              _addCards(
                                cards: CardData.includesOldCard(),
                              );
                            },
                            color: Colors.green,
                            label: 'add [1,8,9]',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _button(
                            onPressed: () {
                              print('rewind');
                            },
                            color: Colors.purpleAccent,
                            label: 'rewind',
                          ),
                          _button(
                            onPressed: () {
                              print('next');
                            },
                            color: Colors.pink,
                            label: 'next',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          const Text('id: '),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              onChanged: (id) {
                                setState(() {
                                  _inputText = id;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          _button(
                            onPressed: () {
                              final _inputText = this._inputText;
                              if (_inputText == null) {
                                return;
                              }
                              _removeCard(id: _inputText);
                            },
                            color: Colors.brown,
                            label: 'remove',
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeCard({
    required String id,
  }) {
    _cards.value = _cards.value
        .where(
          (identifiable) => !(identifiable.id == id),
        )
        .toList();
  }

  void _addCards({
    required List<CardData> cards,
  }) {
    _cards.value += cards;
  }

  Widget _button({
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
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
