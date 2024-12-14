import 'package:uuid/uuid.dart';

class LlmApi {
  String id;
  String url;
  String apiKey;
  String modelName;
  bool isGemini;

  LlmApi({
    required this.id,
    required this.url,
    required this.apiKey,
    required this.modelName,
    this.isGemini = false,
  });

  Map<String, dynamic> toMap() {
    return <String, String>{
     'id': id,
      'url': url,
      'apiKey': apiKey,
      'modelName': modelName,
      'isGemini': isGemini.toString(),
    };
  }

  factory LlmApi.fromMap(Map<String, dynamic> map) {
    return LlmApi(
      id: map['id'] as String? ?? const Uuid().v4(),
      url: map['url'] as String? ?? '',
      apiKey: map['apiKey'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
      isGemini: (map['isGemini'] as String? ?? '') == 'true',
    );
  }

  @override
  String toString() {
    return 'LlmApi(id: $id, url: $url,  apiKey: $apiKey, modelName: $modelName, isGemini: $isGemini)';
  }
}
