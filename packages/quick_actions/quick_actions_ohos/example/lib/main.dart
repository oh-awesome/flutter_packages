// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions_ohos/quick_actions_ohos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Quick Actions Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String shortcut = 'no action set';

  // --- API demo state ---
  String _launchActionResult = 'not checked';
  List<ShortcutItem> _currentItems = [];
  String _clearResult = 'not called';
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();

    final QuickActionsOhos quickActions = QuickActionsOhos();
    quickActions.initialize((String shortcutType) {
      setState(() {
        shortcut = '$shortcutType has launched';
        _launchActionResult = shortcutType;
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_one',
        localizedTitle: 'Action one',
        icon: 'ic_shortcut',
      ),
      const ShortcutItem(
        type: 'action_two',
        localizedTitle: 'Action two',
        icon: 'ic_shortcut',
      ),
    ]).then((void _) {
      setState(() {
        if (shortcut == 'no action set') {
          shortcut = 'actions ready';
        }
        _currentItems = [
          const ShortcutItem(type: 'action_one', localizedTitle: 'Action one', icon: 'ic_shortcut'),
          const ShortcutItem(type: 'action_two', localizedTitle: 'Action two', icon: 'ic_shortcut'),
        ];
      });
    });
  }

  Future<void> _runWithCatch(Future<void> Function() action, String label) async {
    setState(() { _errorMsg = ''; });
    try {
      await action();
    } on PlatformException catch (e) {
      setState(() { _errorMsg = '$label: PlatformException(${e.code}, ${e.message})'; });
    } catch (e) {
      setState(() { _errorMsg = '$label: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shortcut),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On home screen, long press the app icon to '
                      'get Action one or Action two options. Tapping on that action should '
                      'set the toolbar title.'),
                  const SizedBox(height: 100),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text('API Status', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),

                  // --- getLaunchAction() ---
                  _apiRow('getLaunchAction()', _launchActionResult, () {
                    _runWithCatch(() async {
                      // initialize() internally calls getLaunchAction()
                      await QuickActionsOhos().initialize((String shortcutType) {
                        setState(() {
                          _launchActionResult = shortcutType;
                          shortcut = '$shortcutType has launched';
                        });
                      });
                      // If no shortcut launch, callback won't fire
                      setState(() {
                        if (_launchActionResult == 'not checked') {
                          _launchActionResult = 'null (no shortcut launch)';
                        }
                      });
                    }, 'getLaunchAction');
                  }),
                  const SizedBox(height: 4),

                  // --- setShortcutItems() ---
                  _apiRow('setShortcutItems()', _currentItems.isEmpty ? 'not set' : '${_currentItems.length} items', () {
                    _runWithCatch(() {
                      return QuickActionsOhos().setShortcutItems(<ShortcutItem>[
                        const ShortcutItem(type: 'action_one', localizedTitle: 'Action one', icon: 'ic_shortcut'),
                        const ShortcutItem(type: 'action_two', localizedTitle: 'Action two', icon: 'ic_shortcut'),
                      ]).then((_) {
                        setState(() {
                          _currentItems = [
                            const ShortcutItem(type: 'action_one', localizedTitle: 'Action one', icon: 'ic_shortcut'),
                            const ShortcutItem(type: 'action_two', localizedTitle: 'Action two', icon: 'ic_shortcut'),
                          ];
                        });
                      });
                    }, 'setShortcutItems');
                  }),
                  if (_currentItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _currentItems.map((item) => Text(
                          'type: ${item.type}, title: ${item.localizedTitle}, icon: ${item.icon}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // --- setShortcutItems([])  boundary ---
                  _apiRow('setShortcutItems([])', _currentItems.isEmpty ? 'empty list' : 'has items', () {
                    _runWithCatch(() {
                      return QuickActionsOhos().setShortcutItems(<ShortcutItem>[]).then((_) {
                        setState(() { _currentItems = []; });
                      });
                    }, 'setShortcutItems([])');
                  }),
                  const SizedBox(height: 4),

                  // --- clearShortcutItems() ---
                  _apiRow('clearShortcutItems()', _clearResult, () {
                    _runWithCatch(() {
                      return QuickActionsOhos().clearShortcutItems().then((_) {
                        setState(() {
                          _clearResult = 'cleared';
                          _currentItems = [];
                          // clearShortcutItems() does not touch the launch action;
                          // keep showing the last real query result instead of a
                          // misleading 'null'.
                          _launchActionResult = 'not affected by clear';
                        });
                      });
                    }, 'clearShortcutItems');
                  }),
                  const SizedBox(height: 8),

                  // --- Exception display ---
                  if (_errorMsg.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_errorMsg, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                const SizedBox(height: 4),
                Text(
                  '- Static shortcuts be configured in shortcuts_config.json\n'
                  '- Cold start: action is held as pendingLaunchAction until plugin attaches\n'
                  '- Hot start: action is delivered immediately via onNewWant callback\n'
                  '- clearShortcutItems() only clears shortcut items, not the launch action',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiRow(String name, String result, VoidCallback onTap) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(result, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        SizedBox(
          height: 28,
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Run', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
