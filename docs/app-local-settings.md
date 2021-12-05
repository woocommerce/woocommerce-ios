# App Local Settings

A small amount of data is currently stored in plist files.
Initial goals were:

- prevent complexity overhead of Core Data
- prevent data loss when we auto-create the database (if a migration fails)
- make data typed
- inject storage layer as dependency.

Retrieving and storing the data is done via [`AppSettingsAction`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Yosemite/Yosemite/Actions/AppSettingsAction.swift) and most of the logic happens in [`AppSettingsStore`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Yosemite/Yosemite/Stores/AppSettingsStore.swift).
There are a few data models + plist files separated for specific features and use cases.

## General use cases

- [`GeneralAppSettings`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Storage/Storage/Model/GeneralAppSettings.swift) handles settings universal to all stores.
- [`GeneralStoreSettings`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Storage/Storage/Model/GeneralStoreSettings.swift) handles settings unique for each store. Cleared on logout.
- [`StoredProductSettings`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Networking/Networking/Model/Product/StoredProductSettings.swift) handles products-specific settings, unique for each store. Cleared on logout.
- [`StoredOrderSettings`](https://github.com/woocommerce/woocommerce-ios/blob/develop/Networking/Yosemite/Model/Product/StoredOrderSettings.swift) handles orders-specific settings, unique for each store. Cleared on logout.


## How to add new property

Example for store settings use case:

1. Add property to data model (`GeneralStoreSettings.swift`).
2. Run `rake generate` to update `Copiable` implementation.
3. Add get and set actions in `AppSettingsAction.swift`.
4. Implement new actions in `AppSettingsStore.swift`. Use existing `getStoreSettings(for:)` and `setStoreSettings(settings:, for:)` helpers + `storeSettings.copy(...)` to update non-mutable settings struct.
