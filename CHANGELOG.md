## 2.0.2

### BREAKING CHANGES
* **Unified OpenAI Structure**: Removed `google_generative_ai` dependency and standardized all LLM providers to use OpenAI-compatible API format
* **Removed `isGemini` flag**: No longer needed as all providers use the same structure
* **Simplified API configuration**: All providers now use the same configuration pattern

### Changes
* **Removed dependencies**: Eliminated `google_generative_ai` package dependency
* **Removed GeminiService**: All providers now use the unified OpenAIService
* **Updated Message model**: Removed Gemini-specific conversion methods, kept only OpenAI format
* **Simplified LlmApi model**: Removed `isGemini` boolean flag and related logic
* **Updated UI components**: Removed Gemini-specific checkbox from configuration forms
* **Enhanced documentation**: Added comprehensive examples for all supported providers

### Migration Guide
* **Gemini users**: Update your API URL to `https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`
* **Remove `isGemini` flags**: No longer needed in LlmApi configurations
* **API compatibility**: All existing functionality preserved with unified interface

### Supported Providers
* OpenAI (GPT-4, GPT-3.5-turbo, etc.)
* Google Gemini (via OpenAI-compatible endpoints)
* Any OpenAI-compatible API service

## 0.0.1

* Initial release with dual service architecture
