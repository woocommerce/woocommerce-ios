#  UI Tests

WooCommerce for iOS has UI acceptance tests for critical user flows through the app. The tests use mocked network requests with [WireMock](http://wiremock.org/).

## Test coverage

The following flows are covered/planned to be covered by UI tests. Tests that are covered will be checked.

1. Login
    - [x] Log in with Store Address
    - [x] Log in with email/password
    - [x] Invalid password
    - [ ] Log in with magic link
    - [ ] Log in with Apple
    - [ ] Log in with Google
2. My Store
    - [x] Stats Today, This Week, This Month, This Year load
    - [x] View detailed chart stats
3. Orders
   - [x] Orders list loads
   - [ ] Single Order Screen:
     - [x] Single order screen loads
     - [ ] View product on single order screen
     - [ ] Add customer note
     - [ ] Add order note
     - [ ] Update order status
     - [ ] Issue refund
     - [ ] Add shipping details
   - [x] Create a new order:
     - [x] With a selected order status
     - [x] With a product
     - [x] With customer details
     - [x] With shipping
     - [x] With a fee
     - [x] With a customer note
   - [x] Edit an existing order:
     - [x] Open edit flow
     - [x] Check existing order number
     - [x] Check existing product 
     - [ ] Edit products
     - [ ] Edit customer details
     - [x] Order Edit flow can be dismissed
   - [x] Order Creation flow can be dismissed
4. Products
    - [x] Products list and single product screens load
    - [x] Add new product - Simple physical product
    - [x] Add new product - Simple virtual product
    - [x] Add new product - Variable product
    - [ ] Add new product - Grouped product
    - [ ] Add new product - External product
    - [x] Search product
    - [x] Filter product
    - [ ] Edit product
    - [ ] Add media library image to existing product
    - [ ] Add camera image to existing product
5. Reviews
    - [x] Reviews list and single review screens load
    - [ ] Mark review as spam
    - [ ] Trash review
    - [ ] Approve/unapprove review
    - [ ] Undo action
6. Push Notifications
    - [ ] New order results in a push notification
    - [ ] Orders push notification opens the correct order
    - [ ] Reviews push notification opens the correct review
7. Universal Links and Deeplinks - Tests are temporarily disabled, [Issue 9382](https://github.com/woocommerce/woocommerce-ios/issues/9382) is happening frequently on tests too
    - [x] Universal Link to Payments screen
    - [x] Universal Link to an Order
8. Settings
    - [x] Contact support - Validate buttons and text fields
    - [ ] Contact support - Submit support ticket
9. Payments
    - [x] Make a Simple payment - Cash
    - [ ] Make a Simple payment - Card Reader
    - [ ] Make a Tap to Pay on iPhone payment
    - [ ] Manage Card Reader - Connect/Disconnect Reader
    - [x] Card Reader Manual (Chipper) loads
    - [x] Learn More link loads

## Running tests

Note that due to the mock server setup, tests cannot be run on physical devices right now.

You can run the tests locally with these steps:

1. Follow the [build instructions](../../README.md#build-instructions) to clone the project, install the dependencies, and open the project in Xcode.
2. Run `rake mocks` to start a local mock server.
3. Select the `WooCommerceUITests` scheme in Xcode.
4. Navigate to Product > Test to run all the tests, or use the Test Navigator to run specific tests or test suites.

We also run the UI tests on Buildkite on every commit. See the [Buildkite config](../../.buildkite/pipeline.yml) for more details.

## Adding tests

When adding a new UI test, consider:

* Whether you need to test a user flow (to accomplish a task or goal) or a specific feature (e.g. boundary testing).
* What screens are being tested (defined as screen objects in the [Screens](../UITestsFoundation/Screens) directory).
* Whether there are actions or flows that could be shared across tests (defined in the [Utils](Utils) directory).
* What network requests are made during the test (defined in the [Mocks](Mocks) directory).

It's preferred to focus UI tests on entire user flows, and group tests with related flows or goals in the same test suite.

When you add a new test, you may need to add new screens and methods. We use [ScreenObject](https://github.com/Automattic/ScreenObject) and method chaining for clarity in our tests. Wherever possible, use an existing `accessibilityIdentifier` (or add one to the app) instead of a string to select a UI element on the screen. This ensures tests can be run regardless of the device language.

When adding a new test case, please mark the test case as done on the list above. If the test case is not on the list, please add it to the list and mark it as done.

## Adding or updating network mocks

When you add a test (or when the app changes), the request definitions for WireMock need to be updated. You can read the [WireMock documentation](http://wiremock.org/docs/) for more details.

If you are unsure what network requests need to be mocked for a test, an easy way to find out is to run the app through [Charles Proxy](https://www.charlesproxy.com/) and observe the required requests.
