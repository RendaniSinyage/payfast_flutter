import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

/// PayFast service based on official documentation
class PayFastService {
  /// Generates a PayFast payment URL with proper signature
  ///
  /// Follows the exact signature generation method specified by PayFast documentation:
  /// 1. Variables in the order they appear in the attributes description
  /// 2. URL encoding in uppercase with spaces as +
  /// 3. MD5 hash of the final string with passphrase
  static String generatePaymentUrl({
    required String merchantId,
    required String merchantKey,
    required String passphrase,
    required bool production,
    required String amount,
    required String itemName,
    String? notifyUrl,
    String? returnUrl,
    String? cancelUrl,
    String? paymentId,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
  }) {
    // Create the parameters map in the correct order as per PayFast docs
    // 1. Merchant details
    final Map<String, String> params = {
      'merchant_id': merchantId,
      'merchant_key': merchantKey,
    };

    if (returnUrl != null && returnUrl.isNotEmpty) {
      params['return_url'] = returnUrl;
    }

    if (cancelUrl != null && cancelUrl.isNotEmpty) {
      params['cancel_url'] = cancelUrl;
    }

    if (notifyUrl != null && notifyUrl.isNotEmpty) {
      params['notify_url'] = notifyUrl;
    }

    // 2. Customer details
    if (firstName != null && firstName.isNotEmpty) {
      params['name_first'] = firstName;
    }

    if (lastName != null && lastName.isNotEmpty) {
      params['name_last'] = lastName;
    }

    if (email != null && email.isNotEmpty) {
      params['email_address'] = email;
    }

    if (phone != null && phone.isNotEmpty) {
      params['cell_number'] = phone;
    }

    // 3. Transaction details
    if (paymentId != null && paymentId.isNotEmpty) {
      params['m_payment_id'] = paymentId;
    }

    params['amount'] = amount;
    params['item_name'] = itemName;

    // Calculate signature according to PayFast documentation
    final signature = _createSignaturePerDocumentation(params, passphrase);
    params['signature'] = signature;

    // Debug
    debugPrint('PayFast params: ${jsonEncode(params)}');

    // Build the URL
    final host = production ? 'www.payfast.co.za' : 'sandbox.payfast.co.za';
    final queryString = _buildQueryString(params);

    return 'https://$host/eng/process?$queryString';
  }

  /// Creates a query string from parameters
  static String _buildQueryString(Map<String, String> params) {
    final queryParts = <String>[];
    params.forEach((key, value) {
      queryParts.add('$key=${Uri.encodeComponent(value)}');
    });
    return queryParts.join('&');
  }

  /// Creates a signature exactly as specified in PayFast documentation
  static String _createSignaturePerDocumentation(Map<String, String> params, String passphrase) {
    // 1. Concatenate all non-blank variables in specified order with & separator
    final StringBuffer pfOutput = StringBuffer();

    params.forEach((key, value) {
      if (value.isNotEmpty) {
        // Use custom URL encoding to match PayFast's requirements
        pfOutput.write('$key=${_customUrlEncode(value)}&');
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

  /// Helper method for enhanced payments
  static String enhancedPayment({
    required String passphrase,
    required String merchantId,
    required String merchantKey,
    required String amount,
    required String itemName,
    required bool production,
    String? notifyUrl,
    String? returnUrl,
    String? cancelUrl,
    String? paymentId,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
  }) {
    return generatePaymentUrl(
      merchantId: merchantId,
      merchantKey: merchantKey,
      passphrase: passphrase,
      production: production,
      amount: amount,
      itemName: itemName,
      notifyUrl: notifyUrl,
      returnUrl: returnUrl,
      cancelUrl: cancelUrl,
      paymentId: paymentId,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
