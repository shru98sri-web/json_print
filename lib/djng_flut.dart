import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// void main() {
//   runApp(const SingleFileApp());
// }

class SingleFileApp extends StatelessWidget {
  const SingleFileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Single File Python + Flutter'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const NetworkInterfaceView(),
      ),
    );
  }
}

class NetworkInterfaceView extends StatefulWidget {
  const NetworkInterfaceView({super.key});

  @override
  State<NetworkInterfaceView> createState() => _NetworkInterfaceViewState();
}

class _NetworkInterfaceViewState extends State<NetworkInterfaceView> {
  String _serverOutput = "No data fetched yet.";
  bool _isRequesting = false;

  Future<void> _fetchServerPayload() async {
    setState(() => _isRequesting = true);

    // 💡 CONNECTION DEVICE ROUTING CONFIGURATION:
    // Android Emulator IP -> 'http://10.0.2'
    // iOS / Desktop Web IP -> 'http://localhost:8000/api/data'
    final Uri targetEndpoint = Uri.parse('ngrok forwarding url from ngrok terminal command /api/data');
    //http://0.0.0.0:8000/api/data
    //192.168.1.41:8000/api/data

    try {
      final response = await http.get(targetEndpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);
        setState(() {
          _serverOutput = "Message: ${dataMap['message']}\nStatus: ${dataMap['status']}\nTime: ${dataMap['timestamp']}";
        });
      } else {
        setState(() => _serverOutput = "Server returned failure code: ${response.statusCode}");
      }
    } catch (networkError) {
      setState(() => _serverOutput = "Connection Failed!\nDid you forget to run 'python server.py'?\nDetails: $networkError");
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isRequesting
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : Text(
                _serverOutput,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace', color: Colors.black87),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isRequesting ? null : _fetchServerPayload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              icon: const Icon(Icons.sync_alt),
              label: const Text('Trigger Python Call', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
