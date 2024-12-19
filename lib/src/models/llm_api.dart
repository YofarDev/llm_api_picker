import 'package:uuid/uuid.dart';

class LlmApi {
  String id;
  String url;
  String apiKey;
  String modelName;
  bool isGemini;
  int millisecondsDelayBetweenRequests;

  LlmApi({
    required this.id,
    required this.url,
    required this.apiKey,
    required this.modelName,
    this.isGemini = false,
    this.millisecondsDelayBetweenRequests = 0,
  });

  Map<String, dynamic> toMap() {
    return <String, String>{
      'id': id,
      'url': url,
      'apiKey': apiKey,
      'modelName': modelName,
      'isGemini': isGemini.toString(),
      'millisecondsDelayBetweenRequests':
          millisecondsDelayBetweenRequests.toString(),
    };
  }

  factory LlmApi.fromMap(Map<String, dynamic> map) {
    return LlmApi(
      id: map['id'] as String? ?? const Uuid().v4(),
      url: map['url'] as String? ?? '',
      apiKey: map['apiKey'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
      isGemini: (map['isGemini'] as String? ?? '') == 'true',
      millisecondsDelayBetweenRequests: int.tryParse(
        map['millisecondsDelayBetweenRequests'] as String? ?? '0',
      )!,
    );
  }

  @override
  String toString() {
    return 'LlmApi(id: $id, url: $url,  apiKey: $apiKey, modelName: $modelName, isGemini: $isGemini, millisecondsDelayBetweenRequests: $millisecondsDelayBetweenRequests)';
  }

  LlmApi copyWith({
    String? id,
    String? url,
    String? apiKey,
    String? modelName,
    bool? isGemini,
    int? millisecondsDelayBetweenRequests,
  }) {
    return LlmApi(
      id: id ?? this.id,
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      isGemini: isGemini ?? this.isGemini,
      millisecondsDelayBetweenRequests: millisecondsDelayBetweenRequests ??
          this.millisecondsDelayBetweenRequests,
    );
  }
}
