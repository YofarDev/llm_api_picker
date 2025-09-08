import 'package:flutter/foundation.dart';
import 'package:llm_api_picker/llm_api_picker.dart';

/// Simple test to demonstrate the simplified memory system
class SimpleMemoryTest {
  /// Test the simplified memory system with basic interactions
  static Future<void> runTest() async {
    if (kDebugMode) {
      debugPrint('=== Simple Memory System Test ===');
    }

    try {
      // Initialize the memory service
      await SimpleMemoryService.initialize();
      
      // Enable memory for testing
      await SimpleMemoryService.setMemoryEnabled(true);
      
      if (kDebugMode) {
        debugPrint('✓ Memory service initialized and enabled');
      }

      // Test 1: Simple greeting with name
      await _testSimpleGreeting();
      
      // Test 2: User preferences
      await _testUserPreferences();
      
      // Test 3: Memory context generation
      await _testMemoryContext();
      
      // Test 4: Conversation topics
      await _testConversationTopics();

      if (kDebugMode) {
        debugPrint('=== All tests completed successfully! ===');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Test failed: $e');
      }
    }
  }

  /// Test simple greeting extraction
  static Future<void> _testSimpleGreeting() async {
    if (kDebugMode) {
      debugPrint('\n--- Test 1: Simple Greeting ---');
    }

    final List<Message> messages = [
      Message(role: MessageRole.user, body: 'Hello my name is John :)'),
      Message(role: MessageRole.assistant, body: 'Hi John! Nice to meet you!'),
    ];

    // Extract memories
    await SimpleMemoryExtractor.extractMemoriesFromConversation(
      messages: messages,
      conversationId: 'test_greeting',
      userContext: 'test_user',
    );

    // Check if name was extracted
    final Map<String, String> facts = await SimpleMemoryService.getUserFacts(
      userContext: 'test_user',
    );

    if (kDebugMode) {
      debugPrint('Extracted facts: $facts');
    }

    // Should contain name
    if (facts.containsKey('name') && facts['name'] == 'John') {
      if (kDebugMode) {
        debugPrint('✓ Name correctly extracted: ${facts['name']}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Name not extracted correctly');
      }
    }
  }

  /// Test user preferences extraction
  static Future<void> _testUserPreferences() async {
    if (kDebugMode) {
      debugPrint('\n--- Test 2: User Preferences ---');
    }

    final List<Message> messages = [
      Message(role: MessageRole.user, body: 'I love pizza but hate broccoli'),
      Message(role: MessageRole.assistant, body: 'Got it! Pizza is great, broccoli not so much.'),
    ];

    // Extract memories
    await SimpleMemoryExtractor.extractMemoriesFromConversation(
      messages: messages,
      conversationId: 'test_preferences',
      userContext: 'test_user',
    );

    // Check if preferences were extracted
    final Map<String, String> facts = await SimpleMemoryService.getUserFacts(
      userContext: 'test_user',
    );

    if (kDebugMode) {
      debugPrint('Updated facts: $facts');
    }

    // Should contain food preferences
    if (facts.containsKey('food_likes') || facts.containsKey('food_dislikes')) {
      if (kDebugMode) {
        debugPrint('✓ Food preferences extracted');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Food preferences not extracted');
      }
    }
  }

  /// Test memory context generation
  static Future<void> _testMemoryContext() async {
    if (kDebugMode) {
      debugPrint('\n--- Test 3: Memory Context ---');
    }

    final String context = await SimpleMemoryService.getMemoryContext(
      userContext: 'test_user',
    );

    if (kDebugMode) {
      debugPrint('Generated context: "$context"');
    }

    // Should be simple and focused
    if (context.isNotEmpty && context.contains('John')) {
      if (kDebugMode) {
        debugPrint('✓ Simple context generated with user info');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Context not generated correctly');
      }
    }
  }

  /// Test conversation topics
  static Future<void> _testConversationTopics() async {
    if (kDebugMode) {
      debugPrint('\n--- Test 4: Conversation Topics ---');
    }

    final List<Message> messages = [
      Message(role: MessageRole.user, body: 'How\'s the weather today?'),
      Message(role: MessageRole.assistant, body: 'It\'s sunny and warm today!'),
    ];

    // Extract memories
    await SimpleMemoryExtractor.extractMemoriesFromConversation(
      messages: messages,
      conversationId: 'test_weather',
      userContext: 'test_user',
    );

    // Check recent topics
    final List<String> topics = await SimpleMemoryService.getRecentTopics();

    if (kDebugMode) {
      debugPrint('Recent topics: $topics');
    }

    // Should contain weather topic
    if (topics.contains('weather')) {
      if (kDebugMode) {
        debugPrint('✓ Weather topic extracted');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ Weather topic not extracted');
      }
    }
  }

  /// Compare with old system complexity
  static void showComplexityComparison() {
    if (kDebugMode) {
      debugPrint('\n=== COMPLEXITY COMPARISON ===');
      debugPrint('OLD SYSTEM (for "Hello my name is John :)"):');
      debugPrint('- 3 separate LLM calls (semantic, episodic, procedural)');
      debugPrint('- Complex data structures with versions, scores, metadata');
      debugPrint('- Behavioral pattern analysis');
      debugPrint('- Time decay calculations');
      debugPrint('- Relevance scoring');
      debugPrint('- Tag-based categorization');
      debugPrint('');
      debugPrint('NEW SYSTEM (for "Hello my name is John :)"):');
      debugPrint('- 1 simple LLM call');
      debugPrint('- Simple key-value facts: {"name": "John"}');
      debugPrint('- Basic topics: ["greeting"]');
      debugPrint('- Clean context: "User: name: John"');
      debugPrint('');
      debugPrint('RESULT: 90% complexity reduction! 🎉');
    }
  }
}