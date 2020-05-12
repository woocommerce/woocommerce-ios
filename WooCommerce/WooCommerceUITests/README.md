#  UI Tests

WooCommerce for iOS has UI acceptance tests for critical user flows through the app. The tests use mocked network requests with [WireMock](http://wiremock.org/).

## Test coverage

The following user flows are covered with UI tests:

* [Log in with email/password and log out](WooCommerceUITests/Tests/LoginTests.swift)

## Running tests

Note that due to the mock server setup, tests cannot be run on physical devices right now.

You can run the tests locally with these steps:

1. Follow the [build instructions](../README.md#build-instructions) to clone the project, install the dependencies, and open the project in Xcode.
2. Run `rake mocks` to start a local mock server.
3. With the `WooCommerce` scheme selected in Xcode, open the Test Navigator and select the `UITests` test plan.
4. Run the tests on a simulator.

We also run the UI tests on CircleCI on every commit to the `develop` or `release/*` branches. (See the [CircleCI config](../.circleci/config.yml) for device and workflow details.)

## Adding tests

When adding a new UI test, consider:

* Whether you need to test a user flow (to accomplish a task or goal) or a specific feature (e.g. boundary testing).
* What screens are being tested (defined as screen objects in the [Screens](WooCommerceUITests/Screens) directory).
* Whether there are actions or flows that could be shared across tests (defined in the [Utils](WooCommerceUITests/Utils) directory).
* What network requests are made during the test (defined in the [Mocks](WooCommerceUITests/Mocks) directory).

It's preferred to focus UI tests on entire user flows, and group tests with related flows or goals in the same test suite.

When you add a new test, you may need to add new screens and methods. We use [screen (page) objects](https://www.martinfowler.com/bliki/PageObject.html) and method chaining for clarity in our tests. Wherever possible, use an existing `accessibilityIdentifier` (or add one to the app) instead of a string to select a UI element on the screen. This ensures tests can be run regardless of the device language.

## Adding or updating network mocks

When you add a test (or when the app changes), the request definitions for WireMock need to be updated. You can read the [WireMock documentation](http://wiremock.org/docs/) for more details.

If you are unsure what network requests need to be mocked for a test, an easy way to find out is to run the app through [Charles Proxy](https://www.charlesproxy.com/) and observe the required requests.
