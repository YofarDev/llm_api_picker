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
  bool _memoryEnabled = false;
  bool _memoryAutoCleanup = true;
  int _memoryCleanupDays = 90;
  MemoryStats _memoryStats = MemoryStats.empty();

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
      await MemoryService.initialize();
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
      final MemoryStats stats = await MemoryService.getMemoryStatistics();
      setState(() {
        _memoryStats = stats;
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
        await MemoryService.clearAllMemories();
        await _loadMemoryStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All memories cleared successfully')),
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
      final semanticMemories = await MemoryDatabase.getAllSemanticMemories();
      final episodicMemories = await MemoryDatabase.getAllEpisodicMemories();
      final proceduralMemories = await MemoryDatabase.getAllProceduralMemories();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => _MemoryViewerDialog(
            semanticMemories: semanticMemories,
            episodicMemories: episodicMemories,
            proceduralMemories: proceduralMemories,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading memories: $e')),
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
            title: const Text('Enable Long-term Memory'),
            subtitle: const Text(
                'Allow the system to remember conversations and learn from interactions'),
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
                            'Semantic', _memoryStats.semanticCount.toString()),
                        _buildStatItem(
                            'Episodic', _memoryStats.episodicCount.toString()),
                        _buildStatItem('Procedural',
                            _memoryStats.proceduralCount.toString()),
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
                  label: const Text('View Memories'),
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

class _MemoryViewerDialog extends StatefulWidget {
  final List<SemanticMemory> semanticMemories;
  final List<EpisodicMemory> episodicMemories;
  final List<ProceduralMemory> proceduralMemories;

  const _MemoryViewerDialog({
    required this.semanticMemories,
    required this.episodicMemories,
    required this.proceduralMemories,
  });

  @override
  State<_MemoryViewerDialog> createState() => _MemoryViewerDialogState();
}

class _MemoryViewerDialogState extends State<_MemoryViewerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
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
                children: [
                  Text(
                    'Memory Viewer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
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
              tabs: [
                Tab(text: 'Semantic (${widget.semanticMemories.length})'),
                Tab(text: 'Episodic (${widget.episodicMemories.length})'),
                Tab(text: 'Procedural (${widget.proceduralMemories.length})'),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSemanticMemoriesView(),
                  _buildEpisodicMemoriesView(),
                  _buildProceduralMemoriesView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemanticMemoriesView() {
    if (widget.semanticMemories.isEmpty) {
      return const Center(child: Text('No semantic memories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.semanticMemories.length,
      itemBuilder: (context, index) {
        final memory = widget.semanticMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text('User Context: ${memory.userContext}'),
            subtitle: Text('Version: ${memory.version} | Updated: ${_formatDate(memory.updatedAt)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (memory.profileData.containsKey('preferences'))
                      _buildDataSection('Preferences', memory.profileData['preferences']),
                    if (memory.profileData.containsKey('facts'))
                      _buildDataSection('Facts', memory.profileData['facts']),
                    if (memory.profileData.containsKey('knowledge'))
                      _buildDataSection('Knowledge', memory.profileData['knowledge']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEpisodicMemoriesView() {
    if (widget.episodicMemories.isEmpty) {
      return const Center(child: Text('No episodic memories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.episodicMemories.length,
      itemBuilder: (context, index) {
        final memory = widget.episodicMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text(memory.summary),
            subtitle: Text('Relevance: ${(memory.relevanceScore * 100).toStringAsFixed(1)}% | ${_formatDate(memory.createdAt)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Context:', style: Theme.of(context).textTheme.titleSmall),
                    Text(memory.context),
                    const SizedBox(height: 8),
                    if (memory.tags.isNotEmpty) ...[
                      Text('Tags:', style: Theme.of(context).textTheme.titleSmall),
                      Wrap(
                        spacing: 4.0,
                        children: memory.tags.map((tag) => Chip(
                          label: Text(tag),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProceduralMemoriesView() {
    if (widget.proceduralMemories.isEmpty) {
      return const Center(child: Text('No procedural memories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.proceduralMemories.length,
      itemBuilder: (context, index) {
        final memory = widget.proceduralMemories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text('${memory.patternType} Pattern'),
            subtitle: Text('Success: ${(memory.successRate * 100).toStringAsFixed(1)}% | Used: ${memory.usageCount} times'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (memory.description != null) ...[
                      Text('Description:', style: Theme.of(context).textTheme.titleSmall),
                      Text(memory.description!),
                      const SizedBox(height: 8),
                    ],
                    Text('Rule Data:', style: Theme.of(context).textTheme.titleSmall),
                    _buildDataSection('', memory.ruleData),
                    const SizedBox(height: 8),
                    Text('Last Used: ${_formatDate(memory.lastUsed)}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataSection(String title, dynamic data) {
    if (data == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            data is Map ? _formatMap(data) : data.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatMap(Map<dynamic, dynamic> map) {
    final buffer = StringBuffer();
    map.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
