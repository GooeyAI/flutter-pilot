import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:flutter_test/src/finders.dart' show find;

extension PilotCommonFinders on CommonFinders {
  /// Finds widgets by [key]. Only [String] and [int] values can be used.
  ///
  /// For more advanced usage, use [byKey] directly.
  Finder byValueKey(dynamic key) {
    var keyValueType = '${key.runtimeType}';
    switch (keyValueType) {
      case 'int':
        return find.byKey(ValueKey<int>(key as int));
      case 'String':
        return find.byKey(ValueKey<String>(key as String));
      default:
        throw 'Unsupported ByValueKey type: ${keyValueType}';
    }
  }

  /// Finds the back button on a Material or Cupertino page's scaffold.
  Finder pageBack() {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip) return widget.message == 'Back';
      if (widget is CupertinoNavigationBarBackButton) return true;
      return false;
    }, description: 'Material or Cupertino back button');
  }

  Finder byWidgetType<T extends Widget>() {
    return find.byWidgetPredicate((widget) => widget is T);
  }
}
