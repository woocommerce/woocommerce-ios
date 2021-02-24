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

Integration tests that go just beyond discovering readers are not easy to run (at this stage). The reason is that the Terminal SDK needs a valid connection token when it attempts to connect to a reader, even if the SDK is in test mode.

There are some prerequistes for running some of the integration tests:

* Install WooCommerce Payments on a WooCommerce site. Do not run the setup assistant yet.
* Install woocommerce-payments-dev-tools by downloading the repo as a zip and uploading it to the site as a new plugin, and activate it. as an alternative, add this to wp-config.php: `define( 'WCPAY_DEV_MODE', true );`
* After activating the Dev Tools plugin, look in wp-admin all the way at the bottom of the sidebar menu for WCPay Dev.
* Uncheck Proxy WPCOM requests
* Run the WooCommerce Payments setup assistant. It should indicate that it is running in "TEST DATA" mode. That would allow entering mock data.

At the time of writing this, we do not have the infrastructure to obtain that connection token by performing an authenicated request to a WooCommerce store. So integration tests that requir a connection token will require to edit WCPayTokenProvider and update the mock token with a value obtainied from your store's wp-admin. In order to do that you would need to download and install woocommerce-payments-card-reader-token-helper. 

After installing and activating the plugin, connection tokens would be available in a notice at the top of most wp-admin pages. 

## Business logic

The business logic of the integration is encapsulated in `CardPresentPaymentStore`. This logic is unit tested in the YosemiteTests, like any other Store in the codebase