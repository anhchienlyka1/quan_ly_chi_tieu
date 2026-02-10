/// Form validation utilities.
class Validators {
  Validators._();

  /// Validate that the field is not empty
  static String? required(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  /// Validate that the value is a valid positive number
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    final number = num.tryParse(cleaned);
    if (number == null || number <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }
    return null;
  }

  /// Validate max length
  static String? maxLength(String? value, int maxLength) {
    if (value != null && value.length > maxLength) {
      return 'Tối đa $maxLength ký tự';
    }
    return null;
  }
}
