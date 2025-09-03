# llm_api_picker

Pick your backend API for your LLM.

## Description

This Flutter package allows you to easily select and manage your Large Language Model (LLM) API backend.  It simplifies the process of switching between different providers and managing API keys.

## Features

* **Unified OpenAI Structure:**  All LLM providers use the standardized OpenAI API format for consistency and simplicity.
* **Multiple Provider Support:**  Works with OpenAI, Gemini (via OpenAI-compatible endpoints), and any OpenAI-compatible API.
* **Long-term Memory System:**  Optional memory system that learns from conversations to provide personalized, context-aware responses.
* **Simple Integration:**  Integrate seamlessly into your Flutter application.
* **No Provider-Specific Dependencies:**  Lightweight implementation using only HTTP requests.

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
  llm_api_picker: ^2.0.2
```

2. Import the package:

```dart
import 'package:llm_api_picker/llm_api_picker.dart';
```

3. Configure your LLM APIs:

```dart
// OpenAI API
final openaiApi = LlmApi(
  id: 'openai-gpt4',
  url: 'https://api.openai.com/v1/chat/completions',
  apiKey: 'your-openai-api-key',
  modelName: 'gpt-4',
);

// Gemini via OpenAI-compatible endpoint
final geminiApi = LlmApi(
  id: 'gemini-pro',
  url: 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
  apiKey: 'your-gemini-api-key',
  modelName: 'gemini-1.5-pro',
);

// Any other OpenAI-compatible API
final customApi = LlmApi(
  id: 'custom-api',
  url: 'https://your-custom-api.com/v1/chat/completions',
  apiKey: 'your-api-key',
  modelName: 'your-model-name',
);

// Save and set as current
await LLMRepository.saveLlmApi(geminiApi);
await LLMRepository.setCurrentApi(geminiApi);
```

4. Use the unified interface:

```dart
// Create messages
final messages = [
  Message(role: MessageRole.user, body: "Hello, how are you?"),
];

// Get response (works with any configured provider)
final response = await LLMRepository.promptModel(
  messages: messages,
  systemPrompt: "You are a helpful assistant",
);

// Stream response
final stream = await LLMRepository.promptModelStream(
  messages: messages,
  systemPrompt: "You are a helpful assistant",
);

await for (final chunk in stream) {
  print(chunk);
}
```

## Supported Providers

### OpenAI
- **URL:** `https://api.openai.com/v1/chat/completions`
- **Models:** `gpt-4`, `gpt-4-turbo`, `gpt-3.5-turbo`, etc.
- **API Key:** Your OpenAI API key

### Google Gemini (via OpenAI-compatible endpoint)
- **URL:** `https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`
- **Models:** `gemini-1.5-pro`, `gemini-1.5-flash`, `gemini-1.0-pro`, etc.
- **API Key:** Your Google AI Studio API key

### Other OpenAI-Compatible APIs
Any service that implements the OpenAI chat completions API format, including:
- Azure OpenAI Service
- Anthropic Claude (via proxy)
- Local LLM servers (Ollama, LM Studio, etc.)
- Custom API implementations

## Migration from v1.x

If you're upgrading from v1.x, the main changes are:

1. **Removed `google_generative_ai` dependency** - Now uses HTTP requests for all providers
2. **Simplified API configuration** - No more `isGemini` flag needed
3. **Unified message format** - All providers use OpenAI message structure
4. **Gemini integration** - Now uses Gemini's OpenAI-compatible endpoints

To migrate:
1. Update your Gemini API configurations to use the OpenAI-compatible URL
2. Remove any `isGemini: true` flags from your `LlmApi` configurations
3. All existing functionality remains the same


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
