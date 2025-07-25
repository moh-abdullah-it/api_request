class ApiError {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.message,
    this.code,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('ApiError: $message');
    if (code != null) buffer.write(' (Code: $code)');
    if (details != null) buffer.write(' Details: $details');
    return buffer.toString();
  }
}