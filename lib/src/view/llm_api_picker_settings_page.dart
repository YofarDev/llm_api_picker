import 'package:flutter/material.dart';

import '../../llm_api_picker.dart';
import 'inputs_form_llm_api_view.dart';

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
    _llmApis.clear();
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
    return showDialog<LlmApi>(
      context: context,
      builder: (BuildContext context) {
        return InputsFormLlmApiView(api: api);
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
                    value: api.id == _currentApi?.id,
                    onChanged: (bool? value) {
                      if (value == true) {
                        LLMRepository.setCurrentApi(api);
                        setState(() {
                          _currentApi = api;
                        });
                      }
                    },
                  ),
                  title: Text(api.modelName),
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
