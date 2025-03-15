import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

class SignatureService {
  /// Creates a signature for PayFast payment parameters following PayFast documentation
  ///
  /// The signature is created by:
  /// 1. Concatenating parameters in the order they appear in the PayFast documentation
  /// 2. URL encoding values with uppercase hexadecimal values
  /// 3. Adding the passphrase
  /// 4. Calculating an MD5 hash of the result
  static String createSignature(Map<String, dynamic> queryParameters, String passphrase) {
    // Create parameter string in the order of PayFast documentation
    final StringBuffer pfOutput = StringBuffer();
    
    // Convert all values to strings and filter out empty values
    final Map<String, String> cleanParams = {};
    queryParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        cleanParams[key] = value.toString().trim();
      }
    });
    
    // Add parameters in correct order to match PayFast documentation
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

// payfast.dart
import 'enums/frequency_cycle_period.dart';
import 'enums/payment_type.dart';
import 'enums/recurring_payment_types.dart';
import 'models/billing_types/recurring_billing.dart';
import 'models/billing_types/recurring_billing_types/subscription_payment.dart';
import 'models/billing_types/recurring_billing_types/tokenization_billing.dart';
import 'models/billing_types/simple_billing.dart';
import 'models/merchant_details.dart';
import 'signature_service.dart';
import 'package:flutter/foundation.dart';

class Payfast {
  String passphrase;
  PaymentType paymentType;
  bool production;

  RecurringBilling? recurringBilling;
  SimpleBilling? simpleBilling;
  MerchantDetails merchantDetails;

  // Customer details
  String? emailAddress;
  String? cellNumber;
  String? nameFirst;
  String? nameLast;

  Payfast({
    required this.passphrase,
    required this.paymentType,
    required this.production,
    required this.merchantDetails,
    this.emailAddress,
    this.cellNumber,
    this.nameFirst,
    this.nameLast,
  });

