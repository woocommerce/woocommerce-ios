# Creating Core Data Model Versions

If you are unfamiliar with Core Data model versions and how they work, we recommend reading [Lightweight Migrations in Core Data Tutorial](https://www.raywenderlich.com/7585-lightweight-migrations-in-core-data-tutorial) first.

The Core Data model versions are located at [`Storage/Storage/Model/WooCommerce.xcdatamodeld`](../Storage/Storage/Model/WooCommerce.xcdatamodeld).

## Naming

When creating a new version (`xcdatamodel`), name it as `Model N+1` where `N` is the last model version number. For example, if the last model version is `Model 32`, then the new version should be named `Model 33`. The correct name is usually suggested by Xcode.

The sequential version numbers are important because that sequence is used by the automatic [iterative migrator](../Storage/Storage/CoreData/CoreDataIterativeMigrator.swift) to determine how to upgrade the user's existing database. You can find more information about how the model versions sequence is determined in [`ManagedObjectModelsInventory`](../Storage/Storage/CoreData/ManagedObjectModelsInventory.swift).

## Avoid Modifying Existing Model Versions

Once a model version is merged in `develop`, consider creating a new model version instead. This helps us avoid issues like:

- Different model version sequences between production and `develop`.
- Inconsistent model version references if multiple model versions, created by different developers, refer to the same model version.

These scenarios can lead to users' databases to be incompatible with the current model and they would be **unable to load** their data. The app would end up recreating the database. It's not an ideal scenario.

Also, avoid modifying model versions in release branches. If possible, model version changes should be done and merged swiftly in `develop`.

## Always Add Unit Tests

Always create a unit test between the current model version and the new version in [`MigrationTests`](../Storage/StorageTests/CoreData/MigrationTests.swift). This helps us ensure that the migrations will always work for users who have not upgraded. Consider the unit test as **concrete documentation** for what the new model version changed.

Avoid using the [`NSManagedObject` subclasses](../Storage/Storage/Model) in the unit tests. Prefer to use pure `NSManagedObject` instances.

```swift
// Prefer
let product: NSManagedObject = insertProduct(to: sourceContext)
product.setValue([1, 2, 3], forKey: "crossSellIDs")

// Avoid
let product: Product = insertProduct(to: sourceContext)
product.crossSellIDs = [1, 2, 3]
```

In the example above, using the `NSManagedObject` subclass named `Product` is less future-proof. If we end up deleting the `crossSellIDs` property, then the code will no longer compile. We would have to modify the unit test and risk diverging from the original intent.

## Add a Changelog

After creating a new model, add a note in the [`MIGRATIONS.md` file](../Storage/Storage/Model/MIGRATIONS.md), stating the changes in the new model version.
