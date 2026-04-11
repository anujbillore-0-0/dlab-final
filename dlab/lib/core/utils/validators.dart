class Validators {
  Validators._();

  static String? requiredText(String? v, {String message = 'Required'}) {
    if ((v ?? '').trim().isEmpty) return message;
    return null;
  }
}
