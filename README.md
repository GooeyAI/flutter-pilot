# Pilot

Pilot is a better way to write integration (end-to-end) tests in flutter.

## How does this work?

It gives you access to the raw flutter driver [extension API](https://github.com/flutter/flutter/blob/master/packages/flutter_driver/lib/src/extension/extension.dart),
by removing the RPC bridge between flutter driver and the flutter driver extension.

## How is this better than flutter driver?

- Hot reload supported!

```
Performing hot restart...
Restarted application in 1,885ms.
I/flutter (20159): 00:00 +0: Counter App starts at 0
I/flutter (20159): 00:00 +1: Counter App increments the counter
I/flutter (20159): 00:00 +2: All tests passed!

```

- Share code between tests and app

Pilot frees you from the oppression of class names / keys as strings,
and makes refactoring code super fast and safe.

Flutter driver runs the tests on the host machine using dart,
which means you can't import flutter, and any code that uses it.

Pilot runs directly on the target device.

- Find widgets by their type, directly

```dart
find.byWidgetType<MyCoolWidget>();
```

## Example

```dart
import 'package:example/main.dart' as app;
import 'package:flutter/material.dart'; // <-- easy access to flutter
import 'package:flutter_test/flutter_test.dart';
import 'package:pilot/pilot.dart';

main() async {
  // run your app, like you normally would
  app.main();

  // setup pilot (optionally, do this in flutter_test's setUpAll)
  await pilot.setUp();

  // then, run the tests
  group('Counter App', () {
    var addBtn = find.byIcon(Icons.add);

    var counter = find.byKey(app
        .MyHomePage.counterKey); // <-- no need for finding keys by String value

    test('starts at 0', () async {
      // Use the [getText] method to verify the counter starts at 0.
      expect(await counter.getText(), "0");
    });

    test('increments the counter', () async {
      // First, tap the button.
      await addBtn
          .tap(); // <-- no complicated driver API, simply call tap() on the [Finder].

      // Then, verify the counter text is incremented by 1.
      expect(await counter.getText(), "1");
    });
  });
}
```

### Run this example -

(Also runs on desktop and web!)

```
git clone https://github.com/dara-network/flutter-pilot.git
cd example
flutter run test_pilot/test_counter.dart
```
