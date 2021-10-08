# Experiments

This framework allows us to develop and test experimental features with different build configurations in release and debug builds. In the future, we can expand the framework to include more advanced experimentation like AB testing (using ExPlat in the Tracks library) and remote feature flag configuration.

## Requirements

The framework should [only contain APIs that are safe in app extensions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html), since it is used in the notification service extension (and possibly more app extensions in the future).

## Dependencies

None at the moment.

## Public interfaces

- Enum `FeatureFlag`: where we define feature flag cases for all the experimental features
- Protocol `FeatureFlagService` and default implementation `DefaultFeatureFlagService`. The protocol allows mocking feature flag states in unit tests, and the default implementation is based on build configurations
- Enum `BuildConfiguration`: the current build configuration `BuildConfiguration.current` is currently used in logging

## Build configurations

The project has three build configurations to match the WooCommerce app: `Debug`, `Release`, and `Release-Alpha`. The `BuildConfiguration` enum is then based on the build configuration via the Experiments project build settings > `Active Compilation Conditions`:

- `Debug` build configuration: `DEBUG` value is set. Used for debug builds from Xcode
- `Release` build configuration: no values are set. Used for release builds for the App Store
- `Release-Alpha` build configuration: `ALPHA` value is set. Used for one-off installable builds for internal testing, which we can trigger from a commit in a pull request

In the default implementation of `FeatureFlagService`, some of the feature flags are based on build configurations - enabled in `Debug` and `Release-Alpha` configurations, and disabled in `Release` builds.
