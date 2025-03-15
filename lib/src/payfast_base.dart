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
  
  // Added customer details properties
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
    
    // Build the URL with proper host
    final host = production ? 'payfast.co.za' : 'sandbox.payfast.co.za';
    
    return Uri.decodeComponent(
      Uri(
        scheme: 'https',
        host: host,
        path: '/eng/process',
        queryParameters: {
          ...queryParameters,
          'signature': signature,
        },
      ).toString(),
    );
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
