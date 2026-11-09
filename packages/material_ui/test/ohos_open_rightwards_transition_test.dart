/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Regression test for the OHOS default page transition: the entering page must
// actually slide in from the right following the transition curve, including
// when the parent does not rebuild on animation ticks.
void main() {
  testWidgets('ohos transition follows both animations without parent rebuilds', (tester) async {
    final primary = AnimationController(vsync: tester, duration: const Duration(milliseconds: 300));
    final secondary = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(primary.dispose);
    addTearDown(secondary.dispose);
    const key = ValueKey<String>('transition child');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const OpenRightwardsPageTransitionsBuilder().buildTransitions<void>(
          null,
          null,
          primary,
          secondary,
          const SizedBox.expand(key: key),
        ),
      ),
    );
    final double width = tester.getSize(find.byKey(key)).width;
    expect(tester.getTopLeft(find.byKey(key)).dx, width);
    primary.value = 0.5;
    await tester.pump();
    final double middle = tester.getTopLeft(find.byKey(key)).dx;
    expect(middle, inExclusiveRange(0, width));
    primary.value = 1;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(key)).dx, 0);
    secondary.value = 1;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(key)).dx, closeTo(-0.2 * width, 0.001));
    secondary.value = 0;
    primary.value = 0;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(key)).dx, width);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ohos OpenRightwards transition slides the entering page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.ohos: OpenRightwardsPageTransitionsBuilder(),
            },
          ),
        ),
        home: const Text('home page'),
      ),
    );

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('target page')));
    await tester.pump();

    final double screenWidth =
        tester.binding.window.physicalSize.width / tester.binding.window.devicePixelRatio;

    // Sample the entering page's position at two points during the 300ms
    // transition. The page must be progressively sliding in: further right
    // early in the transition than halfway through, and not yet arrived.
    await tester.pump(const Duration(milliseconds: 75));
    final double earlyLeft = tester.getTopLeft(find.text('target page')).dx;
    await tester.pump(const Duration(milliseconds: 75));
    final double midLeft = tester.getTopLeft(find.text('target page')).dx;
    expect(
      earlyLeft,
      greaterThan(midLeft),
      reason: 'entering page must be moving, not stuck at the initial offset',
    );
    expect(
      earlyLeft,
      lessThan(screenWidth),
      reason: 'entering page must have entered the viewport early in the transition',
    );
    expect(
      midLeft,
      greaterThan(0),
      reason: 'entering page must not have fully arrived at mid-transition',
    );

    // At the end of the transition the page must be fully in place.
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('target page')).dx, 0.0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('ohos transition releases listeners after repeated rebuilds', (
    WidgetTester tester,
  ) async {
    final primary = _CountingAnimation();
    final secondary = _CountingAnimation();

    for (var i = 0; i < 8; i++) {
      await tester.pumpWidget(_buildTransition(primary, secondary));
      expect(primary.statusListeners, hasLength(1));
      expect(secondary.statusListeners, hasLength(1));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    expect(primary.statusListeners, isEmpty);
    expect(secondary.statusListeners, isEmpty);
    expect(primary.listeners, isEmpty);
    expect(secondary.listeners, isEmpty);
  });

  for (final replacement in <String>['primary', 'secondary', 'both']) {
    testWidgets('ohos transition replaces $replacement animation parents', (
      WidgetTester tester,
    ) async {
      final oldPrimary = _CountingAnimation();
      final oldSecondary = _CountingAnimation();
      final primary = replacement == 'secondary' ? oldPrimary : _CountingAnimation();
      final secondary = replacement == 'primary' ? oldSecondary : _CountingAnimation();

      await tester.pumpWidget(_buildTransition(oldPrimary, oldSecondary));
      final Widget oldTransition = tester.widget<Directionality>(find.byType(Directionality)).child;
      final State<StatefulWidget> state = tester.state(find.byWidget(oldTransition));
      final AnimationStatusListener primaryListener = oldPrimary.statusListeners.single;
      final AnimationStatusListener secondaryListener = oldSecondary.statusListeners.single;
      await tester.pumpWidget(_buildTransition(primary, secondary));
      expect(tester.takeException(), isNull);
      final Widget transition = tester.widget<Directionality>(find.byType(Directionality)).child;
      expect(tester.state(find.byWidget(transition)), same(state));
      expect(primary.statusListeners, hasLength(1));
      expect(secondary.statusListeners, hasLength(1));
      if (oldPrimary != primary) {
        expect(oldPrimary.statusListeners, isEmpty);
        expect(oldPrimary.listeners, isEmpty);
      } else {
        expect(primary.statusListeners.single, same(primaryListener));
      }
      if (oldSecondary != secondary) {
        expect(oldSecondary.statusListeners, isEmpty);
        expect(oldSecondary.listeners, isEmpty);
      } else {
        expect(secondary.statusListeners.single, same(secondaryListener));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      expect(primary.statusListeners, isEmpty);
      expect(secondary.statusListeners, isEmpty);
      expect(primary.listeners, isEmpty);
      expect(secondary.listeners, isEmpty);
    });
  }

  testWidgets('ohos navigation does not accumulate transition status listeners', (
    WidgetTester tester,
  ) async {
    final home = _CountingPageRoute(builder: (_) => const Text('home page'));
    await tester.pumpWidget(MaterialApp(onGenerateRoute: (RouteSettings settings) => home));
    await tester.pumpAndSettle();
    final int initialListenerCount = home.trackedAnimation.statusListeners.length;
    final NavigatorState navigator = tester.state(find.byType(Navigator));

    for (var i = 0; i < 4; i++) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('target page')));
      await tester.pumpAndSettle();
      navigator.pop();
      await tester.pumpAndSettle();
      expect(home.trackedAnimation.statusListeners, hasLength(initialListenerCount));
      expect(tester.takeException(), isNull);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));
}

Widget _buildTransition(Animation<double> primary, Animation<double> secondary) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: const OpenRightwardsPageTransitionsBuilder().buildTransitions<void>(
      null,
      null,
      primary,
      secondary,
      const SizedBox(width: 100, height: 100),
    ),
  );
}

class _CountingAnimation extends Animation<double> {
  _CountingAnimation([this.parent]);

  final Animation<double>? parent;
  final Set<VoidCallback> listeners = <VoidCallback>{};
  final Set<AnimationStatusListener> statusListeners = <AnimationStatusListener>{};

  @override
  double get value => parent?.value ?? 0.5;

  @override
  AnimationStatus get status => parent?.status ?? AnimationStatus.forward;

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    parent?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    parent?.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners.add(listener);
    parent?.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners.remove(listener);
    parent?.removeStatusListener(listener);
  }
}

class _CountingPageRoute extends MaterialPageRoute<void> {
  _CountingPageRoute({required super.builder});

  late final _CountingAnimation trackedAnimation;

  @override
  Animation<double> createAnimation() {
    trackedAnimation = _CountingAnimation(super.createAnimation());
    return trackedAnimation;
  }
}
