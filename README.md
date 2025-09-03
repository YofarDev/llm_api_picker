# llm_api_picker

Pick your backend API for your LLM.

## Description

This Flutter package allows you to easily select and manage your Large Language Model (LLM) API backend.  It simplifies the process of switching between different providers and managing API keys.

## Features

* **Multiple API Support:**  Easily switch between different LLM APIs with the OpenAI structure.
* **Long-term Memory System:**  Optional memory system that learns from conversations to provide personalized, context-aware responses.
* **Simple Integration:**  Integrate seamlessly into your Flutter application.

## Memory System

The package includes an optional long-term memory system based on LangMem concepts that enhances LLM interactions by:

* **Learning from Conversations:** Automatically extracts and stores meaningful information from interactions
* **Three Memory Types:**
  - **Semantic Memory:** User preferences, facts, and knowledge
  - **Episodic Memory:** Conversation summaries and past experiences
  - **Procedural Memory:** Successful behavioral patterns and response styles
* **Privacy-First:** All memories stored locally using SQLite - no cloud synchronization
* **User Control:** Complete enable/disable control with memory management tools
* **Automatic Context Enhancement:** Seamlessly injects relevant memory context into LLM prompts

### Memory Usage

```dart
// Memory is automatically used when enabled (default: disabled)
final response = await LLMRepository.promptModel(
  messages: conversationMessages,
  systemPrompt: "You are a helpful assistant",
);

// Explicit memory control
final response = await LLMRepository.promptModel(
  messages: conversationMessages,
  useMemory: true,
  conversationId: "project_discussion",
  userContext: "user_123",
);

// Memory management
await MemoryService.setMemoryEnabled(true);
final stats = await MemoryService.getMemoryStatistics();
```

Enable memory in your app's settings page using the built-in `LlmApiPickerSettingsPage` which includes memory controls.


## Usage

1. Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  llm_api_picker: ^1.0.0
```

2. Import the package:

```dart
import 'package:llm_api_picker/llm_api_picker.dart';
```


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
