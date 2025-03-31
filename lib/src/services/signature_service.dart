import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;

/// SignatureService that follows PayFast's official documentation
/// for generating payment signatures.
class SignatureService {
  /// Creates a signature exactly as specified in PayFast documentation
  static String createSignature(Map<String, dynamic> params, String passphrase) {
    // 1. Concatenate all non-blank variables in specified order with & separator
    final StringBuffer pfOutput = StringBuffer();

    params.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        // Use custom URL encoding to match PayFast's requirements
        pfOutput.write('$key=${_customUrlEncode(value.toString())}&');
      }
    });

    // Remove last & and add passphrase
    String getString = pfOutput.toString();
    if (getString.endsWith('&')) {
      getString = getString.substring(0, getString.length - 1);
    }

    if (passphrase.isNotEmpty) {
      getString += '&passphrase=${_customUrlEncode(passphrase)}';
    }

    // Debug
    debugPrint('PayFast signature string: $getString');

    // Calculate MD5 hash
    final signature = crypto.md5.convert(utf8.encode(getString)).toString();
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

  /// Creates a query string from parameters
  static String buildQueryString(Map<String, dynamic> params) {
    final queryParts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        queryParts.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });
    return queryParts.join('&');
  }
}