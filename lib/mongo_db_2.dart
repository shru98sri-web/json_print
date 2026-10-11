import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

// ============================================================================
// DATABASE CONFIGISTRATION & SERVICE LAYER
// ============================================================================
class MongoService {
  static mongo.Db? _db;
  static mongo.DbCollection? _collection;

  // ⚠️ TODO: Replace with your actual MongoDB Atlas connection string URI
  // Remember to replace <username> and <password> with your database user details
  static const String mongoUrl =
      "mongodb+srv://<username>:<password>@cluster0.8sr6god.mongodb.net/?appName=Cluster0";

  // Establishes a socket connection to MongoDB Atlas
  static Future<void> connect() async {
    try {
      _db = await mongo.Db.create(mongoUrl);
      await _db!.open();
      _collection = _db!.collection('test_collection');
      debugPrint("Successfully connected to MongoDB Atlas!");
    } catch (e) {
      debugPrint("Error connecting to database: $e");
    }
  }

  // Inserts a single document into the collection
  static Future<String> insertDocument(String name, String role) async {
    if (_collection == null) return "Database not connected";

    try {
      var result = await _collection!.insertOne({
        "name": name,
        "role": role,
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (result.isSuccess) {
        return "Success! Inserted document ID: ${result.id}";
      } else {
        return "Failed to insert document.";
      }
    } catch (e) {
      return "Insertion Error: $e";
    }
  }

  // Retrieves all documents from the collection
  static Future<List<Map<String, dynamic>>> fetchDocuments() async {
    if (_collection == null) return [];
    try {
      return await _collection!.find().toList();
    } catch (e) {
      debugPrint("Error fetching data: $e");
      return [];
    }
  }

  // Gracefully shuts down the connection pool
  static Future<void> close() async {
    await _db?.close();
  }
}

// ============================================================================
// APPLICATION ENTRY POINT
// ============================================================================
void main() async {
  // Ensures standard plugin bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Establish connection to Atlas pool on app boot
  await MongoService.connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Mongo Direct Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MongoHomeScreen(),
    );
  }
}

// ============================================================================
// USER INTERFACE LAYER
// ============================================================================
class MongoHomeScreen extends StatefulWidget {
  const MongoHomeScreen({super.key});

  @override
  State<MongoHomeScreen> createState() => _MongoHomeScreenState();
}

class _MongoHomeScreenState extends State<MongoHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  String _statusMessage = "Status: Connected & Ready";
  List<Map<String, dynamic>> _displayData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData(); // Fetch existing records on launch
  }

  // Handles reading documents from the Atlas cluster
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    var data = await MongoService.fetchDocuments();
    setState(() {
      _displayData = data;
      _isLoading = false;
    });
  }

  // Handles validation and calling insertion service
  Future<void> _handleInsert() async {
    if (_nameController.text.trim().isEmpty || _roleController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = "Status: Please fill out both fields";
      });
      return;
    }

    setState(() {
      _statusMessage = "Status: Transmitting data...";
      _isLoading = true;
    });

    String response = await MongoService.insertDocument(
      _nameController.text.trim(),
      _roleController.text.trim(),
    );

    setState(() {
      _statusMessage = "Status: $response";
    });

    _nameController.clear();
    _roleController.clear();

    // Automatically pull down updated collection records
    _refreshData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    MongoService.close(); // Safeguard database pool connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MongoDB Atlas Integration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Fields Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Role / Designation',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Operational Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleInsert,
                    icon: const Icon(Icons.add),
                    label: const Text('Insert Doc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Sync View'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Console / Status Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade800),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // List View Header
            const Text(
              "Atlas Cluster Documents:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Reactive Data List Render
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayData.isEmpty
                  ? const Center(child: Text("No items inside cluster collection."))
                  : ListView.builder(
                itemCount: _displayData.length,
                itemBuilder: (context, index) {
                  final item = _displayData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.description)),
                      title: Text(item['name'] ?? 'Unknown'),
                      subtitle: Text("Role: ${item['role'] ?? 'N/A'}"),
                      trailing: Text(
                        item['_id'] != null
                            ? item['_id'].toString().replaceFirst('ObjectId("', '').substring(0, 8)
                            : '',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
