# Naming Conventions

## Protocols

When naming protocols, we generally follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/#strive-for-fluent-usage):

- Protocols that describe _what something_ is should read as nouns (e.g. `Collection`).
- Protocols that describe a _capability_ should be named using the suffixes `able`, `ible`, or `ing` (e.g. `Equatable`, `ProgressReporting`).

For protocols that are specifically for one type only, it is acceptable to append `Protocol` to the name.

```swift
public protocol ProductsRemoteProtocol { }

final class ProductsRemote: Remote, ProductsRemoteProtocol { }
```

We usually end up with cases like this when we _have_ to create a protocol to support mocking unit tests.

## String Constants in Nested Enums

When a class/struct that contains localization, we generally group the string constants in a nested enum called `Localization`. In the past, we had other names like `Constants` or `Strings` and it is fine to leave them and follow this naming for new code. For example:

```swift
final class ViewController: UIViewController {
    enum Localization {
        static let title = NSLocalizedString("Products", comment: "Navigation bar title of the products tab.")
    }
}
```

## Test Methods

Contrary to the standard [Camel case](https://en.wikipedia.org/wiki/Camel_case) style in Swift functions, test methods should use [Snake case](https://en.wikipedia.org/wiki/Snake_case). We concluded that this helps with readability especially since test methods can be quite long.

**Preferred:**

```swift
func test_tapping_ScheduleSaleToRow_toggles_PickerRow_in_Sales_section()
```

**Not Preferred:**

```swift
func testTappingScheduleSaleToRowTogglesPickerRowInSalesSection()
```

Note that when referring to a property or a class, we can still use the appropriate Camel or Pascal case for it.

Also, consider writing the test method name in a way that incorporates these three things:

1. What operation are we testing
2. Under what circumstances
3. What is the expected result?

For example:

```swift
func test_evolvePokemon_when_passed_a_Pikachu_then_it_returns_Raichu()
```

Please refer to [Unit Test Naming: The 3 Most Important Parts](https://qualitycoding.org/unit-test-naming/) for some rationale on why this can be a good idea.
