import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/src/extension/wait_conditions.dart';
import 'package:flutter_test/flutter_test.dart';

/// A condition that waits until no transient callbacks are scheduled.
class NoTransientCallbacksCondition implements WaitCondition {
  @override
  bool get condition => SchedulerBinding.instance.transientCallbackCount == 0;

  @override
  Future<void> wait() async {
    while (!condition) {
      await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }
}

/// A condition that waits until no pending frame is scheduled.
class NoPendingFrameCondition implements WaitCondition {
  @override
  bool get condition => !SchedulerBinding.instance.hasScheduledFrame;

  @override
  Future<void> wait() async {
    while (!condition) {
      await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }
}

/// A condition that waits until the Flutter engine has rasterized the first frame.
class FirstFrameRasterizedCondition implements WaitCondition {
  @override
  bool get condition => WidgetsBinding.instance.firstFrameRasterized;

  @override
  Future<void> wait() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    assert(condition);
  }
}

/// A condition that waits until no pending platform messages.
class NoPendingPlatformMessagesCondition implements WaitCondition {
  @override
  bool get condition {
    final TestDefaultBinaryMessenger binaryMessenger = ServicesBinding
        .instance.defaultBinaryMessenger as TestDefaultBinaryMessenger;
    return binaryMessenger.pendingMessageCount == 0;
  }

  @override
  Future<void> wait() async {
    final TestDefaultBinaryMessenger binaryMessenger = ServicesBinding
        .instance.defaultBinaryMessenger as TestDefaultBinaryMessenger;
    while (!condition) {
      await binaryMessenger.platformMessagesFinished;
    }
    assert(condition);
  }
}

/// A combined condition that waits until all the given [conditions] are met.
class CombinedCondition implements WaitCondition {
  /// Creates an [_InternalCombinedCondition] instance with the given list of
  /// [conditions].
  ///
  /// The [conditions] argument must not be null.
  const CombinedCondition(this.conditions) : assert(conditions != null);

  /// A list of conditions it waits for.
  final List<WaitCondition> conditions;

  @override
  bool get condition {
    return conditions.every((WaitCondition condition) => condition.condition);
  }

  @override
  Future<void> wait() async {
    while (!condition) {
      for (final WaitCondition condition in conditions) {
        assert(condition != null);
        await condition.wait();
      }
    }
    assert(condition);
  }
}
