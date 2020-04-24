# WooCommerce for iOS 

## Architecture

- [Architecture](ARCHITECTURE.md)
- [Networking](NETWORKING.md)
- [Storage](STORAGE.md)
- [Yosemite](YOSEMITE.md)

## Coding Guidelines

### Coding Style

The guidelines for how Swift should be written and formatted can be found in the [Coding Style Guide](coding-style-guide.md).

### Choosing Between Structures and Classes

In addition to the [Apple guidelines](https://developer.apple.com/documentation/swift/choosing_between_structures_and_classes), we generally prefer to use `struct` for: 

- Value types like the [Networking Models](../../../Networking/Networking/Model)
- Stateless helpers 

But consider using `class` instead if:

- You need to manage mutable states. Especially if there are more than a few `mutating` functions, the `struct` becomes harder to reason about.
- You have to set a `struct` property declaration as `var` because it has a `mutating` function. In this case, a constant (`let`) `class` property may be easier to reason about.
