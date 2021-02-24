#  Testing Card Present Payments

Testing the implementation with the Stripe Terminal SDK presents some challenges:

* We want the tests to be as thorough as possible
* We want to test at different levels of abstraction: i.e. unit tests and integration tests
* We want, by definition, to test an integration with external hardware.

We are approaching these challenges at different levels.

## Integration with the Stripe Terminal SDK

We have a well defined boundary with the [Stripe Terminal SDK](https://github.com/stripe/stripe-terminal-ios): a protocol declared in `Hardware`, called `CardReaderService`

### Unit tests

The `CardreaderService` protocol exposes a set of model object also declared in `Hardware`: i.e. `CardReader`, `Charge`, `PaymentIntent`. These objects map to their counterparts declared in the [Stripe Terminal SDK](https://stripe.dev/stripe-terminal-ios/docs/index.html).

The model objects declared in the Stripe Terminal SDK can not be initialized by us directly, because all their initialisers are annotated as NS_UNAVAILABLE. The way we have found to workaround that in a way that we can instantiate our own model objects with mocked Stripe model objects is by making the objects provided by Stripe implement a protocol that we declare, and then typing the parameter passed to our model objects as that protocol.

That translates into something like this:

```swift
import StripeTerminal

extension CardReader {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.Reader
    init(reader: StripeCardReader) {
        self.serial = reader.serialNumber
        self.vendorIdentifier = reader.stripeId
        self.name = reader.label

        let connected = reader.status == .online
        self.status = CardReaderStatus(connected: connected, remembered: false)

        self.softwareVersion = reader.deviceSoftwareVersion
        self.batteryLevel = reader.batteryLevel?.floatValue

        self.readerType = CardReaderType.with(readerType: reader.deviceType)
    }
}


/// The initializers of StripeTerminal.Reader are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPReader that we are interested in, make Reader implement it,
/// and initialize Harware.CardReader with a type conforming to it.
protocol StripeCardReader {
    var serialNumber: String { get }
    var stripeId: String? { get }
    var label: String? { get }
    var status: ReaderNetworkStatus { get }
    var deviceSoftwareVersion: String? { get }
    var batteryLevel: NSNumber? { get }
    var deviceType: DeviceType { get }
}


extension Reader: StripeCardReader { }

```

These objects are unit tested in `HardwareTests`. 


### Integration tests

The Stripe Terminal SDK provides a "test mode". This test mode allows us to run the terminal SDK in the simulator, without connecting to actual external hardware.

In order to run, no matter if it is in test mode or production mode, the Stripe Terminal SDK asserts that [certain keys are available](https://stripe.com/docs/terminal/sdk/ios#configure) in the Info.plist file. 

That, in turn, means that tests against the Stripe SDK will crash unless those tests are run against an app. So to workaround this, we moved the integration tests to the WooCommerceTests suite. See `StripeCardReaderIntegrationTests`

## Business logic

The business logic of the integration is encapsulated in `CardPresentPaymentStore`. This logic is unit tested in the YosemiteTests, like any other Storein the codebase