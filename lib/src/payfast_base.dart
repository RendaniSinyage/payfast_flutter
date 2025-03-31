import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:payfast/src/models/billing_types/recurring_billing_types/subscription_payment.dart';
import 'package:payfast/src/models/billing_types/recurring_billing_types/tokenization_billing.dart';
import 'package:payfast/src/models/merchant_details.dart';
import 'package:payfast/src/services/signature_service.dart';
import 'package:payfast/src/enums/enums.dart';

import 'models/billing_types/recurring_billing.dart';
import 'models/billing_types/simple_billing.dart';

class Payfast {
  String passphrase;
  PaymentType paymentType;
  bool production;

  RecurringBilling? recurringBilling;
  SimpleBilling? simpleBilling;
  MerchantDetails merchantDetails;

  // Customer details
  String? email;
  String? phone;
  String? firstName;
  String? lastName;

  // Custom fields
  String? customStr1;
  String? customStr2;
  String? customStr3;
  String? customStr4;
  String? customInt1;
  String? customInt2;

  Payfast({
    required this.passphrase,
    required this.paymentType,
    required this.production,
    required this.merchantDetails,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.customStr1,
    this.customStr2,
    this.customStr3,
    this.customStr4,
    this.customInt1,
    this.customInt2,
  });

  String generateURL() {
    switch (paymentType) {
      case PaymentType.simplePayment:
        return _generateSimplePaymentUrl();
      case PaymentType.recurringBilling:
        return _generateRecurringBillingUrl();
      default:
        throw Exception("Payment type not selected");
    }
  }

  String _generateSimplePaymentUrl() {
    if (simpleBilling == null) {
      throw Exception("Simple billing not configured. Call createSimplePayment() first.");
    }

    return generatePaymentUrl(
      merchantId: merchantDetails.merchantId,
      merchantKey: merchantDetails.merchantKey,
      passphrase: passphrase,
      production: production,
      amount: simpleBilling!.amount,
      itemName: simpleBilling!.itemName,
      notifyUrl: merchantDetails.notifyUrl,
      returnUrl: merchantDetails.returnUrl,
      cancelUrl: merchantDetails.cancelUrl,
      paymentId: merchantDetails.paymentId,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      customStr1: customStr1,
      customStr2: customStr2,
      customStr3: customStr3,
      customStr4: customStr4,
      customInt1: customInt1,
      customInt2: customInt2,
    );
  }

  String _generateRecurringBillingUrl() {
    if (recurringBilling == null) {
      throw Exception("Recurring billing not configured. Call setRecurringBillingType() first.");
    }

    switch (recurringBilling!.recurringPaymentType) {
      case RecurringPaymentType.subscription:
        return _generateSubscriptionUrl();
      case RecurringPaymentType.tokenization:
        return _generateTokenizationUrl();
      default:
        throw Exception("Recurring payment type not selected");
    }
  }

  String _generateSubscriptionUrl() {
    if (recurringBilling?.subscriptionPayment == null) {
      throw Exception("Subscription payment not configured. Call setupRecurringBillingSubscription() first.");
    }

    final subscriptionPayment = recurringBilling!.subscriptionPayment!;

    // Create parameters map for subscription
    final Map<String, dynamic> params = {
      ...merchantDetails.toMap(),
      'amount': subscriptionPayment.amount,
      'item_name': subscriptionPayment.itemName,
      'subscription_type': subscriptionPayment.subscriptionsType,
      'billing_date': subscriptionPayment.billingDate,
      'recurring_amount': subscriptionPayment.recurringAmount,
      'frequency': subscriptionPayment.frequency,
      'cycles': subscriptionPayment.cycles,
    };

    // Add customer details if provided
    if (email != null) params['email_address'] = email;
    if (phone != null) params['cell_number'] = phone;
    if (firstName != null) params['name_first'] = firstName;
    if (lastName != null) params['name_last'] = lastName;

    // Add custom fields if provided
    if (customStr1 != null) params['custom_str1'] = customStr1;
    if (customStr2 != null) params['custom_str2'] = customStr2;
    if (customStr3 != null) params['custom_str3'] = customStr3;
    if (customStr4 != null) params['custom_str4'] = customStr4;
    if (customInt1 != null) params['custom_int1'] = customInt1;
    if (customInt2 != null) params['custom_int2'] = customInt2;

    // Calculate signature
    final signature = SignatureService.createSignature(params, passphrase);
    params['signature'] = signature;

    // Debug
    debugPrint('PayFast subscription params: ${jsonEncode(params)}');

    // Build the URL
    final host = production ? 'www.payfast.co.za' : 'sandbox.payfast.co.za';
    final queryString = SignatureService.buildQueryString(params);

    return 'https://$host/eng/process?$queryString';
  }

