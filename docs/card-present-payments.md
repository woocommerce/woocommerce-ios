# Card Present Payments
## Project scope
* Support payments using the Stripe SDK for US-based merchants that are already WCPay customers
* The mobile apps should support:
	* Discover card readers.
	* Connect a card reader to a mobile device.
	* Collect payment from a customer on a cash-on-delivery order.
	* Print a receipt
	* E-mail a receipt.
	* Update a card reader firmware.

## High level overview
As mentioned in the previous section, and oversimplifying, this project is going to build an integration with Stripe’s card readers, using the Stripe Terminal SDK.

Things are a bit more complex though. Being able to collect a payment requires certain integrations with WooCommerce Payments. 

This is everything that is required in order to collect a payment for a cash on delivery order:

1. Obtaining a token
2. Creating and processing a payment intent using the card reader
3. Capturing the payment intent submitting it to WooCommerce Payments.

### Obtaining a token

The Stripe Terminal SDK requires a connection token as a prerequisite to any interaction with the SDK.

The way to provide that token to the SDK is by providing an implementation of a protocol declared in the Stripe Terminal SDK, called `ConnectionTokenProvider`

The mobile apps obtain the token from the endpoint `payments/connection_tokens`. The integration with this endpoint is implemented in WCPayRemote.

### Creating and processing a payment intent using the card reader

In order to obtain a payment intent, the mobile app needs to discover and connect to a card reader first.

Once the discovery and connection process is completed, we can collect a payment. To do so, we rely on the Stripe Terminal SDK, which will execute three operations in sequence: 
1. Create a payment intent. This is the initial step of the process. The Stripe Terminal SDK transitions into a mode where it is ready to start collecting a payment. To do so, it creates a payment intent, which will be getting updated as the payment collection process advances.
2. Collect a payment method. We collect a payment method by asking users to tap/insert/swipe their cards. 
3. Process the payment. This is a somewhat obscure operation, where we assume the Terminal SDK submits all the information it has collected so far to Stripe. This information will have to be matched with what the mobile app provides in the next phase.

### Capturing a payment

Once we have a payment intent that has been processed by the Stripe Terminal SDK, we submit the payment intent identifier to an endpoint in WooCommerce Payments (`payments/orders/{id}/capture_terminal_payment`). WooCommerce Payments will then proxy the request containing this identifier to Stripe, where all the pertinent checks will be performed, and the response will be sent back down to the mobile app. 

The end result is a "OK" or "KO" that the mobile app then uses to present a success or error message to the user.

### Printing a receipt

If everything goes well in the previous step, and WooCommerce Payments lets us know that the payment intent identifier was captured correctly, and the payment was finally captured, it is time for us to offer merchants the option to print or email a receipt.

There is a caveat here: when we initiate the process to capture a payment, we will attempt to provide the customer email address to the Stripe Terminal SDK. If the request to create a payment intent contains a valid email address, Stripe will send a receipt automatically.

Leaving that aside, we still offer the option to print or email a receipt right after the payment has been collected and processed. 

Orders that have been processed via a Card Present Payment will also offer the option to see a receipt after the fact. For beta 1, receipts are saved locally only, and will not survive a reinstall.
