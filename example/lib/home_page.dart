import 'package:flutter/material.dart';
import 'package:llm_api_picker/llm_api_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _answer;
  bool _isMemoryEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadMemoryState();
  }

  Future<void> _loadMemoryState() async {
    _isMemoryEnabled = await SimpleMemoryService.isMemoryEnabled();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM API Picker Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) =>
                      const LlmApiPickerSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            if (_answer != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_answer!),
                  ],
                ),
              ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 400,
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter your prompt',
                  ),
                  onSubmitted: (String value) async {
                    final LlmApi? api = await LLMRepository.getCurrentApi();
                    if (api == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please configure an API first in settings',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    try {
                      _answer = await LLMRepository.promptModel(
                        messages: [
                          Message(role: MessageRole.user, body: value),
                        ],
                        api: api,
                        debugLogs: true,
                        useMemory: _isMemoryEnabled,
                      );
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
