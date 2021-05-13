# Hardware

This project provides abstractions that allow us to integrate with external hardware in a way that those integrations fit within the high level architecture of the WooCommerce iOS app.

In the context of the three-tier architecture of the WooCommerce iOS app, Hardware fulfills the role of the data transfer layer in between the application business logic ([Yosemite](YOSEMITE.md)) and external hardware (like card readers or printers). From a functional point of view, Hardware is similar in behaviour to [Networking](NETWORKING.md), the only difference is that Networking transfer information back and forth between the app and remote services, while Hardware transfers info back and forth between the app and external Hardware.

## Public interfaces
* CardReaderService: Abstracts the integration with a Card Reader, it is the public API that provides access to a Card Reader and its associated operations.
* CardReaderConfigProvider: Abstraction provided by Hardware so that clients of the library can model a way to provide a connection token. 
* PrinterService: Abstracts the logic necessary to print receipts. The default implementation of this service integrates with AirPrint.

## Model objects
* CardReader: Models a Card Reader. This is the public struct that clients of Hardware are expected to consume. CardReader is meant to be inmutable. 
* CardReaderEvent: An event emitted by a connected reader.
* CardReaderEventType: The types of events emitted by a connected reader.
* CardReaderServiceDiscoveryStatus: Models the discovery status of a Card Reader Service.
* CardReaderServiceStatus: Models the status of a Card Reader Service.
* CardReaderType: Indicates if a reader is meant to be used handheld or as a countertop device.
* PaymentIntentParameters: Encapsulates the parameters needed to create a PaymentIntent, for example amount, currency, and readable descriptions for receipts
* PaymentStatus. The possible payment statuses
* CardReaderServiceError. Models errors thrown by the CardReaderService. See Error Handling for more info.
* PaymentIntent. A PaymentIntent tracks the process of collecting a payment from your customer. There should be only one payment intent for each order. It aggregates a collection of Charges.
* Charge. Represents a charge, including the PaymentMethod
* PaymentMethod. The payment method associated with the charge. If it is of type card present, it will have an associated value of type CardPresentDetails
* ReceiptContent. The data that will be used to generate a receipt.
* ReceiptLineItem. Each of the line items in a receipt
* CardPresentReceiptParameters. Encapsulates the information necessary to print a receipt for a card present payment. 
* CardPresentTransactionDetails. Metadata provided by the payment processor.

