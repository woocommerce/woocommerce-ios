
import Foundation

/// A typealias for arguments of `copy()` methods signifying that the required property's value
/// will be copied by default if no value is given.
///
/// For example:
///
/// ```
/// struct Person {
///     let id: Int
///     let name: String
///
///     func copy(id: CopiableProp<Int> = .copy,
///               name: CopiableProp<String> = .copy) -> Person {
///         Person(id: id ?? self.id,
///                name: name ?? self.name)
///     }
/// }
///
/// let luke = Person(id: 1, name: "Luke")
///
/// let leia = luke.copy(name: "Leia")
/// ```
///
/// The variable `leia` will have the same `id` as `luke`:
///
/// ```
/// { id: 1, name: "Leia" }
/// ```
///
public typealias CopiableProp<Wrapped> = Optional<Wrapped>

/// A typealias for arguments of `copy()` methods signifying that the property is `Optional` and
/// that the existing value will be copied by default if no value is given.
///
/// Using `NullableCopiableProp` allows us to set an `Optional` property to `nil` when copying.
/// For example, if passing a variable as an argument, the property will be set to `nil` as
/// expected:
///
/// ```
/// struct Person {
///     let id: Int
///     let name: String
///     let address: String?
///
///     func copy(id: CopiableProp<Int> = .copy,
///               name: CopiableProp<String> = .copy,
///               address: NullableCopiableProp<String> = .copy) -> Person {
///         Person(id: id ?? self.id,
///                name: name ?? self.name,
///                address: address ?? self.address)
///     }
/// }
///
/// let luke = Person(id: 1, name: "Luke", address: "Jakku")
///
/// let address: String? = nil
///
/// let lukeWithNoAddress = luke.copy(address: address)
/// ```
///
/// The variable `lukeWithNoAddress` will have a `nil` `address` as expected:
///
/// ```
/// { id: 1, name: "Luke", address: nil }
/// ```
///
/// In order to **directly** set a `NullableCopiableProp` to `nil`, the argument `.some(nil)`
/// must be passed:
///
/// ```
/// let lukeWithNoAddress = luke.copy(address: .some(nil))
/// ```
///
/// We will still end up with the same result:
///
/// ```
/// { id: 1, name: "Luke", address: nil }
/// ```
///
public typealias NullableCopiableProp<Wrapped> = CopiableProp<Wrapped?>

// MARK: - Support for `.copy` alias

extension CopiableProp {
    /// Allow `CopiableProp<>` declarations to use a `.copy` alias as the default value instead of
    /// using `nil`.
    ///
    /// For example, instead of declaring `copy()` arguments like this:
    ///
    /// ```
    /// func copy(orderID: CopiableProp<Int> = nil)
    /// ```
    ///
    /// We can declare them like this:
    ///
    /// ```
    /// func copy(orderID: CopiableProp<Int> = .copy)
    /// ```
    ///
    /// Using `.copy` makes it a bit more clearer what will happen if you don't declare or
    /// provide a different value.
    ///
    public static var copy: Wrapped? {
        nil
    }
}
