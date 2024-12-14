class FunctionInfo {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final Function function;

  FunctionInfo({
    required this.name,
    required this.description,
    required this.parameters,
    required this.function,
  });

  FunctionInfo copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
    Function? function,
  }) {
    return FunctionInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      function: function ?? this.function,
    );
  }

  String toPromptString() {
    return '{function: $name, description: $description, parameters: $parameters}';
  }

  @override
  String toString() {
    return 'FunctionInfo(name: $name, description: $description, parameters: $parameters, function: $function)';
  }
}

extension FunctionInfoExt on List<FunctionInfo> {
  String toPromptString() {
    final StringBuffer sb = StringBuffer();
    sb.write('[');
    for (final FunctionInfo functionInfo in this) {
      sb.write(functionInfo.toPromptString());
      sb.write(',');
    }
    sb.write(']');
    return sb.toString();
  }
}