## Integration with Stripe Terminal
The initial release of Hardware provides an integration with the [Stripe Terminal SDK](https://github.com/stripe/stripe-terminal-ios). That integration is encapsulated in `StripeCardReaderService`, and implementation of `CardReaderService` that is internal (in terms of Swift's access modifiers) to Hardware.

There are some interesting quirks in our implementation of the integration with the Stripe SDK that are worth mentioning.

The Stripe Terminal SDK exposes access to external card readers through a singleton, called [SCPTerminal](https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html). The fact that is a singleton makes sense (there is one gateweay with external readers after all), but it makes our attempts to encapsulate the integration behind a clear boundary a bit more challenging. The reasons for those challenges will hopefully be clarified soon.

### Initialization

If there is one quirk, if there is one spot where we had to jump through a few hoops in order to make the integration with the Stripe Terminal SDK fit with the rest of the app, this is it.

Initializing the Stripe Terminal SDK requires providing it with access to an endpoint in our backend, [so that it can fetch a connection token](https://stripe.com/docs/terminal/sdk/ios#connection-token-client-side). 

The way that is meant to happen is by setting a property of type `ConnectionTokenProvider` in SCPTerminal. ConnectionTokenProvider is a protocol declared in the Stripe Terminal SDK.

To prevent that protocol from leaking up outside of Hardware, Hardware exposes a pubic protocol, `CardReaderConfigProvider`, that we expect clients of Hardware to implement in a way that they can provide the connection token that is needed. 

This implementation of CardReaderConfigProvider will have to be passed as a parameter to the `start()` method declared in CardReaderService. Internally, our implementation of CardReaderService specific to the integration with the Stripe Terminal SDK (`StripeCardReaderService`) will adapt the parameter to the required protocol and pass it to SCPTerminal

### Discovering readers

One thing to have in mind when initiating the reader discovery process is that, if there is another reader discovery process that has been already started, the Stripe Terminal SDK will throw an assertion.

That is why we provide a `cancelDiscovery()` method. 

At this point, reader discovery commences as soon as initialization happens. In other words, calling `start()` triggers a reader discovery. We might need to revisit this decission later on.

The Stripe Terminal SDK notifies implementations of the [SCPDiscoveryDelegate](https://stripe.dev/stripe-terminal-ios/docs/Protocols/SCPDiscoveryDelegate.html) protocol of changes in the status of the process: every time a new reader is discovered, or when the process is considered complete. 

To avoid this detail from leaking up as well, we implement SCPDiscoveryDelegate in StripeCardReaderService, and publish the new readers through `connectedReaders` and the status of the discovery process via `discoveryStatus`, two Combine publishers.

Once the reader discovery process starts yielding results, those results are propagated to the UI. Once again, we want to avoid leaking implementation details related to the Stripe Terminal SDK, so we expose domain model objects that are declared on Hardware. In this case, that is `CardReader`

Discovered readers are modelled, within the boundary of the integration with the Stripe Terminal SDK, as `StripeTerminal.CardReader`. These objects are not available for initialization outside of the Stripe Terminal SDK, and are [not meant to be cached](https://stripe.dev/stripe-terminal-ios/docs/Protocols/SCPDiscoveryDelegate.html#/c:objc(pl)SCPDiscoveryDelegate(im)terminal:didUpdateDiscoveredReaders:) between discovery sessions.

What our integration does is cache temporarlity those discovered readers, cleared that cache between discovery sessions, and map them to the instances of `CardReader` that we propagate up.

### Pairing (connecting) with a reader

Once the reader discovery process starts yielding results, those results are propagated to the UI. That happens in the form of instances of `CardReader`, a public model object declared in Hardware, that provides the information needed to render a card reader on the UI (e.g. name, identifier, battery level...)

When the user selects a reader to connect to, we pass that public model object back to the `CardReaderService`, via the `connect()` method. At that point, for the integration with the Stripe Terminal SDK, we will look into the internal cache of discovered readers, find the one that matches the serial number of the parameter provided, and attempt a connection with the StripeTerminal.CardReader found.

### Disconnecting from a card reader

There are to ways a client and a card reader can disconnect: either by a user-initiated action, or because the reader has gone offline.

The disconnection is initiated by a user by just calling the `disconnect()` method in `CardReaderService` This is an async operation.

Card Readers can shut down as well after a certain time being inactive. In that case, the integration with the Stripe Terminal SDK will catch the disconnection and publish a new array of connected readers (empty) via the `connectedReaders` publisher.

### Processing a payment

Collecting a payment is a three step process that needs to be performed in this specific sequence:

1. [Create a Payment Intent](https://stripe.com/docs/terminal/payments#create-payment). There are two ways to create a payment intent, depending on the external card reader being used. Intents can be created on device, with the exception of the Verifone P400 reader, that requires creating the PaymentIntent server-side.
2. [Collect a Payment Method](https://stripe.com/docs/terminal/payments#collect-payment). In order to collect a payment method, the app needs to be connected to a reader. The connected reader will wait for a card to be presented after the app calls collectPaymentMethod. This method collects encrypted payment method data using the connected card reader, and associates the encrypted data with the local PaymentIntent.
3. [Process the Payment](https://stripe.com/docs/terminal/payments#process-payment). After successfully collecting a payment method from the customer, the next step is to process the payment with the SDK. We can either process automatically or display a confirmation screen, where the customer can choose to proceed with the payment or cancel (e.g., to pay with cash, or use a different payment method).

For more details, see [Stripe's documentation](https://stripe.com/docs/terminal/payments)

This process is abstracted away by the CardReaderService, meaning that clients of the service do not need to know that the process requires three steps. 

The status of the payment collection process is notified to the UI via a `CardReaderEvent`. This model object wraps a `CardReaderEventType`, which will allow a view model or view controller to decide how it needs to react to said event, and a user facing message. This message is, in the integraton with the Stripe SDK, most likely being generated [by the Stripe SDK itself](https://stripe.dev/stripe-terminal-ios/docs/Protocols/SCPReaderDisplayDelegate.html#/c:objc(pl)SCPReaderDisplayDelegate(im)terminal:didRequestReaderDisplayMessage:) so it might be wise to ignore it, as it can be a tad vague. But it is there anyway.

### Error handling

All operations in the public API of the `CardReaderService` protocol that can fail would return an error. 

In order to provide as much visibility over what went wrong to other layers (e.g. Yosemite or the UI), errors returned by the `CardReaderService` are modelled in a way that indicate the interaction with the card reader that failed, and the reason why that interaction failed. 

That information is packaged in a single entity, an enumeration named `CardReaderServiceError` that defines, as cases, the interactions with the card reader, while also providing the reason for the error as an associated value:

```
public enum CardReaderServiceError: Error {
    /// Error thrown during reader discovery
    case discovery(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while connecting to a reader
    case connection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while creating a payment intent
    case intentCreation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while collecting payment methods
    case paymentMethod(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while capturing a payment
    case capturePayment(underlyingError: UnderlyingError = .internalServiceError)
}
```

`UnderlyingError` is another enumeration that abstracts out the [error codes provided by the Stripe Terminal SDK](https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html), mapping them to domain errors. 

This way, clients of the service can switch on the CardReaderServiceError in order to understand what part of the process went wrong, and then extract the underlying error to understand why the operation failed.

### Switching accounts or stores

In order to switch accounts or to just reset the integration with the Stripe Terminal SDK it is necessary to first disconnect from connected readers, via a call to `disconnect()` and, after that call is completed, call `clear()`. 

The method `clear()` will reset the integration, clear all the caches, and will make the Stripe Terminal ready to fetch a new connection token.

## Printing receipts.
Receipts can be customized, as long as we list some required information. When accepting in-person payments with EMV chip cards, card networks require us to include several fields on the receipts we provide to customers. Those fields are included as part of the PaymentIntent object (to be more specific, the CardReaderDetails object), once the payment is processed. For more information, see Stripe's documentation: [Custom receipts](https://stripe.com/docs/terminal/checkout/receipts#custom)

Printing receipts is supported via a public interface called `ReceiptPrinterService`. This interface provides, at this moment, a single public method `printReceipt(content: ReceiptContent)`.

`ReceiptContent` wraps the information that needs to be rendered in the receipt. This information is a mix of the contents of the Order and the fields we get from the Stripe Terminal SDK after the payment has been collected. Some of those fields obtained from Stripe are required, in order to meet the card network rules and local regulatory requirements. For more info, check [Stripe's documentation](https://stripe.com/docs/terminal/checkout/receipts#custom)

ReceiptContent provides as well an array of items, modelled by `ReceiptLineItem`, in case we want to add itemized content to the receipt.

The actual rendering of the receipt is performed, at the time of writing this document, by a class called ReceiptRenderer. This class, in its initial implementation, renders the receipt as HTML, applying styles via CSS.
