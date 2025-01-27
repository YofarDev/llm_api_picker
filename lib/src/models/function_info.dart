import 'dart:convert';

class FunctionInfo {
  final String name;
  final String description;
  final List<Parameter> parameters;
  final FunctionInfo? nextStep;
  final Function function;
  final Map<String, dynamic>? parametersCalled;

  FunctionInfo({
    required this.name,
    required this.description,
    required this.parameters,
    this.nextStep,
    required this.function,
    this.parametersCalled,
  });

  FunctionInfo copyWith({
    String? name,
    String? description,
    List<Parameter>? parameters,
    FunctionInfo? nextStep,
    Function? function,
    Map<String, dynamic>? parametersCalled,
  }) {
    return FunctionInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      nextStep: nextStep ?? this.nextStep,
      function: function ?? this.function,
      parametersCalled: parametersCalled ?? this.parametersCalled,
    );
  }

  String toPromptString() {
    final StringBuffer p = StringBuffer();
    for (final Parameter parameter in parameters) {
      p.write(parameter.toMap().toString());
    }
    return '{function: $name, description: $description, parameters: $p}';
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

class Parameter {
  final String name;
  final String type;
  final String description;

  Parameter({
    required this.name,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'description': description,
    };
  }

  factory Parameter.fromMap(Map<String, dynamic> map) {
    return Parameter(
      name: map['name'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Parameter.fromJson(String source) =>
      Parameter.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Parameter(name: $name, type: $type, description: $description)';
}
