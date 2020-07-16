# WooCommerce for iOS

**Table of Contents**

- [Architecture](#architecture)
- [Coding Guidelines](#coding-guidelines)
    - [Naming Conventions](#naming-conventions)
        - [Protocols](#protocol)
    - [Coding Style](#coding-style)
    - [Choosing Between Structures and Classes](#choosing-between-structures-and-classes)
- [Design Patterns](#design-patterns)
    - [Copiable](#copiable)
        - [Generating Copiable Methods](#generating-copiable-methods)
        - [Modifying The Copiable Code Generation](#modifying-the-copiable-code-generation)
- [Testing](#testing)

## Architecture

- [Architecture](ARCHITECTURE.md)
- [Networking](NETWORKING.md)
- [Storage](STORAGE.md)
- [Yosemite](YOSEMITE.md)

## Coding Guidelines

### Naming Conventions

#### Protocols

When naming protocols, we generally follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/#strive-for-fluent-usage):

- Protocols that describe _what something_ is should read as nouns (e.g. `Collection`).
- Protocols that describe a _capability_ should be named using the suffixes `able`, `ible`, or `ing` (e.g. `Equatable`, `ProgressReporting`).

For protocols that are specifically for one type only, it is acceptable to append `Protocol` to the name.

```swift
public protocol ProductsRemoteProtocol { }

final class ProductsRemote: Remote, ProductsRemoteProtocol { }
```

We usually end up with cases like this when we _have_ to create a protocol to support mocking unit tests.

### Coding Style

The guidelines for how Swift should be written and formatted can be found in the [Coding Style Guide](coding-style-guide.md).

### Choosing Between Structures and Classes

In addition to the [Apple guidelines](https://developer.apple.com/documentation/swift/choosing_between_structures_and_classes), we generally prefer to use `struct` for:

- Value types like the [Networking Models](../Networking/Networking/Model)
- Stateless helpers

But consider using `class` instead if:

- You need to manage mutable states. Especially if there are more than a few `mutating` functions, the `struct` becomes harder to reason about.
- You have to set a `struct` property declaration as `var` because it has a `mutating` function. In this case, a constant (`let`) `class` property may be easier to reason about.

## Design Patterns

### Copiable

In the WooCommerce module, we generally work with [immutable objects](../Yosemite/Yosemite/Model/Model.swift). Mutation only happens within Yosemite and Storage. This is an intentional design and promotes clarity of [where and when those objects will be updated](https://git.io/JvALp).

But in order to _update_ something, we still need to pass an _updated_ object to Yosemite. For example, to use the [`ProductAction.updateProduct`](../Yosemite/Yosemite/Actions/ProductAction.swift) action, we'd probably have to create a new [`Product`](../Networking/Networking/Model/Product/Product.swift) object:

```swift
// An existing Product instance given by Yosemite
let currentProduct: Product

// Update the Product instance with a new `name`
let updatedProduct = Product(
    productID: currentProduct.productID,
    name: "A new name", // The only updated property
    slug: currentProduct.slug,
    permalink: currentProduct.permalink,
    dateCreated: currentProduct.dateCreated,
    dateModified: currentProduct.dateModified,
    dateOnSaleStart: currentProduct.dateOnSaleStart,

    // And so on...
)

let action = ProductAction.updateProduct(product: updatedProduct, ...)
store.dispatch(action)
```

This is quite cumbersome, especially since `Product` has more than 50 properties.

To help with this, we generate `copy()` methods for these objects. These `copy()` methods follow a specific pattern and will make use of the [`CopiableProp` and `NullableCopiableProp` typealiases](../Networking/Networking/Copiable/Copiable.swift).

Here is an example implementation on a `Person` `struct`:

```swift
struct Person {
    let id: Int
    let name: String
    let address: String?
}

/// This will be automatically generated
extension Person {
    func copy(
        id: CopiableProp<Int> = .copy,
        name: CopiableProp<String> = .copy,
        address: NullableCopiableProp<String> = .copy
    ) -> Person {
        // Create local variables to reduce Swift compilation complexity.
        let id = id ?? self.id
        let name = name ?? self.name
        let address = address ?? self.address

        return Person(
            id: id
            name: name
            address: address
        )
    }
}
```

The `copy()` arguments match the `Person`'s properties. For the `Optional` properties like `address`, the `NullableCopiableProp` typealias is used.

By default, not passing any argument would only create a _copy_ of the `Person` instance. Passing an argument would _replace_ that property's value:

```swift
let luke = Person(id: 1, name: "Luke", address: "Jakku")

let leia = luke.copy(name: "Leia")
```

In the above, `leia` would have the same `id` and `address` as `luke` because those arguments were not given.

```swift
{ id: 1, name: "Leia", address: "Jakku" }
```

The `address` property, declared as `NullableCopiableProp<String>` has an additional functionality. Because it is `Optional`, we should be able to set its value to `nil`. We can do that by passing an `Optional` variable as the argument:

```swift
let luke = Person(id: 1, name: "Luke", address: "Jakku")

let address: String? = nil

let lukeWithNoAddress = luke.copy(address: address)
```

The `lukeWithNoAddress` variable will have a `nil` address as expected:

```swift
{ id: 1, name: "Luke", address: nil }
```

If we want to _directly_ set the `address` to `nil`, we should **not** pass just `nil`. This is because `nil` is just the same as `.copy` in this context. Instead, we should pass `.some(nil)` instead.

```swift
let luke = Person(id: 1, name: "Luke", address: "Jakku")

// DO NOT
// Result will be incorrect: { id: 1, name: "Luke", address: "Jakku" }
let lukeWithNoAddress = luke.copy(address: nil)

// DO
// Result will be { id: 1, name: "Luke", address: nil }
let lukeWithNoAddress = luke.copy(address: .some(nil))
```

### Generating Copiable Methods

The `copy()` methods are generated using [Sourcery](https://github.com/krzysztofzablocki/Sourcery). For now, only the classes or structs in the WooCommerce, Yosemite, and Networking modules are supported.

To generate a `copy()` method for a `class` or `struct`:

1. Make it conform to [`GeneratedCopiable`](../Networking/Networking/Copiable/GeneratedCopiable.swift). Consider importing the `protocol` only.

    ```swift
    import protocol Networking.GeneratedCopiable

    struct ProductSettings: GeneratedCopiable {
        ...
    }
    ```

2. In terminal, navigate to the project's root folder and run `rake generate`.

    ```
    $ cd /path/to/root
    $ rake generate
    ```

    This will generate separate files for every module. For example:

    ```
    WooCommerce/Classes/Copiable/Models+Copiable.generated.swift
    Yosemite/Yosemite/Model/Copiable/Models+Copiable.generated.swift
    ```

3. Add the generated files to the appropriate project if they're not added yet.
4. Compile the project.

### Modifying The Copiable Code Generation

The [`rake generate`](../Rakefile) command executes the Sourcery configuration files located in the [`CodeGeneration` folder](../CodeGeneration). There are different configuration files for every module:

```
Networking module → Networking-Copiable.sourcery.yaml
WooCommerce module → WooCommerce-Copiable.sourcery.yaml
Yosemite module → Yosemite-Copiable.sourcery.yaml
```

All of them use a single template, [`Models+Copiable.swifttemplate`](../CodeGeneration/Models+Copiable.swifttemplate), to generate the code. It's written using [Swift templates](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/writing-templates.html).

Please refer to the [Sourcery reference](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/index.html) for more info about how to write templates.


## Testing

- [UI Tests](UI-TESTS.md)
- [Beta Testing](https://woocommercehalo.wordpress.com/setup/join-ios-beta/)