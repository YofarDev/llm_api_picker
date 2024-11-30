class LlmApi {
  String name;
  String url;
  String headerApiKeyEntry;
  String apiKey;
  String modelName;

  LlmApi({
    required this.name,
    required this.url,
    this.headerApiKeyEntry = 'Authorization',
    required this.apiKey,
    required this.modelName,
  });

  Map<String, dynamic> toMap() {
    return <String, String>{
      'name': name,
      'url': url,
      'headerApiKeyEntry': headerApiKeyEntry,
      'apiKey': apiKey,
      'modelName': modelName,
    };
  }

  factory LlmApi.fromMap(Map<String, dynamic> map) {
    return LlmApi(
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      headerApiKeyEntry: map['headerApiKeyEntry'] as String? ?? '',
      apiKey: map['apiKey'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'LlmApi(name: $name, url: $url, headerApiKeyEntry: $headerApiKeyEntry, apiKey: $apiKey, modelName: $modelName)';
  }
}
