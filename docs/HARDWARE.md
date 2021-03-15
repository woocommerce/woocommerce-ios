# Hardware

## High level class diagram

## Public interfaces

## Model objects

## Integration with Stripe Terminal

The initial release of Hardware provides an integration with the [Stripe Terminal SDK](https://github.com/stripe/stripe-terminal-ios)

### Initialization

### Discovering readers

### Pairing (connecting) with a reader

### Processing a payment

Collecting a payment is a three step process that needs to be performed in this specific sequence:

1. [Create a Payment Intent](https://stripe.com/docs/terminal/payments#create-payment). There are two ways to create a payment intent, depending on the external card reader being used. Intents can be created on device, with the exception of the Verifone P400 reader, that requires creating the PaymentIntent server-side.
2. [Collect a Payment Method](https://stripe.com/docs/terminal/payments#collect-payment). In order to collect a payment method, the app needs to be connected to a reader. The connected reader will wait for a card to be presented after the app calls collectPaymentMethod. This method collects encrypted payment method data using the connected card reader, and associates the encrypted data with the local PaymentIntent.
3. [Process the Payment](https://stripe.com/docs/terminal/payments#process-payment). After successfully collecting a payment method from the customer, the next step is to process the payment with the SDK. We can either process automatically or display a confirmation screen, where the customer can choose to proceed with the payment or cancel (e.g., to pay with cash, or use a different payment method).

For more details, see [Stripe's documentation](https://stripe.com/docs/terminal/payments)