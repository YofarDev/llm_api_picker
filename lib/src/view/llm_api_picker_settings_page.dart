import 'package:flutter/material.dart';

import '../../llm_api_picker.dart';
import 'inputs_form_llm_api_view.dart';

/// Simple memory statistics for the simplified memory system
class SimpleMemoryStats {
  final int userMemories;
  final int conversationMemories;
  final int totalMemories;

  const SimpleMemoryStats({
    required this.userMemories,
    required this.conversationMemories,
    required this.totalMemories,
  });

  static const SimpleMemoryStats empty = SimpleMemoryStats(
    userMemories: 0,
    conversationMemories: 0,
    totalMemories: 0,
  );
}

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
  bool _memoryEnabled = false;
  bool _memoryAutoCleanup = true;
  int _memoryCleanupDays = 90;
  SimpleMemoryStats _memoryStats = SimpleMemoryStats.empty;

  @override
  void initState() {
    super.initState();
    _loadLlmApis();
    _loadCurrentsApi();
    _loadMemorySettings();
    _loadMemoryStats();
    _initializeMemoryService();
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

  Future<void> _initializeMemoryService() async {
    try {
      await SimpleMemoryService.initialize();
    } catch (e) {
      // Handle initialization error silently
    }
  }

  Future<void> _loadMemorySettings() async {
    try {
      final Map<String, dynamic> settings =
          await CacheService.getMemorySettings();
      setState(() {
        _memoryEnabled = settings['enabled'] as bool;
        _memoryAutoCleanup = settings['auto_cleanup'] as bool;
        _memoryCleanupDays = settings['cleanup_days'] as int;
      });
    } catch (e) {
      // Handle error silently, keep default values
    }
  }

  Future<void> _loadMemoryStats() async {
    try {
      final Map<String, int> stats = await MemoryDatabase.getSimpleMemoryStatistics();
      setState(() {
        _memoryStats = SimpleMemoryStats(
          userMemories: stats['user_memories'] ?? 0,
          conversationMemories: stats['conversation_memories'] ?? 0,
          totalMemories: stats['total'] ?? 0,
        );
      });
    } catch (e) {
      // Handle error silently, keep empty stats
    }
  }

  Future<void> _toggleMemory(bool enabled) async {
    try {
      await CacheService.setMemoryEnabled(enabled);
      setState(() {
        _memoryEnabled = enabled;
      });
      if (enabled) {
        await _loadMemoryStats();
      }
    } catch (e) {
      // Handle error - could show a snackbar
    }
  }

  Future<void> _toggleMemoryAutoCleanup(bool enabled) async {
    try {
      await CacheService.setMemoryAutoCleanup(enabled);
      setState(() {
        _memoryAutoCleanup = enabled;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _updateMemoryCleanupDays(int days) async {
    try {
      await CacheService.setMemoryCleanupDays(days);
      setState(() {
        _memoryCleanupDays = days;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _clearAllMemories() async {
    final bool confirmed = await _showConfirmationDialog(
      'Clear All Memories',
      'This will permanently delete all stored memories. This action cannot be undone.',
    );

    if (confirmed) {
      try {
        await MemoryDatabase.clearAllSimpleMemories();
        await _loadMemoryStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All simple memories cleared successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing memories: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewMemories() async {
    if (!_memoryEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory is not enabled')),
      );
      return;
    }

    try {
      // Get all user memories
      final List<SimpleUserMemory> userMemories = [];
      try {
        final SimpleUserMemory defaultUserMemory = await SimpleMemoryService.getOrCreateUserMemory();
        if (defaultUserMemory.facts.isNotEmpty) {
          userMemories.add(defaultUserMemory);
        }
      } catch (e) {
        // Handle case where no user memory exists
      }

      // Get recent conversation memories
      final List<SimpleConversationMemory> conversationMemories =
          await MemoryDatabase.getRecentSimpleConversationMemories(limit: 20);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => _SimpleMemoryViewerDialog(
            userMemories: userMemories,
            conversationMemories: conversationMemories,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading simple memories: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<LlmApi?> _showLlmApiDialog({LlmApi? api}) {
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Memory Settings Section
            _buildMemorySettingsSection(),
            const Divider(thickness: 2),

            // LLM APIs Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'LLM APIs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (_llmApis.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No APIs configured'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLlmApi,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMemorySettingsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Memory Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Memory Enable/Disable Toggle
          SwitchListTile(
            title: const Text('Enable Simplified Memory'),
            subtitle: const Text(
                'Store essential user facts and conversation topics'),
            value: _memoryEnabled,
            onChanged: _toggleMemory,
          ),

          if (_memoryEnabled) ...<Widget>[
            const SizedBox(height: 8),

            // Memory Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Memory Statistics',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildStatItem(
                            'Total', _memoryStats.totalMemories.toString()),
                        _buildStatItem(
                            'User Facts', _memoryStats.userMemories.toString()),
                        _buildStatItem(
                            'Conversations', _memoryStats.conversationMemories.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Auto Cleanup Toggle
            SwitchListTile(
              title: const Text('Auto Cleanup'),
              subtitle: Text(
                  'Automatically clean up old memories after $_memoryCleanupDays days'),
              value: _memoryAutoCleanup,
              onChanged: _toggleMemoryAutoCleanup,
            ),

            const SizedBox(height: 8),

            // Cleanup Days Slider
            ListTile(
              title: const Text('Cleanup After (Days)'),
              subtitle: Slider(
                value: _memoryCleanupDays.toDouble(),
                min: 7,
                max: 365,
                divisions: 51,
                label: '$_memoryCleanupDays days',
                onChanged: (double value) =>
                    _updateMemoryCleanupDays(value.round()),
              ),
            ),

            const SizedBox(height: 16),

            // Memory Management Actions
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8.0,
              runSpacing: 8.0,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _loadMemoryStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Stats'),
                ),
                ElevatedButton.icon(
                  onPressed: _viewMemories,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Simple Memories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllMemories,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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

class _SimpleMemoryViewerDialog extends StatefulWidget {
  final List<SimpleUserMemory> userMemories;
  final List<SimpleConversationMemory> conversationMemories;

  const _SimpleMemoryViewerDialog({
    required this.userMemories,
    required this.conversationMemories,
  });

  @override
  State<_SimpleMemoryViewerDialog> createState() => _SimpleMemoryViewerDialogState();
}

class _SimpleMemoryViewerDialogState extends State<_SimpleMemoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: [
                      Text(
                        'Simple Memory Viewer',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '90% Simpler',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: <Widget>[
                Tab(text: 'User Facts (${widget.userMemories.length})'),
                Tab(text: 'Conversation Topics (${widget.conversationMemories.length})'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildUserFactsView(),
                  _buildConversationTopicsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFactsView() {
    if (widget.userMemories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No user facts stored yet'),
            SizedBox(height: 8),
            Text(
              'Try saying "Hello my name is John" to store your first fact!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.userMemories.length,
      itemBuilder: (BuildContext context, int index) {
        final SimpleUserMemory memory = widget.userMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text('User: ${memory.userContext}'),
            subtitle: Text('${memory.facts.length} facts | Updated: ${_formatDate(memory.updatedAt)}'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Facts:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (memory.facts.isEmpty)
                      const Text('No facts stored', style: TextStyle(color: Colors.grey))
                    else
                      ...memory.facts.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationTopicsView() {
    if (widget.conversationMemories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No conversation topics yet'),
            SizedBox(height: 8),
            Text(
              'Start chatting to see topics appear here!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.conversationMemories.length,
      itemBuilder: (BuildContext context, int index) {
        final SimpleConversationMemory memory = widget.conversationMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.chat, color: Colors.green.shade800),
            ),
            title: Text('Conversation ${memory.conversationId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_formatDate(memory.createdAt)} • ${memory.ageInDays} days ago'),
                const SizedBox(height: 4),
                if (memory.topics.isEmpty)
                  const Text('No topics', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: memory.topics.map((String topic) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    )).toList(),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
