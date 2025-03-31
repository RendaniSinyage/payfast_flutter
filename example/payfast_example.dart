import 'package:flutter/material.dart';
import 'package:payfast/payfast.dart';

// Updated example using the enhanced Payfast implementation
// Demonstrates simple payments, subscriptions, and tokenization
// Use ngrok and nodejs to handle webhooks for testing in sandbox mode

void main() {
  runApp(const PayfastDemoApp());
}

class PayfastDemoApp extends StatelessWidget {
  const PayfastDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payfast Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PayfastDemoScreen(),
    );
  }
}

class PayfastDemoScreen extends StatefulWidget {
  const PayfastDemoScreen({Key? key}) : super(key: key);

  @override
  _PayfastDemoScreenState createState() => _PayfastDemoScreenState();
}

class _PayfastDemoScreenState extends State<PayfastDemoScreen> {
  late Payfast payfast;
  String generatedUrl = '';

  @override
  void initState() {
    super.initState();

    // Initialize Payfast with merchant details and customer information
    payfast = Payfast(
      passphrase: 'JoshuaMunstermann',
      paymentType: PaymentType.simplePayment,
      production: false, // Use sandbox for testing
      merchantDetails: MerchantDetails(
        merchantId: '10026561',
        merchantKey: 'cwon220sjr9ga',
        notifyUrl: 'https://b5f5-196-30-8-166.eu.ngrok.io/payfast-webhook',
        returnUrl: 'https://myapp.com/payment-success',
        cancelUrl: 'https://myapp.com/payment-cancelled',
        paymentId: 'ORDER-123456', // Your custom order ID
      ),
      // Customer details (optional but recommended)
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      phone: '0821234567',
      // Custom fields for your own tracking (optional)
      customStr1: 'web-checkout',
      customStr2: 'premium-plan',
    );
  }

  // Example of simple one-time payment
  void setupSimplePayment() {
    // Reset payment type
    payfast.paymentType = PaymentType.simplePayment;

    // Setup simple payment
    payfast.createSimplePayment(
        amount: '299.99',
        itemName: 'Premium Plan - Monthly'
    );

    // Generate and display the URL
    setState(() {
      generatedUrl = payfast.generateURL();
    });
  }

  // Example of subscription payment
  void setupSubscriptionPayment() {
    // Set payment type to recurring
    payfast.paymentType = PaymentType.recurringBilling;

    // Set recurring billing type to subscription
    payfast.setRecurringBillingType(RecurringPaymentType.subscription);

    // Setup subscription details
    payfast.setupRecurringBillingSubscription(
      amount: 299, // Initial amount
      itemName: 'Premium Subscription',
      billingDate: '2025-04-05', // First billing date
      cycles: 12, // Number of billing cycles (12 months)
      cyclePeriod: FrequencyCyclePeriod.monthly, // Monthly billing
      recurringAmount: 299, // Amount to bill each cycle
    );

    // Generate and display the URL
    setState(() {
      generatedUrl = payfast.generateURL();
    });
  }

  // Example of tokenization for future billing
  void setupTokenization() {
    // Set payment type to recurring
    payfast.paymentType = PaymentType.recurringBilling;

    // Set recurring billing type to tokenization
    payfast.setRecurringBillingType(RecurringPaymentType.tokenization);

    // Setup tokenization with initial payment
    payfast.setupRecurringBillingTokenization(
        amount: '1.00', // Small amount for initial tokenization
        itemName: 'Save payment method'
    );

    // Generate and display the URL
    setState(() {
      generatedUrl = payfast.generateURL();
    });
  }

  // Example of charging a saved token
  void chargeExistingToken() {
    final String savedToken = '3ee21522-7cc9-464d-837a-3e791c5a6f1d'; // Token from previous tokenization

    // Generate token payment URL (Note: this would typically be used in a server-side API call)
    final tokenUrl = payfast.generateTokenPaymentUrl(
        token: savedToken,
        amount: '499.99',
        itemName: 'Recurring charge - Premium Plan'
    );

    setState(() {
      generatedUrl = tokenUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payfast Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: setupSimplePayment,
              child: const Text('Simple Payment'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: setupSubscriptionPayment,
              child: const Text('Subscription Payment'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: setupTokenization,
              child: const Text('Tokenization'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: chargeExistingToken,
              child: const Text('Charge Saved Token'),
            ),
            const SizedBox(height: 24),
            const Text('Generated URL:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                generatedUrl.isEmpty ? 'Press a button to generate a URL' : generatedUrl,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}