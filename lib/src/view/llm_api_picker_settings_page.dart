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
  LlmApi? _currentSmallApi;

  @override
  void initState() {
    super.initState();
    _loadLlmApis();
    _loadCurrentsApi();
  }

  Future<void> _loadLlmApis() async {
    _llmApis.clear();
    final List<LlmApi> llmApis = await LLMRepository.getSavedLlmApis();
    setState(() {
      _llmApis.addAll(llmApis);
    });
  }

  Future<void> _loadCurrentsApi() async {
    final LlmApi? currentApi = await LLMRepository.getCurrentApi();
    final LlmApi? currentSmallApi = await LLMRepository.getCurrentSmallApi();
    setState(() {
      _currentApi = currentApi;
      _currentSmallApi = currentSmallApi;
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

  Future<LlmApi?> _showLlmApiDialog({LlmApi? api})  {
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
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildCheckbox(
                            label: 'current API',
                            value: api.id == _currentApi?.id,
                            color: Colors.deepPurpleAccent,
                            onChanged: (bool? value) {
                              if (value == true) {
                                LLMRepository.setCurrentApi(api);
                                setState(() {
                                  _currentApi = api;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildCheckbox(
                            label: 'small API',
                            value: api.id == _currentSmallApi?.id,
                            color: Colors.pinkAccent,
                            onChanged: (bool? value) {
                              if (value == true) {
                                LLMRepository.setCurrentSmallApi(api);
                                setState(() {
                                  _currentSmallApi = api;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListTile(
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
                        ),
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

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool? value) onChanged,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 16,
          width: 16,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
