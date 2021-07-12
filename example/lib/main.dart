import 'package:flutter/material.dart';
import 'package:swipeable_stack/swipeable_stack.dart';

class SwipeDirectionColor {
  static const right = Color.fromRGBO(70, 195, 120, 1);
  static const left = Color.fromRGBO(220, 90, 108, 1);
  static const up = Color.fromRGBO(83, 170, 232, 1);
  static const down = Color.fromRGBO(154, 85, 215, 1);
}

extension SwipeDirecionX on SwipeDirection {
  Color get color {
    switch (this) {
      case SwipeDirection.right:
        return Color.fromRGBO(70, 195, 120, 1);
      case SwipeDirection.left:
        return Color.fromRGBO(220, 90, 108, 1);
      case SwipeDirection.up:
        return Color.fromRGBO(83, 170, 232, 1);
      case SwipeDirection.down:
        return Color.fromRGBO(154, 85, 215, 1);
    }
    return Colors.transparent;
  }
}

const _images = [
  'images/image_3.jpg',
  'images/image_1.jpg',
  'images/image_2.jpg',
];

final data = <UserData>[
  for (int index = 0; index < 10; index++)
    ..._images.map(
      (path) => UserData(
        path: path,
        name: '$path-$index',
      ),
    ),
];

class UserData extends Identifiable {
  UserData({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  String get id => name;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const double _bottomAreaHeight = 100;

  static const EdgeInsets _padding = EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SwipeableStack<UserData>(
          dataSets: data,
          builder: (
            context,
            user,
            constraints,
          ) {
            return Padding(
              padding: _padding,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            user.path,
                            height: constraints.maxHeight,
                          ),
                        ),
                        Center(
                          child: Text(user.name),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
