import Foundation

///
/// The goal of these utilities is to be able to provide a type-safe API when creating `NSPredicates`.
/// This is achieved by overloading logical operators between a `Swift.KeyPath` which is type-safe and a `Value`.
/// `KeyPaths` and `Values` can be transformed into `NSExpression` via a native `APIs`
/// Which then can be converted to a `NSComparisonPredicate` using the `init(leftExpression, rightExpression, operator)`method.
///


// MARK: - Types

/// Protocol to enclose `CompoundPredicate` and `ComparisonPredicate` instances  to be able perform operations between them.
///
public protocol TypedPredicate: NSPredicate {}

/// Abstraction of `NSCompoundPredicate` that conforms to  `TypedPredicate`
///
public final class CompoundPredicate: NSCompoundPredicate, TypedPredicate {}

/// Abstraction of `NSComparisonPredicate` that conforms to  `TypedPredicate`
///
public final class ComparisonPredicate: NSComparisonPredicate, TypedPredicate {}


// MARK: - Compound Operators Overloads

/// Overloads for compound operators.
/// Each operator takes `TypedPredicate` instances and returns a `CompoundPredicate` that evaluate the predicates using their respective logical rule.
///

/// Overloads the `AND` operator between two predicates, returns a `CompoundPredicate` that evaluates the two predicates with the `&&` rule.
///
public func && (p1: TypedPredicate, p2: TypedPredicate) -> CompoundPredicate {
    CompoundPredicate(type: .and, subpredicates: [p1, p2])
}

/// Overloads the `OR` operator between two predicates, returns a `CompoundPredicate` that evaluates the two predicates with the `||` rule.
///
public func || (p1: TypedPredicate, p2: TypedPredicate) -> CompoundPredicate {
    CompoundPredicate(type: .or, subpredicates: [p1, p2])
}

// MARK: - Comparison Operators Overloads

/// Overloads for comparison  operators.  Each operator takes a `KeyPath` and a `Value`
/// That will be mapped to `NSExpressions` instances  for then constructing a `ComparisonPredicate` with the correct comparison rule.
/// These overloads make use of `Generics` because need to know at compile time that the `KeyPath.ResultingType` has the same type as the `Value`.
/// As well as making sure that those values are `Equatable`.

/// Overloads the `equal` operator between a `KeyPath` and a `Value`. Returns a `ComparisonPredicate` that evaluates the parameters using the `==` rule.
///
public func == <RootType, ResultingType: Equatable>(keyPath: KeyPath<RootType, ResultingType>, value: ResultingType) -> ComparisonPredicate {
    ComparisonPredicate(keyPath, .equalTo, value)
}

/// Defines a new  operator `=~` between a `KeyPath` and a `Value`. Returns a `ComparisonPredicate` that evaluates the parameters using the `==[c]` rule.
///
infix operator =~ : ComparisonPrecedence
public func =~ <RootType, ResultingType: Equatable>(keyPath: KeyPath<RootType, ResultingType>, value: ResultingType) -> ComparisonPredicate {
    ComparisonPredicate(keyPath, .equalTo, value, .caseInsensitive)
}

/// Overloads the `not equal` operator between a `KeyPath` and a `Value`. Returns a `ComparisonPredicate` that evaluates the parameters using the `!=` rule.
///
public func != <RootType, ResultingType: Equatable>(keyPath: KeyPath<RootType, ResultingType>, value: ResultingType) -> ComparisonPredicate {
    ComparisonPredicate(keyPath, .notEqualTo, value)
}

/// Overloads the  `IN` operator between a `KeyPath` and a `[Value]`. Returns a `ComparisonPredicate` that evaluates the parameters using the `===` rule.
///
public func === <RootType, ResultingType: Equatable>(keyPath: KeyPath<RootType, ResultingType>, value: Array<ResultingType>) -> ComparisonPredicate {
    ComparisonPredicate(keyPath, .in, value)
}

// MARK: - Convenience Initializers

internal extension ComparisonPredicate {
    /// Returns a `ComparisonPredicate` by converting the parameters into `NSExpression` instances using the provided `Operator` as a modifier.
    ///
    convenience init<RootType, ResultingType>(_ keyPath: KeyPath<RootType, ResultingType>,
                                              _ operator: NSComparisonPredicate.Operator,
                                              _ value: Any?,
                                              _ options: NSComparisonPredicate.Options = []) {
        let keyPathExpression = NSExpression(forKeyPath: keyPath)
        let valueExpression = NSExpression(forConstantValue: value)
        self.init(leftExpression: keyPathExpression, rightExpression: valueExpression, modifier: .direct, type: `operator`, options: options)
    }
}
