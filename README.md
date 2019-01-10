
[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=5b2b904eaa674400010e975e&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/5b2b904eaa674400010e975e/build/latest?branch=develop) 

# woocommerce-ios
A Jetpack-powered companion app for WooCommerce.

## Build Instructions

### Download Xcode

At the moment *WooCommerce for iOS* uses Swift 4.2 and requires Xcode 10 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action).*

### Third party tools

We use a few tools to help with development. To install or update the required dependencies, run the follow command on the command line:

`rake dependencies`

#### CocoaPods

The woocommerce-ios project uses [CocoaPods](http://cocoapods.org/) to manage third party libraries.  
Third party libraries and resources managed by CocoaPods will be installed by the `rake dependencies` command above.

#### Dangerbot

The woocommerce-ios project uses [Danger](https://danger.systems/swift/) to enforce Swift linting styles.
