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
  late final _controller = SwipeableStackController();
  late final _cards = ValueNotifier<List<CardData>>(
    CardData.initialDeck(),
  );

  String? _inputText;

  String get _ids => '[${_cards.value.map((cp) => cp.id).join(',')}]';

  @override
  void initState() {
    super.initState();
    _cards.addListener(_setState);
  }

  @override
  void dispose() {
    _cards.removeListener(_setState);
    super.dispose();
  }

  void _setState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Text(
            'data : $_ids',
          ),
        ),
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
      body: SafeArea(
        child: LayoutBuilder(
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
                          controller: _controller,
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
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        alignment: Alignment.center,
                                        color: data.color,
                                        child: Text(
                                          'id: ${data.id}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _button(
                          onPressed: () {
                            _addCards(
                              cards: CardData.initialDeck(),
                            );
                          },
                          color: Colors.amber,
                          label: 'add ids:[1,2,3]',
                        ),
                        _button(
                          onPressed: () {
                            _addCards(
                              cards: CardData.newDeck(),
                            );
                          },
                          color: Colors.blue,
                          label: 'add ids:[4,5,6]',
                        ),
                        _button(
                          onPressed: () {
                            _addCards(
                              cards: CardData.includesOldCard(),
                            );
                          },
                          color: Colors.green,
                          label: 'add ids:[2,7,8]',
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _button(
                          onPressed: _controller.rewind,
                          color: Colors.purpleAccent,
                          label: 'rewind',
                        ),
                        _button(
                          onPressed: _controller.next,
                          color: Colors.pink,
                          label: 'next',
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            for (final id in _inputText.split(',')) {
                              _removeCard(
                                id: id,
                              );
                            }
                          },
                          color: Colors.brown,
                          label: 'remove',
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: color,
      ),
      child: Text(label),
    );
  }
}
