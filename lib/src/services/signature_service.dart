import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

class SignatureService {
  /// Creates a signature for PayFast payment parameters
  ///
  /// The signature is created by following PayFast's official documentation:
  /// 1. Concatenate parameters in the order they appear in the attributes description
  /// 2. URL encode values with uppercase hex values and spaces as +
  /// 3. Add the passphrase
  /// 4. Generate an MD5 hash
  static String createSignature(Map<String, dynamic> queryParameters, String passphrase) {
    // Create parameter string
    final StringBuffer pfOutput = StringBuffer();
    
    // Convert all values to strings and filter out empty values
    final Map<String, String> cleanParams = {};
    queryParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        cleanParams[key] = value.toString().trim();
      }
    });
    
    // Add parameters to output string
    cleanParams.forEach((key, value) {
      pfOutput.write('$key=${_customUrlEncode(value)}&');
    });
    
    // Remove last ampersand
    String paramString = pfOutput.toString();
    if (paramString.endsWith('&')) {
      paramString = paramString.substring(0, paramString.length - 1);
    }
    
    // Add passphrase if provided
    if (passphrase.isNotEmpty) {
      paramString += '&passphrase=${_customUrlEncode(passphrase)}';
    }
    
    // Debug output to assist with troubleshooting
    debugPrint('PayFast signature string: $paramString');
    
    // Generate MD5 hash
    final signature = crypto.md5.convert(utf8.encode(paramString)).toString();
    debugPrint('PayFast generated signature: $signature');
    
    return signature;
  }
  
  /// Custom URL encode function to match PayFast's requirements:
  /// - Uppercase hexadecimal values
  /// - Spaces as +
  static String _customUrlEncode(String value) {
    // First do standard encoding
    String encoded = Uri.encodeComponent(value);
    
    // Replace lowercase hex with uppercase
    encoded = encoded.replaceAllMapped(RegExp(r'%[0-9a-f]{2}'), (match) {
      return match.group(0)!.toUpperCase();
    });
    
    // Replace %20 with +
    encoded = encoded.replaceAll('%20', '+');
    
    return encoded;
  }
}
