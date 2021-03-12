# Fakeable

Instantiating `Networking` models for tests is not a simple task. Sometimes, the initializer has too many attributes and the test does not rely on the full set of attributes.
This inconvenience hurts our ability to efficiently unit test our app, which could discourage members from writing them at all.

To help with this, we have introduced a new framework called `Fakes.framework`. This framework defines `.fake()` functions for all of our networking models.
The `.fake()` function instantiates a type with fake values. As of now, we are [defining](https://github.com/woocommerce/woocommerce-ios/blob/develop/Fakes/Fakes/Fake.swift) fake values as empty values.

This, in conjunction with the [copiable pattern](https://github.com/woocommerce/woocommerce-ios/blob/develop/docs/copiable.md) allow us to write tests like:

```swift
func test() {
     // Given
     let initialProduct = Product.fake()
     let expectedProduct = initialProduct.copy(name: "new-name")
     let ViewModel = ViewModel(product: initialProduct)
     
     // When
     viewModel.updateName("new_name")
     
     // Then
     XCTAssertEqual(viewModel.product, expectedProduct)
}
```

**Note: This framework is meant to be used in test targets only!**


## Generating Fake Methods

The `fake()` methods are generated using [Sourcery](https://github.com/krzysztofzablocki/Sourcery). For now, only `classes`, `structs`, and `enums` of the `Networking` target are supported.

To generate a `fake()` method:

1. Make it conform to [`GeneratedFakeable`](../Networking/Networking/Copiable/GeneratedFakeable.swift).

    ```swift
    import protocol Networking.GeneratedFakeable

    struct ProductSettings: GeneratedFakeable {
        ...
    }
    ```

2. In the terminal, navigate to the project's root folder and run `rake generate`.

    ```
    $ cd /path/to/root
    $ rake generate
    ```

    This will update the [Fakes.generated](https://github.com/woocommerce/woocommerce-ios/blob/develop/Fakes/Fakes/Fakes.generated.swift) file with the new `fake()` method.

5. Compile the project.


## Modifying The Fakeable Code Generation

The [`rake generate`](../Rakefile) command executes the Sourcery configuration files located in the [`CodeGeneration/Fakes` folder](../CodeGeneration/Fakes). There is just one configuration file:

```
Networking module → Networking-Fakes.yaml
```

It uses a single template, [`Fakes.swifttemplate`](../CodeGeneration/Fakes/Fakes.swifttemplate), to generate the code. It's written using [Swift templates](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/writing-templates.html).

Please refer to the [Sourcery reference](https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/index.html) for more info about how to write templates.
