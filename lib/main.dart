import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const WordListScreen(),
    );
  }
}

// 1. Data Model exactly aligned with your specific JSON key schemas
class WordModel {
  final String word;
  final String definition;
  final String example;
  final String status; // 👈 Updated from bool to String to match your "current_status" key safely

  WordModel({
    required this.word,
    required this.definition,
    required this.example,
    required this.status,
  });

  // Factory constructor to safely parse dynamic server response payloads
  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      status: json['current_status'] ?? json['status'] ?? 'reviewing', // 👈 Grabs "current_status" from database
    );
  }
}

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  // Configured with the explicit server port destination rule checked previously
  final String apiUrl = "http://192.168.1.37:8000/api/words";
// Inside your _WordListScreenState class:

  // 2. Repaired fetch function navigating the inner JSON 'words' map block safely
  Future<List<WordModel>> fetchWords() async {
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Decode the data safely from UTF-8 format bytes
        final Map<String, dynamic> decodedData = json.decode(utf8.decode(response.bodyBytes));

        // 👈 FIX: Extracted the nested 'words' List out from the root JSON Map safely
        final List<dynamic> wordListJson = decodedData['words'] ?? [];

        // Map every JSON item to a WordModel instance
        return wordListJson.map((item) => WordModel.fromJson(item)).toList();
      } else {
        throw Exception("Server returned error response code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Could not resolve network connection to backend server: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Dictionary'),
        elevation: 2,
      ),
      body: FutureBuilder<List<WordModel>>(
        future: fetchWords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            final words = snapshot.data!;

            if (words.isEmpty) {
              return const Center(child: Text('No words inside your dictionary yet.'));
            }

            // 3. Render the UI using a custom list of cards
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final currentWord = words[index];

                // Heuristic evaluation to format badge checks smoothly
                final bool isEstablished = currentWord.status.toLowerCase().contains('established');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word title & Learned status checkbox/indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentWord.word,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Simple visual badge for "status" parameters mapping
                            Chip(
                              label: Text(
                                isEstablished ? "Established" : "Reviewing",
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: isEstablished
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Definition block
                        const Text(
                          "Definition:",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          currentWord.definition,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        // Example block
                        const Text(
                          "Example:",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          '"${currentWord.example}"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Unexpected state. No data found.'));
        },
      ),
    );
  }
}
