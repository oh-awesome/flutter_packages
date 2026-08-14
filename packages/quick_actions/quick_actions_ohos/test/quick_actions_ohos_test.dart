// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_actions_ohos/quick_actions_ohos.dart';
import 'package:quick_actions_ohos/src/messages.g.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

const String LAUNCH_ACTION_STRING = 'aString';

/// Conversion tool to change [ShortcutItemMessage] back to [ShortcutItem].
///
/// Maps every field — including [ShortcutItemMessage.localizedSubtitle] — so
/// round-trip assertions stay complete after the wire format gained the
/// subtitle field.
ShortcutItem shortcutItemMessageToShortcutItem(ShortcutItemMessage item) {
  return ShortcutItem(
    type: item.type,
    localizedTitle: item.localizedTitle,
    localizedSubtitle: item.localizedSubtitle,
    icon: item.icon,
  );
}

/// A configurable fake of [OhosQuickActionsApi] used to drive the Dart-side
/// [QuickActionsOhos] without a real platform channel.
///
/// Each test constructs its own instance through [setUp] so no state leaks
/// between tests (see the `tearDown` that clears the channel handler).
class _FakeQuickActionsApi implements OhosQuickActionsApi {
  _FakeQuickActionsApi({this.launchAction = LAUNCH_ACTION_STRING});

  List<ShortcutItem> items = <ShortcutItem>[];
  bool getLaunchActionCalled = false;
  int getLaunchActionCallCount = 0;
  int setShortcutItemsCallCount = 0;
  int clearShortcutItemsCallCount = 0;
  final String? launchAction;

  /// When non-null, [setShortcutItems] throws this error to emulate a
  /// platform-channel failure (used by exception-path tests).
  Object? setShortcutItemsError;
  Object? clearShortcutItemsError;

  void reset() {
    items = <ShortcutItem>[];
    getLaunchActionCalled = false;
    getLaunchActionCallCount = 0;
    setShortcutItemsCallCount = 0;
    clearShortcutItemsCallCount = 0;
    setShortcutItemsError = null;
    clearShortcutItemsError = null;
  }

  @override
  Future<void> clearShortcutItems() async {
    clearShortcutItemsCallCount += 1;
    if (clearShortcutItemsError != null) {
      throw clearShortcutItemsError!;
    }
    items = <ShortcutItem>[];
    return;
  }

  @override
  Future<String?> getLaunchAction() async {
    getLaunchActionCalled = true;
    getLaunchActionCallCount += 1;
    return launchAction;
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItemMessage?> itemsList) async {
    setShortcutItemsCallCount += 1;
    if (setShortcutItemsError != null) {
      throw setShortcutItemsError!;
    }
    await clearShortcutItems();
    for (final ShortcutItemMessage? element in itemsList) {
      items.add(shortcutItemMessageToShortcutItem(element!));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Per-test instances avoid the shared-mutable-state / order-dependence
  // problems called out in the coverage review.
  late _FakeQuickActionsApi api;
  late QuickActionsOhos quickActions;

  setUp(() {
    api = _FakeQuickActionsApi();
    quickActions = QuickActionsOhos(api: api);
  });

  tearDown(() {
    // Reset the Flutter→native callback channel so one test's handler cannot
    // leak into another.
    OhosQuickActionsFlutterApi.setup(null);
  });

  group('registerWith', () {
    test('should register a QuickActionsOhos instance as the platform default',
        () {
      QuickActionsOhos.registerWith();
      expect(QuickActionsPlatform.instance, isA<QuickActionsOhos>());
    });
  });

  group('initialize', () {
    test('should query the launch action on the host api', () async {
      await quickActions.initialize((String type) {});

      expect(api.getLaunchActionCalled, isTrue);
    });

    test('should invoke the handler with the launch action when present',
        () async {
      final Completer<String> receivedAction = Completer<String>();
      await quickActions.initialize(receivedAction.complete);

      expect(receivedAction.future, completion(LAUNCH_ACTION_STRING));
    });

    test('should not invoke the handler when launch action is null', () async {
      final QuickActionsOhos quickActionsWithNullLaunchAction =
          QuickActionsOhos(api: _FakeQuickActionsApi(launchAction: null));
      bool handlerCalled = false;

      await quickActionsWithNullLaunchAction.initialize((_) {
        handlerCalled = true;
      });

      expect(handlerCalled, isFalse);
    });

    test('should propagate platform errors thrown by getLaunchAction',
        () async {
      final QuickActionsOhos failing = QuickActionsOhos(
        api: _FailingGetLaunchActionApi(),
      );

      await expectLater(
        failing.initialize((String type) {}),
        throwsA(isA<StateError>()),
      );
    });

    test('should be safe to call setShortcutItems concurrently', () async {
      // Concurrent channel calls on the same instance must each complete
      // without corrupting state or throwing. The two invocations are
      // independent map+forward operations against the fake host api.
      await Future.wait<void>([
        quickActions.setShortcutItems(<ShortcutItem>[
          const ShortcutItem(type: 'a', localizedTitle: 'a'),
        ]),
        quickActions.setShortcutItems(<ShortcutItem>[
          const ShortcutItem(type: 'b', localizedTitle: 'b'),
        ]),
      ]);

      expect(api.setShortcutItemsCallCount, 2);
    });
  });

  group('setShortcutItems', () {
    test('should map and forward shortcut items to the host api', () async {
      await quickActions.initialize((String type) {});
      const ShortcutItem item = ShortcutItem(
        type: 'test',
        localizedTitle: 'title',
        localizedSubtitle: 'subtitle',
        icon: 'icon.svg',
      );
      await quickActions.setShortcutItems(<ShortcutItem>[item]);

      expect(api.items.first.type, item.type);
      expect(api.items.first.localizedTitle, item.localizedTitle);
      expect(api.items.first.localizedSubtitle, item.localizedSubtitle);
      expect(api.items.first.icon, item.icon);
    });

    test('should accept an empty list as a boundary case', () async {
      await quickActions.setShortcutItems(<ShortcutItem>[]);

      expect(api.items, isEmpty);
      expect(api.setShortcutItemsCallCount, 1);
    });

    test('should accept an item with an empty type', () async {
      const ShortcutItem item =
          ShortcutItem(type: '', localizedTitle: 'title');
      await quickActions.setShortcutItems(<ShortcutItem>[item]);

      expect(api.items.first.type, '');
    });

    test('should accept a null localizedSubtitle and icon', () async {
      const ShortcutItem item =
          ShortcutItem(type: 'test', localizedTitle: 'title');
      await quickActions.setShortcutItems(<ShortcutItem>[item]);

      expect(api.items.first.localizedSubtitle, isNull);
      expect(api.items.first.icon, isNull);
    });

    test('should handle a large list without error', () async {
      final List<ShortcutItem> items = List<ShortcutItem>.generate(
        500,
        (int i) => ShortcutItem(
          type: 'type_$i',
          localizedTitle: 'title_$i',
        ),
      );

      await quickActions.setShortcutItems(items);

      expect(api.items.length, 500);
      expect(api.items.last.type, 'type_499');
    });

    test('should clear previous items when set again', () async {
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'first', localizedTitle: 'first'),
      ]);
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'second', localizedTitle: 'second'),
      ]);

