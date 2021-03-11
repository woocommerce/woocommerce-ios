import Foundation

/// Collection of fake values for most common types
///

extension Int64 {
    /// Returns `0`
    ///
    static func fake() -> Self {
        0
    }
}

extension Int {
    /// Returns `0`
    ///
    static func fake() -> Self {
        0
    }
}

extension Double {
    /// Returns `0.0`
    ///
    static func fake() -> Self {
        0.0
    }
}

extension Decimal {
    /// Returns `.zero`
    ///
    static func fake() -> Self {
        .zero
    }
}

extension NSDecimalNumber {
    /// Returns `.zero`
    ///
    static func fake() -> NSDecimalNumber {
        .zero
    }
}

extension String {
    /// Returns an empty `string`
    ///
    static func fake() -> Self {
        ""
    }
}

extension Date {
    /// Returns the current `date`
    ///
    static func fake() -> Self {
        Date()
    }
}

extension Bool {
    /// Returns `false`
    ///
    static func fake() -> Self {
        false
    }
}

extension URL {
    /// Returns an empty `URL`
    ///
    static func fake() -> Self {
        NSURL() as URL
    }
}

extension Optional {
    /// Returns `nil`
    ///
    static func fake() -> Self {
        nil
    }
}

extension Array {
    /// Returns an empty `array`
    ///
    static func fake() -> Self {
        []
    }
}

extension Dictionary {
    /// Returns an empty `dictionary`
    static func fake() -> Self {
        [:]
    }
}

extension Data {
    /// Returns an empty `Data` type
    static func fake() -> Self {
        .init()
    }
}

extension NSRange {
    /// Returns an empty `NSRange` type
    static func fake() -> Self {
        .init()
    }
}
