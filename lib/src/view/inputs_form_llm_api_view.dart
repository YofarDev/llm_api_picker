import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../llm_api_picker.dart';

class InputsFormLlmApiView extends StatefulWidget {
  final LlmApi? api;

  const InputsFormLlmApiView({
    super.key,
    this.api,
  });

  @override
  _InputsFormLlmApiViewState createState() => _InputsFormLlmApiViewState();
}

class _InputsFormLlmApiViewState extends State<InputsFormLlmApiView> {
  late LlmApi _api;
  late final TextEditingController urlController =
      TextEditingController(text: _api.url);
  late final TextEditingController apiKeyController =
      TextEditingController(text: _api.apiKey);
  late final TextEditingController modelNameController =
      TextEditingController(text: _api.modelName);
  late final TextEditingController delayController = TextEditingController(
    text: _api.millisecondsDelayBetweenRequests.toString(),
  );

  @override
  void initState() {
    super.initState();
    _api = widget.api ??
        LlmApi(
          id: const Uuid().v4(),
          url: '',
          apiKey: '',
          modelName: '',
        );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.api == null ? 'Add LLM API' : 'Edit LLM API'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            TextField(
              controller: modelNameController,
              decoration: const InputDecoration(labelText: 'Model Name'),
            ),
            TextField(
              controller: delayController,
              decoration: const InputDecoration(
                labelText: 'Delay between requests (milliseconds)',
              ),
              keyboardType: TextInputType.number,
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
            if (urlController.text.isEmpty ||
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
            }
            final LlmApi api = LlmApi(
              id: _api.id,
              url: urlController.text,
              apiKey: apiKeyController.text,
              modelName: modelNameController.text,
              millisecondsDelayBetweenRequests: int.tryParse(
                delayController.text,
              ) ?? 0,
            );
            Navigator.of(context).pop(
              api,
            );
          },
        ),
      ],
    );
  }
}
