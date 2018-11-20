import Foundation


/// Describes the kind of data contained within a specific Text Range.
///
protocol StringDescriptor {

    /// Text Range associated.
    ///
    var range: NSRange { get }

    /// Associated URL.
    ///
    var url: URL? { get }

    /// String Payload associated to the range.
    ///
    var value: String? { get }

    /// Returns the `Text Style` that should be applied over the associated range.
    ///
    func attributes(from styles: StringStyles) -> [NSAttributedString.Key: Any]?
}