      expect(api.items.length, 1);
      expect(api.items.first.type, 'second');
    });

    test('should propagate errors from the host api', () async {
      api.setShortcutItemsError = StateError('boom');

      await expectLater(
        quickActions.setShortcutItems(
          <ShortcutItem>[const ShortcutItem(type: 'x', localizedTitle: 'x')],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('clearShortcutItems', () {
    test('should clear stored items on the host api', () async {
      // Prime the fake directly so the assertion is not influenced by
      // setShortcutItems() clearing items internally.
      api.items = <ShortcutItem>[
        const ShortcutItem(type: 'test', localizedTitle: 'title'),
      ];

      await quickActions.clearShortcutItems();

      expect(api.items, isEmpty);
      expect(api.clearShortcutItemsCallCount, 1);
    });

    test('should be safe to call repeatedly (idempotent)', () async {
      await quickActions.clearShortcutItems();
      await quickActions.clearShortcutItems();

      expect(api.clearShortcutItemsCallCount, 2);
      expect(api.items, isEmpty);
    });

    test('should allow rapid set/clear alternation', () async {
      // Stress the set→clear→set sequence to guard against state corruption.
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'one', localizedTitle: 'one'),
      ]);
      await quickActions.clearShortcutItems();
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'two', localizedTitle: 'two'),
      ]);

      expect(api.items.single.type, 'two');
    });

    test('should propagate errors from the host api', () async {
      api.clearShortcutItemsError = StateError('clear boom');

      await expectLater(
        quickActions.clearShortcutItems(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ShortcutItem', () {
    test('should expose all fields when fully constructed', () {
      const ShortcutItem item = ShortcutItem(
        type: 'type',
        localizedTitle: 'title',
        localizedSubtitle: 'subtitle',
        icon: 'foo',
      );

      expect(item.type, 'type');
      expect(item.localizedTitle, 'title');
      expect(item.localizedSubtitle, 'subtitle');
      expect(item.icon, 'foo');
    });

    test('should default optional fields to null', () {
      const ShortcutItem item =
          ShortcutItem(type: 'type', localizedTitle: 'title');

      expect(item.localizedSubtitle, isNull);
      expect(item.icon, isNull);
    });
  });
}

/// A fake api whose [getLaunchAction] always throws, used to assert that
/// [QuickActionsOhos.initialize] propagates platform errors instead of
/// swallowing them.
class _FailingGetLaunchActionApi implements OhosQuickActionsApi {
  @override
  Future<String?> getLaunchAction() async => throw StateError('no launch');

  @override
  Future<void> setShortcutItems(List<ShortcutItemMessage?> itemsList) async {}

  @override
  Future<void> clearShortcutItems() async {}
}
