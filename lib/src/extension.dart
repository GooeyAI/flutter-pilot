/// Stolen code from flutter_driver/lib/src/extension/extension.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding, SemanticsHandle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/src/common/diagnostics_tree.dart';
import 'package:flutter_driver/src/common/geometry.dart';
import 'package:flutter_driver/src/common/layer_tree.dart';
import 'package:flutter_driver/src/common/render_tree.dart';
import 'package:flutter_test/flutter_test.dart';

class Pilot {
  /// With [frameSync] enabled, Pilot will wait to perform an action
  /// until there are no pending frames in the app under test.
  static var frameSync = true;

  static var testTextInput = TestTextInput();
  static var prober = LiveWidgetController(WidgetsBinding.instance);

  static SemanticsHandle semantics;

  static bool get semanticsIsEnabled =>
      RendererBinding.instance.pipelineOwner.semanticsOwner != null;

  static Future<bool> setSemantics(bool enabled) async {
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

  static LayerTree getLayerTree() {
    return LayerTree(
      RendererBinding.instance?.renderView?.debugLayer?.toStringDeep(),
    );
  }

  static RenderTree getRenderTree() {
    return RenderTree(RendererBinding.instance?.renderView?.toStringDeep());
  }

  // Waits until at the end of a frame the provided [condition] is [true].
  static Future<void> waitUntilFrame(
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

  static Future<void> waitForTransientCallbacks() async {
    await Pilot.waitUntilFrame(
      () => SchedulerBinding.instance.transientCallbackCount == 0,
    );
  }
}

extension PilotFinder on Finder {
  /// Runs [finder] repeatedly until it finds one or more [Element]s.
  Future<void> wait() async {
    if (Pilot.frameSync) await Pilot.waitForTransientCallbacks();

    await Pilot.waitUntilFrame(() => evaluate().isNotEmpty);

    if (Pilot.frameSync) await Pilot.waitForTransientCallbacks();
  }

  /// Runs [finder] repeatedly until it finds zero [Element]s.
  Future<void> waitForAbsent() async {
    if (Pilot.frameSync) await Pilot.waitForTransientCallbacks();

    await Pilot.waitUntilFrame(() => evaluate().isEmpty);

    if (Pilot.frameSync) await Pilot.waitForTransientCallbacks();
  }

  Future<void> tap() async {
    await wait();
    await Pilot.prober.tap(this);
  }

  Future<SemanticsNode> getSemanticsNode() async {
    await wait();
    final Iterable<Element> elements = evaluate();
    if (elements.length > 1) {
      throw StateError(
          'Found more than one element with the same ID: $elements');
    }
    final Element element = elements.single;
    RenderObject renderObject = element.renderObject;
    SemanticsNode node;
    while (renderObject != null && node == null) {
      node = renderObject.debugSemantics;
      renderObject = renderObject.parent as RenderObject;
    }
    if (node == null) throw StateError('No semantics data found');
    return node;
  }

  Future<Offset> getOffset(OffsetType offsetType) async {
    await wait();
    final Element element = evaluate().single;
    final RenderBox box = element.renderObject as RenderBox;
    Offset localPoint;
    switch (offsetType) {
      case OffsetType.topLeft:
        localPoint = Offset.zero;
        break;
      case OffsetType.topRight:
        localPoint = box.size.topRight(Offset.zero);
        break;
      case OffsetType.bottomLeft:
        localPoint = box.size.bottomLeft(Offset.zero);
        break;
      case OffsetType.bottomRight:
        localPoint = box.size.bottomRight(Offset.zero);
        break;
      case OffsetType.center:
        localPoint = box.size.center(Offset.zero);
        break;
    }
    final Offset globalPoint = box.localToGlobal(localPoint);
    return globalPoint;
  }

  Future<DiagnosticsNode> getDiagnosticsTree(
    DiagnosticsType diagnosticsType,
  ) async {
    await wait();
    final Element element = evaluate().single;
    DiagnosticsNode diagnosticsNode;
    switch (diagnosticsType) {
      case DiagnosticsType.renderObject:
        diagnosticsNode = element.renderObject.toDiagnosticsNode();
        break;
      case DiagnosticsType.widget:
        diagnosticsNode = element.toDiagnosticsNode();
        break;
    }
    return diagnosticsNode;
  }

  Future<void> scroll(
    double dx,
    double dy,
    Duration duration,
    int frequency,
  ) async {
    await wait();
    final int totalMoves =
        duration.inMicroseconds * frequency ~/ Duration.microsecondsPerSecond;
    final Offset delta = Offset(dx, dy) / totalMoves.toDouble();
    final Duration pause = duration ~/ totalMoves;
    final Offset startLocation = Pilot.prober.getCenter(this);
    Offset currentLocation = startLocation;
    final TestPointer pointer = TestPointer(1);
    final HitTestResult hitTest = HitTestResult();

    Pilot.prober.binding.hitTest(hitTest, startLocation);
    Pilot.prober.binding.dispatchEvent(pointer.down(startLocation), hitTest);
    await Future<
        void>.value(); // so that down and move don't happen in the same microtask
    for (int moves = 0; moves < totalMoves; moves += 1) {
      currentLocation = currentLocation + delta;
      Pilot.prober.binding
          .dispatchEvent(pointer.move(currentLocation), hitTest);
      await Future<void>.delayed(pause);
    }
    Pilot.prober.binding.dispatchEvent(pointer.up(), hitTest);
  }

  Future<void> scrollIntoView({double alignment = 0}) async {
    await wait();
    await Scrollable.ensureVisible(
      evaluate().single,
      duration: const Duration(milliseconds: 100),
      alignment: alignment ?? 0.0,
    );
  }

  Future<String> getText() async {
    await wait();

    final Widget widget = evaluate().single.widget;
    String text;

    if (widget.runtimeType == Text) {
      text = (widget as Text).data;
    } else if (widget.runtimeType == RichText) {
      final RichText richText = widget as RichText;
      if (richText.text.runtimeType == TextSpan) {
        text = (richText.text as TextSpan).text;
      }
    } else if (widget.runtimeType == TextField) {
      text = (widget as TextField).controller.text;
    } else if (widget.runtimeType == TextFormField) {
      text = (widget as TextFormField).controller.text;
    } else if (widget.runtimeType == EditableText) {
      text = (widget as EditableText).controller.text;
    }

    if (text == null) {
      throw UnsupportedError(
          'Type ${widget.runtimeType.toString()} is currently not supported by getText');
    }

    return text;
  }

  Future<void> setTextEntryEmulation(bool enabled) async {
    if (enabled) {
      Pilot.testTextInput.register();
    } else {
      Pilot.testTextInput.unregister();
    }
  }

  Future<void> enterText(String text) async {
    if (!Pilot.testTextInput.isRegistered) {
      throw 'Unable to fulfill `$runtimeType.enterText`. Text emulation is '
          'disabled. You can enable it using `$runtimeType.setTextEntryEmulation`.';
    }
    Pilot.testTextInput.enterText(text);
  }
}
