class ErrorResponse {
  final String? timestamp;
  final int? status;
  final String? error;
  final String? message;
  final String? path;
  final Map<String, String>? details; // Para erros de validação

  ErrorResponse({this.timestamp, this.status, this.error, this.message, this.path, this.details});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      timestamp: json['timestamp'],
      status: json['status'],
      error: json['error'],
      message: json['message'],
      path: json['path'],
      details: json['details'] != null ? Map<String, String>.from(json['details']) : null,
    );
  }
}