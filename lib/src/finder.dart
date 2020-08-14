/// Stolen code from flutter_test/lib/src/finders.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class ElementPredicateFinder extends MatchFinder {
  ElementPredicateFinder(
    this.predicate, {
    String description,
    bool skipOffstage = true,
  })  : _description = description,
        super(skipOffstage: skipOffstage);

  final ElementPredicate predicate;
  final String _description;

  @override
  String get description =>
      _description ?? 'element matching predicate ($predicate)';

  @override
  bool matches(Element candidate) {
    return predicate(candidate);
  }
}
