/// Utility functions for formatting currency values
library currency_formatter;

/// Formats a double value as currency with thousands separators
/// 
/// Example:
/// - formatCurrency(1500.0) returns "1,500"
/// - formatCurrency(1234567.89) returns "1,234,568"
String formatCurrency(double amount) {
  // Round to nearest integer for display
  int roundedAmount = amount.round();
  
  // Convert to string and add thousands separators
  return roundedAmount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// Formats a double value as currency with decimal places
/// 
/// Example:
/// - formatCurrencyWithDecimals(1500.50) returns "1,500.50"
/// - formatCurrencyWithDecimals(1234567.89) returns "1,234,567.89"
String formatCurrencyWithDecimals(double amount, {int decimalPlaces = 2}) {
  // Format with specified decimal places
  String formatted = amount.toStringAsFixed(decimalPlaces);
  
  // Split into integer and decimal parts
  List<String> parts = formatted.split('.');
  String integerPart = parts[0];
  String decimalPart = parts.length > 1 ? parts[1] : '';
  
  // Add thousands separators to integer part
  String formattedInteger = integerPart.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  
  // Return with decimal part if it exists and is not zero
  if (decimalPart.isNotEmpty && double.parse('0.$decimalPart') > 0) {
    return '$formattedInteger.$decimalPart';
  } else {
    return formattedInteger;
  }
}

/// Parses a formatted currency string back to double
/// 
/// Example:
/// - parseCurrency("1,500") returns 1500.0
/// - parseCurrency("1,234,567.89") returns 1234567.89
double parseCurrency(String formattedAmount) {
  // Remove commas and parse
  String cleaned = formattedAmount.replaceAll(',', '');
  return double.tryParse(cleaned) ?? 0.0;
}
