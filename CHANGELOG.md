## 0.4.3
- Improve: Not to use `GlobalKey`. 

## 0.4.2
- Fix: Call `notifyListeners()` in `addPostFrameCallback`.

## 0.4.1
- Fix: Delete unnecessary `setState` in `_SwipeableStackState.didUpdateWidget`.

## 0.4.0
- Delete `persistJudgedCard` option.

## 0.3.5
- Change [SwipeableStackController#currentIndex] non-nullable. 
 
## 0.3.4
- Cancel animations when the front card is removed. 

## 0.3.3
- Export `callbacks.dart`.

## 0.3.2
- Add [persistJudgedCard] option.

## 0.3.1
- Add generics for [onSwipeCompleted] callback.

## 0.3.0
- Not to use ValueNotifier.

## 0.2.0

- Refactor: Move cardProperties to [SwipeableStackController].

## 0.1.0

- Initial release.