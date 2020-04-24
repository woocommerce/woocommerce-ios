
[![CircleCI](https://circleci.com/gh/woocommerce/woocommerce-ios.svg?style=svg)](https://circleci.com/gh/woocommerce/woocommerce-ios)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

# woocommerce-ios
A Jetpack-powered companion app for WooCommerce.

## Build Instructions

1. Download Xcode

    At the moment *WooCommerce for iOS* uses Swift 5 and requires Xcode 11.2.1 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action)
2. Clone project in the folder of your preference

    ```bash
    git clone https://github.com/woocommerce/woocommerce-ios.git
    ````

3. Enter the project directory 

    ```bash
    cd woocommerce-ios
    ```
    
4. Install the third party dependencies and tools required to run the project
    
    We use a few tools to help with development. To install or update the required dependencies, run:
    
    ```bash
    rake dependencies
    ```
    
5. Open the project by double clicking on `WooCommerce.xcworkspace` file, or launching Xcode and choose File > Open and browse to `WooCommerce.xcworkspace`

#### Credentials for external contributors
In order to login to WordPress.com using the app:
1. Create a [WordPress.com account](https://wordpress.com/start/user) (if you don't already have one).
2. Create a new developer application [here](https://developer.wordpress.com/apps/).
3. Set **"Redirect URLs"** = `https://localhost` and **"Type"** = `Native` and click **Create** then **Update**.
4. Copy the *Client ID* and *Client Secret* from the OAuth Information. Build the app.
5. Navigate to *WooCommerce/DerivedSources/ApiCredentials.swift*
6. Fill in the dotcomAppId with the Client ID
7. Fill in the dotcomSecret with the Client Secret
8. Recompile and run the app on a device or inside simulator.

Please, remember to not add this information on your commits and PRs.
  
#### SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce a common style for Swift code. The app should build and work without it, but if you plan to write code, you are encouraged to run it locally by `rake lint` (first run will install SwiftLint if you don't have it). No pull requests should have lint warnings or errors before merging, and we also have `Hound` (mentioned below) to help us in pull requests on GitHub.

If your code has any style violations, you can try to automatically correct them by running:

`rake lint:autocorrect`

Otherwise, you can also fix them manually.

#### CocoaPods

The woocommerce-ios project uses [CocoaPods](http://cocoapods.org/) to manage third party libraries.  
Third party libraries and resources managed by CocoaPods will be installed by the `bundle exec pod install` command above.

#### Peril

The woocommerce-ios project uses [Peril](https://danger.systems/js/guides/peril.html) to enforce Pull Request guidelines.

#### Circle CI

The woocommerce-ios project uses [Circle CI](https://circleci.com/gh/woocommerce/woocommerce-ios) for continuous integration.

#### Hound
The woocommerce-ios project uses [Hound](https://houndci.com) to enforce basic Swift styles. (Not all Woo styles are defined in Hound.)

## Security

If you happen to find a security vulnerability, we would appreciate you letting us know at https://hackerone.com/automattic and allowing us to respond before disclosing the issue publicly.

## Need help? ##

You can find the WooCommerce usage docs here: [docs.woocommerce.com](https://docs.woocommerce.com/)

General usage and development questions:

* [WooCommerce Slack Community](https://woocommerce.com/community-slack/)
* [WordPress.org Forums](https://wordpress.org/support/plugin/woocommerce)
* The WooCommerce Help and Share Facebook group

## Resources

- [Documentation on our architecture and frameworks](https://github.com/woocommerce/woocommerce-ios/tree/develop/docs)
- [Mobile blog](https://mobile.blog)
- [WooCommerce API Documentation (currently v3)](https://woocommerce.github.io/woocommerce-rest-api-docs/#introduction)

## License

WooCommerce for iOS is an Open Source project covered by the [GNU General Public License version 2](LICENSE).
