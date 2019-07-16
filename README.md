
[![CircleCI](https://circleci.com/gh/woocommerce/woocommerce-ios.svg?style=svg)](https://circleci.com/gh/woocommerce/woocommerce-ios)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

# woocommerce-ios
A Jetpack-powered companion app for WooCommerce.

## Build Instructions

- Download Xcode
  - At the moment *WooCommerce for iOS* uses Swift 5 and requires Xcode 10.2 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action)
- Clone project by `git clone https://github.com/woocommerce/woocommerce-ios.git` in the folder of your preference
- Enter the project directory by `cd woocommerce-ios`
- Install the third party dependencies and tools required to run the project
  - We use a few tools to help with development. To install or update the required dependencies, run the follow command on the command line: `bundle exec pod install`
  - In some cases, you may also have to: `bundle install`
- Open the project by double clicking on `WooCommerce.xcworkspace` file, or launching Xcode and choose File > Open and browse to `WooCommerce.xcworkspace`
  
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
