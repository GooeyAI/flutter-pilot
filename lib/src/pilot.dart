import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/src/common/layer_tree.dart';
import 'package:flutter_driver/src/common/render_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

final pilot = PilotImpl();

class PilotImpl {
  /// With [frameSync] enabled, Pilot will wait to perform an action
  /// until there are no pending frames in the app under test.
  var frameSync = true;

  var testTextInput = TestTextInput();
  var prober = LiveWidgetController(WidgetsBinding.instance);

  SemanticsHandle semantics;

  bool get semanticsIsEnabled =>
      RendererBinding.instance.pipelineOwner.semanticsOwner != null;

  Future<bool> setSemantics(bool enabled) async {
    final bool semanticsWasEnabled = semanticsIsEnabled;
    if (enabled && semantics == null) {
      semantics = RendererBinding.instance.pipelineOwner.ensureSemantics();
      if (!semanticsWasEnabled) {
        // wait for the first frame where semantics is enabled.
        final Completer<void> completer = Completer<void>();
        SchedulerBinding.instance.addPostFrameCallback((Duration d) {
          completer.complete();
        });
        await completer.future;
      }
    } else if (!enabled && semantics != null) {
      semantics.dispose();
      semantics = null;
    }
    return semanticsWasEnabled != semanticsIsEnabled;
  }

  LayerTree getLayerTree() {
    return LayerTree(
      RendererBinding.instance?.renderView?.debugLayer?.toStringDeep(),
    );
  }

  RenderTree getRenderTree() {
    return RenderTree(RendererBinding.instance?.renderView?.toStringDeep());
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  Future<void> waitUntilFrame(
    bool condition(), [
    Completer<void> completer,
  ]) async {
    completer ??= Completer<void>();
    if (!condition()) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        waitUntilFrame(condition, completer);
      });
    } else {
      completer.complete();
    }
    await completer.future;
  }

  Future<void> waitForTransientCallbacks() async {
    await waitUntilFrame(
      () => SchedulerBinding.instance.transientCallbackCount == 0,
    );
  }

  void setUpAll() {
    flutter_test.setUpAll(() async {
      await pilot.setUp();
    });
  }

  Future<void> setUp([Completer<void> completer]) {
    completer ??= Completer();

    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });

    return completer.future;
  }
}
