import 'package:flutter/material.dart';
import 'package:ceramic_app/utils/validation/validators_util.dart';

typedef ValidationRuleCallback = String? Function(String? value, BuildContext context);

class ValidationBuilder {
  final List<ValidationRuleCallback> rules = [];

  ValidationBuilder add(ValidationRuleCallback validator) {
    return this..rules.add(validator);
  }

  ValidationBuilder isValidEmail() {
    return add(
          (text, context) => ValidatorsUtil.isValidEmail(text) ? null : "Inout is not a valid email",
    );
  }

  ValidationBuilder isNotBlank() {
    return add(
          (text, context) => ValidatorsUtil.isNotBlank(text) ? null : "Input cannot be blank",
    );
  }

  String? build(String? text, BuildContext context) {
    for (final rule in rules) {
      final result = rule(text, context);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}