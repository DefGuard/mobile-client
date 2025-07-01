import 'package:flutter/material.dart';
import 'dart:async';

import 'package:wireguard_plugin/wireguard_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _wireguardPlugin = WireguardPlugin();
  bool permissionsGranted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> requestPermissions() async {
    final result = await _wireguardPlugin.requestPermissions();
    setState(() {
      permissionsGranted = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          children: [
            Center(child: Text("Permissions state: $permissionsGranted")),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  requestPermissions();
                },
                child: Text("Request permissions"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
