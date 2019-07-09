
[![CircleCI](https://circleci.com/gh/woocommerce/woocommerce-ios.svg?style=svg)](https://circleci.com/gh/woocommerce/woocommerce-ios)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

# woocommerce-ios
A Jetpack-powered companion app for WooCommerce.

## Build Instructions

### Download Xcode

At the moment *WooCommerce for iOS* uses Swift 5 and requires Xcode 10.2 or newer. Previous versions of Xcode can be [downloaded from Apple](https://developer.apple.com/downloads/index.action).*

### Third party tools

We use a few tools to help with development. To install or update the required dependencies, run the follow command on the command line:

`bundle exec pod install`

you may also have to:
`bundle install`

#### CocoaPods

The woocommerce-ios project uses [CocoaPods](http://cocoapods.org/) to manage third party libraries.  
Third party libraries and resources managed by CocoaPods will be installed by the `bundle exec pod install` command above.

#### Peril

The woocommerce-ios project uses [Peril](https://danger.systems/js/guides/peril.html) to enforce Pull Request guidelines.

#### Circle CI

The woocommerce-ios project uses [Circle CI](https://circleci.com/gh/woocommerce/woocommerce-ios) for continuous integration.

#### Hound
The woocommerce-ios project uses [Hound](https://houndci.com) to enforce basic Swift styles. (Not all Woo styles are defined in Hound.)
