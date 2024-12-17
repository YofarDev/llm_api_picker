class FunctionInfo {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final FunctionInfo? nextStep;
  final Function function;

  FunctionInfo({
    required this.name,
    required this.description,
    required this.parameters,
    this.nextStep,
    required this.function,
  });

  FunctionInfo copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
    FunctionInfo? nextStep,
    Function? function,
  }) {
    return FunctionInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      nextStep: nextStep ?? this.nextStep,
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

  bool get isMultiStep => nextStep != null;
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

  String toMultiStepPromptString() {
    final StringBuffer sb = StringBuffer();
    sb.write('[');
    for (final FunctionInfo functionInfo in this) {
      if (!functionInfo.isMultiStep) continue;
      sb.write(_buildStepString(functionInfo));
      sb.write(',');
    }
    sb.write(']');
    return sb.toString();
  }

  String _buildStepString(FunctionInfo functionInfo) {
    final StringBuffer stepSb = StringBuffer();
    stepSb.write(functionInfo.name);
    FunctionInfo? nextStep = functionInfo.nextStep;
    while (nextStep != null) {
      stepSb.write(' > ${nextStep.name}');
      nextStep = nextStep.nextStep;
    }
    return stepSb.toString();
  }

  FunctionInfo getFunctionInfo(String name) {
    final FunctionInfo functionInfo = firstWhere(
      (FunctionInfo e) => e.name == name,
      orElse: () => throw ArgumentError('Function not found: $name'),
    );
    return functionInfo;
  }
}
