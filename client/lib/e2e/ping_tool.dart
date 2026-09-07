import 'dart:io';

import 'package:material_ui/material_ui.dart';

const bool e2eToolsEnabled = bool.fromEnvironment('E2E');

const _probePort = 80;
const _probeTimeout = Duration(seconds: 5);
const _connectionRefused = 61;

Future<bool> _reachable(String host) async {
  try {
    final socket = await Socket.connect(
      host,
      _probePort,
      timeout: _probeTimeout,
    );
    socket.destroy();
    return true;
  } on SocketException catch (error) {
    return error.osError?.errorCode == _connectionRefused;
  }
}

class E2ePingTool extends StatefulWidget {
  const E2ePingTool({super.key});

  @override
  State<E2ePingTool> createState() => _E2ePingToolState();
}

class _E2ePingToolState extends State<E2ePingTool> {
  final _target = TextEditingController();
  String _result = 'idle';

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    setState(() => _result = 'pinging');
    final reachable = await _reachable(_target.text.trim());
    if (mounted) {
      setState(() => _result = reachable ? 'ok' : 'fail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'e2e_ping_target',
          container: true,
          child: TextField(controller: _target),
        ),
        Semantics(
          identifier: 'e2e_ping_button',
          container: true,
          child: TextButton(onPressed: _probe, child: const Text('E2E Ping')),
        ),
        Semantics(
          identifier: 'e2e_ping_result',
          container: true,
          child: Text(_result),
        ),
      ],
    );
  }
}
