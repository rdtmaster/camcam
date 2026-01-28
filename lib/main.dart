import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // Ensure plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const FullPassApp());
}

class FullPassApp extends StatelessWidget {
  const FullPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const FileOutputScreen(),
    );
  }
}

class FileOutputScreen extends StatefulWidget {
  const FileOutputScreen({super.key});

  @override
  State<FileOutputScreen> createState() => _FileOutputScreenState();
}

class _FileOutputScreenState extends State<FileOutputScreen> {
  String _status = "Initializing...";
  String _filePath = "";

  @override
  void initState() {
    super.initState();
    _writeFullPass();
  }

  Future<void> _writeFullPass() async {
    try {
      // 1. Get the app's internal data directory
      final directory = await getApplicationDocumentsDirectory();
      
      // 2. Define the file path
      final file = File('${directory.path}/fullpass.txt');

      // 3. Write the content
      await file.writeAsString('fullpass');

      setState(() {
        _filePath = file.path;
        _status = "Success! 'fullpass' written to:";
      });
      
      print("File written to: ${file.path}");
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Directory Output")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _status.contains("Success") ? Icons.check_circle : Icons.error,
              size: 64,
              color: _status.contains("Success") ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SelectableText(
              _filePath,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}