  String generateURL() {
    Map<String, dynamic> queryParameters = {};

    // Simple Payment
    if (paymentType == PaymentType.simplePayment) {
      // Add merchant details first
      queryParameters.addAll(merchantDetails.toMap());
      
      // Add payment details
      queryParameters['amount'] = simpleBilling?.amount;
      queryParameters['item_name'] = simpleBilling?.itemName;
      
      // Add customer details if provided
      if (emailAddress != null && emailAddress!.isNotEmpty) {
        queryParameters['email_address'] = emailAddress;
      }

      if (cellNumber != null && cellNumber!.isNotEmpty) {
        queryParameters['cell_number'] = cellNumber;
      }

      if (nameFirst != null && nameFirst!.isNotEmpty) {
        queryParameters['name_first'] = nameFirst;
      }

      if (nameLast != null && nameLast!.isNotEmpty) {
        queryParameters['name_last'] = nameLast;
      }
    }
    // Recurring Billing
    else if (paymentType == PaymentType.recurringBilling) {
      // Subscription
      if (recurringBilling?.recurringPaymentType == RecurringPaymentType.subscription) {
        // Add merchant details first
        queryParameters.addAll(merchantDetails.toMap());
        
        // Add subscription details
        queryParameters['amount'] = recurringBilling?.subscriptionPayment?.amount;
        queryParameters['item_name'] = recurringBilling?.subscriptionPayment?.itemName;
        queryParameters['subscription_type'] = recurringBilling?.subscriptionPayment?.subscriptionsType;
        queryParameters['billing_date'] = recurringBilling?.subscriptionPayment?.billingDate;
        queryParameters['recurring_amount'] = recurringBilling?.subscriptionPayment?.recurringAmount;
        queryParameters['frequency'] = recurringBilling?.subscriptionPayment?.frequency;
        queryParameters['cycles'] = recurringBilling?.subscriptionPayment?.cycles;
        
        // Add customer details if provided
        if (emailAddress != null && emailAddress!.isNotEmpty) {
          queryParameters['email_address'] = emailAddress;
        }

        if (cellNumber != null && cellNumber!.isNotEmpty) {
          queryParameters['cell_number'] = cellNumber;
        }

        if (nameFirst != null && nameFirst!.isNotEmpty) {
          queryParameters['name_first'] = nameFirst;
        }

        if (nameLast != null && nameLast!.isNotEmpty) {
          queryParameters['name_last'] = nameLast;
        }
      }
      // Tokenization
      else if (recurringBilling?.recurringPaymentType == RecurringPaymentType.tokenization) {
        // Add merchant details first
        queryParameters.addAll(merchantDetails.toMap());
        
        // Add tokenization details
        queryParameters['amount'] = recurringBilling?.tokenizationBilling?.amount ?? '250';
        queryParameters['item_name'] = recurringBilling?.tokenizationBilling?.itemName ?? 'Netflix';
        queryParameters['subscription_type'] = recurringBilling?.tokenizationBilling?.subscriptionType;
        
        // Add customer details if provided
        if (emailAddress != null && emailAddress!.isNotEmpty) {
          queryParameters['email_address'] = emailAddress;
        }

        if (cellNumber != null && cellNumber!.isNotEmpty) {
          queryParameters['cell_number'] = cellNumber;
        }

        if (nameFirst != null && nameFirst!.isNotEmpty) {
          queryParameters['name_first'] = nameFirst;
        }

        if (nameLast != null && nameLast!.isNotEmpty) {
          queryParameters['name_last'] = nameLast;
        }
      } else {
        throw Exception("Payment type not selected");
      }
    }

    // Remove null values
    queryParameters.removeWhere((key, value) => value == null || value.toString().isEmpty);
    
    // Calculate signature
    String signature = SignatureService.createSignature(queryParameters, passphrase);
    queryParameters['signature'] = signature;
    
    // Debug log
    debugPrint('PayFast parameters: ${jsonEncode(queryParameters)}');

    // Build the URL with proper host
    final host = production ? 'www.payfast.co.za' : 'sandbox.payfast.co.za';
    final uri = Uri(
      scheme: 'https',
      host: host,
      path: '/eng/process',
      queryParameters: queryParameters,
    );
    
    return uri.toString();
  }

  void createSimplePayment({
    required String amount,
    required String itemName,
  }) {
    simpleBilling = SimpleBilling(
      amount: amount,
      itemName: itemName,
    );
  }

  void setRecurringBillingType(RecurringPaymentType recurringPaymentType) {
    recurringBilling =
        RecurringBilling(recurringPaymentType: recurringPaymentType);
  }

  void setupRecurringBillingSubscription({
    required int amount,
    required String itemName,
    required String billingDate,
    required int cycles,
    required FrequencyCyclePeriod cyclePeriod,
    required int recurringAmount,
  }) {
    recurringBilling!.subscriptionPayment = SubscriptionPayment(
      amount: amount.toString(),
      itemName: itemName,
      billingDate: billingDate,
      recurringAmount: recurringAmount.toString(),
      frequency: (cyclePeriod.index + 3).toString(),
      cycles: cycles.toString(),
    );
  }

  void setupRecurringBillingTokenization([
    int? amount,
    String? itemName,
  ]) {
    recurringBilling!.tokenizationBilling = TokenizationBilling(
      amount?.toString(),
      itemName,
    );
  }

  void chargeTokenization() {
    Map<String, dynamic> recurringTokenizationQueryParameters = {
      'token': '3ee21522-7cc9-464d-837a-3e791c5a6f1d',
      'merchant-id': '10026561',
      'version': 'v1',
      'timestamp': '2022-07-25',
      'amount': '444',
      'item_name': 'Netflix',
    };

    Map<String, dynamic> signatureEntry = {
      'signature': SignatureService.createSignature(
          recurringTokenizationQueryParameters, passphrase),
    };

    recurringTokenizationQueryParameters.addEntries(signatureEntry.entries);
  }
}