  String _generateTokenizationUrl() {
    if (recurringBilling?.tokenizationBilling == null) {
      throw Exception("Tokenization billing not configured. Call setupRecurringBillingTokenization() first.");
    }

    final tokenizationBilling = recurringBilling!.tokenizationBilling!;

    // Use default values if not provided
    final amount = tokenizationBilling.amount ?? '0.00';
    final itemName = tokenizationBilling.itemName ?? 'Tokenization';

    return generatePaymentUrl(
      merchantId: merchantDetails.merchantId,
      merchantKey: merchantDetails.merchantKey,
      passphrase: passphrase,
      production: production,
      amount: amount,
      itemName: itemName,
      notifyUrl: merchantDetails.notifyUrl,
      returnUrl: merchantDetails.returnUrl,
      cancelUrl: merchantDetails.cancelUrl,
      paymentId: merchantDetails.paymentId,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      subscriptionType: '2', // 2 is for tokenization
      customStr1: customStr1,
      customStr2: 'tokenize', // Mark tokenization requests
      customStr3: customStr3,
      customStr4: customStr4,
      customInt1: customInt1,
      customInt2: customInt2,
    );
  }

  String generateTokenPaymentUrl({
    required String token,
    required String amount,
    required String itemName,
  }) {
    // Create API endpoint for token payment
    final host = production ? 'api.payfast.co.za' : 'sandbox.payfast.co.za';

    // For a complete implementation, you would need to implement the full token payment API call
    // This is just the endpoint construction
    return 'https://$host/subscriptions/$token/adhoc';
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
    recurringBilling = RecurringBilling(recurringPaymentType: recurringPaymentType);
  }

  void setupRecurringBillingSubscription({
    required int amount,
    required String itemName,
    required String billingDate,
    required int cycles,
    required FrequencyCyclePeriod cyclePeriod,
    required int recurringAmount,
    String? customStr4,
  }) {
    if (recurringBilling == null) {
      throw Exception("Call setRecurringBillingType(RecurringPaymentType.subscription) first");
    }

    recurringBilling!.subscriptionPayment = SubscriptionPayment(
      amount: amount.toString(),
      itemName: itemName,
      billingDate: billingDate,
      recurringAmount: recurringAmount.toString(),
      frequency: (cyclePeriod.index + 3).toString(),
      cycles: cycles.toString(),
    );
  }

  void setupRecurringBillingTokenization({
    String? amount,
    String? itemName,
  }) {
    if (recurringBilling == null) {
      throw Exception("Call setRecurringBillingType(RecurringPaymentType.tokenization) first");
    }

    recurringBilling!.tokenizationBilling = TokenizationBilling(
      itemName,
      amount,
    );
  }

  /// Helper method for enhanced payments with tokenization support
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
    bool forceCardPayment = false,
    bool enableTokenization = false,
    String? customStr1,
    String? customStr2,
    String? customStr3,
    String? customStr4,
    String? customInt1,
    String? customInt2,
  }) {
    return generatePaymentUrl(
      merchantId: merchantId,
      merchantKey: merchantKey,
      passphrase: passphrase,
      production: production,
      amount: amount,
      itemName: itemName,
      notifyUrl: notifyUrl,
      // Add token capture flag to return URL to help with token detection
      returnUrl: returnUrl != null ? '$returnUrl&capture_token=true' : null,
      cancelUrl: cancelUrl,
      paymentId: paymentId,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      // Force credit card payment if requested
      paymentMethod: forceCardPayment ? 'cc' : null,
      // Enable tokenization if requested (type 2 is for tokenized payments)
      subscriptionType: enableTokenization ? '2' : null,
      // Pass through custom parameters for tracking
      customStr1: customStr1,
      customStr2: enableTokenization ? 'tokenize' : customStr2, // Mark tokenization requests
      customStr3: customStr3,
      customStr4: enableTokenization ? 'cardlastfour' : customStr4,
      customInt1: customInt1,
      customInt2: customInt2,
    );
  }

  /// Generates a PayFast payment URL with proper signature
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
    String? paymentMethod,
    String? subscriptionType,
    String? customStr1,
    String? customStr2,
    String? customStr3,
    String? customStr4,
    String? customInt1,
    String? customInt2,
  }) {
    // Create the parameters map in the correct order as per PayFast docs
    // 1. Merchant details
    final Map<String, dynamic> params = {
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

    // 4. Custom fields for tracking and additional data
    if (customStr1 != null && customStr1.isNotEmpty) {
      params['custom_str1'] = customStr1;
    }

    if (customStr2 != null && customStr2.isNotEmpty) {
      params['custom_str2'] = customStr2;
    }

    if (customStr3 != null && customStr3.isNotEmpty) {
      params['custom_str3'] = customStr3;
    }

    if (customStr4 != null && customStr4.isNotEmpty) {
      params['custom_str4'] = customStr4;
    }

    if (customInt1 != null && customInt1.isNotEmpty) {
      params['custom_int1'] = customInt1;
    }

    if (customInt2 != null && customInt2.isNotEmpty) {
      params['custom_int2'] = customInt2;
    }

    // 5. Advanced features
    // Only add payment_method if specified
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      params['payment_method'] = paymentMethod;
    }

    // Add subscription_type for tokenization
    if (subscriptionType != null && subscriptionType.isNotEmpty) {
      params['subscription_type'] = subscriptionType;
    }

    // Calculate signature according to PayFast documentation
    final signature = SignatureService.createSignature(params, passphrase);
    params['signature'] = signature;

    // Debug
    debugPrint('PayFast params: ${jsonEncode(params)}');

    // Build the URL
    final host = production ? 'www.payfast.co.za' : 'sandbox.payfast.co.za';
    final queryString = SignatureService.buildQueryString(params);

    return 'https://$host/eng/process?$queryString';
  }
}