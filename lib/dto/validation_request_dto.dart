class ValidationRequest {
  final String code;

  ValidationRequest({required this.code});

  Map<String, dynamic> toJson() => {
        'code': code,
      };
}