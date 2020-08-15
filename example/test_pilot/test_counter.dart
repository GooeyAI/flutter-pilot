import 'package:example/main.dart' as app;
import 'package:flutter/material.dart'; // <-- easy access to flutter
import 'package:flutter_test/flutter_test.dart';
import 'package:pilot/pilot.dart';

main() {
  // run your app, like you normally would
  app.main();

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
