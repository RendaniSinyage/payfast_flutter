import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
//juvo
class SignatureService {
  /// Creates a signature for PayFast payment parameters
  ///
  /// The signature is created by:
  /// 1. Sorting all parameters alphabetically by key
  /// 2. Concatenating all parameter key-value pairs with & between each pair
  /// 3. Appending the passphrase with a leading &
  /// 4. Generating an MD5 hash of the resulting string
  static String createSignature(Map<String, dynamic> queryParameters, String passphrase) {
    // Create a copy of the parameters to avoid modifying the original
    final params = Map<String, String>.from(queryParameters.map(
      (key, value) => MapEntry(key, value?.toString() ?? '')
    ));
    
    // Filter out null values and empty strings
    params.removeWhere((key, value) => value == null || value.isEmpty);
    
    // Sort keys alphabetically
    final sortedKeys = params.keys.toList()..sort();
    
    // Build parameter string
    final parameterString = sortedKeys.map((key) {
      final value = params[key]!;
      return '$key=$value';
    }).join('&');
    
    // Add passphrase
    final signatureString = passphrase.isNotEmpty 
        ? '$parameterString&passphrase=$passphrase'
        : parameterString;
    
    // Debug output to assist with troubleshooting
    debugPrint('PayFast signature string: $signatureString');
    
    // Generate MD5 hash
    final signature = crypto.md5.convert(utf8.encode(signatureString)).toString();
    debugPrint('PayFast generated signature: $signature');
    
    return signature;
  }
}
