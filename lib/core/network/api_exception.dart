class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors});

  /// Returns the first validation error message if present, else [message].
  String get displayMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.first.first;
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
