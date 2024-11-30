import 'package:flutter/material.dart';

import '../../llm_api_picker.dart';

class LlmApiPickerSettingsPage extends StatefulWidget {
  const LlmApiPickerSettingsPage({super.key});

  @override
  State<LlmApiPickerSettingsPage> createState() =>
      _LlmApiPickerSettingsPageState();
}

class _LlmApiPickerSettingsPageState extends State<LlmApiPickerSettingsPage> {
  final List<LlmApi> _llmApis = <LlmApi>[];
  LlmApi? _currentApi;

  @override
  void initState() {
    super.initState();
    _loadLlmApis();
    _loadCurrentApi();
  }

  Future<void> _loadLlmApis() async {
    final List<LlmApi> llmApis = await LLMRepository.getSavedLlmApis();
    setState(() {
      _llmApis.addAll(llmApis);
    });
  }

  Future<void> _loadCurrentApi() async {
    final LlmApi? currentApi = await LLMRepository.getCurrentApi();
    setState(() {
      _currentApi = currentApi;
    });
  }

  Future<void> _addLlmApi() async {
    final LlmApi? newApi = await _showLlmApiDialog();
    if (newApi != null) {
      await LLMRepository.saveLlmApi(newApi);
      await _loadLlmApis();
      if (_currentApi == null) {
        await LLMRepository.setCurrentApi(newApi);
      }
    }
  }

  Future<void> _editLlmApi(LlmApi api) async {
    final LlmApi? editedApi = await _showLlmApiDialog(api: api);
    if (editedApi != null) {
      await LLMRepository.updateExistingLlmApi(editedApi);
      await _loadLlmApis();
    }
  }

  Future<void> _deleteLlmApi(LlmApi api) async {
    await LLMRepository.deleteLlmApi(api);
    await _loadLlmApis();
  }

  Future<LlmApi?> _showLlmApiDialog({LlmApi? api}) async {
    final TextEditingController nameController =
        TextEditingController(text: api?.name ?? '');
    final TextEditingController urlController =
        TextEditingController(text: api?.url ?? '');
    final TextEditingController headerApiKeyEntryController =
        TextEditingController(text: api?.headerApiKeyEntry ?? '');
    final TextEditingController apiKeyController =
        TextEditingController(text: api?.apiKey ?? '');
    final TextEditingController modelNameController =
        TextEditingController(text: api?.modelName ?? '');

    return showDialog<LlmApi>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(api == null ? 'Add LLM API' : 'Edit LLM API'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                TextField(
                  controller: headerApiKeyEntryController,
                  decoration:
                      const InputDecoration(labelText: 'Header API Key Entry'),
                ),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(labelText: 'API Key'),
                  obscureText: true,
                ),
                TextField(
                  controller: modelNameController,
                  decoration: const InputDecoration(labelText: 'Model Name'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (nameController.text.isEmpty ||
                    urlController.text.isEmpty ||
                    headerApiKeyEntryController.text.isEmpty ||
                    apiKeyController.text.isEmpty ||
                    modelNameController.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('Please fill all fields'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Ok'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                } else if (nameController.text.isNotEmpty &&
                    _llmApis.any((LlmApi x) => x.name == nameController.text)) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text('This name is already taken'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Ok'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
                Navigator.of(context).pop(
                  LlmApi(
                    name: nameController.text,
                    url: urlController.text,
                    headerApiKeyEntry: headerApiKeyEntryController.text,
                    apiKey: apiKeyController.text,
                    modelName: modelNameController.text,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLMs APIs Settings'),
      ),
      body: _llmApis.isEmpty
          ? const Center(child: Text('(empty)'))
          : ListView.builder(
              itemCount: _llmApis.length,
              itemBuilder: (BuildContext context, int index) {
                final LlmApi api = _llmApis[index];
                return ListTile(
                  leading: Checkbox(
                    value: api.name == _currentApi?.name,
                    onChanged: (bool? value) {
                      if (value == true) {
                        LLMRepository.setCurrentApi(api);
                        setState(() {
                          _currentApi = api;
                        });
                      }
                    },
                  ),
                  title: Text(api.name),
                  subtitle: Text(api.url),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editLlmApi(api),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteLlmApi(api),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLlmApi,
        child: const Icon(Icons.add),
      ),
    );
  }
}
