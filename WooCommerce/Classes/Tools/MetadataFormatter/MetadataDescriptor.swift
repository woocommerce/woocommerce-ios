import Foundation


///
///
protocol MetadataDescriptor {

    ///
    ///
    var range: NSRange { get }

    ///
    ///
    var value: String? { get }

    ///
    ///
    var url: URL?  { get }

    ///
    ///
    var replacesValueInRange: Bool { get }

    ///
    ///
    func attributes(from styles: MetadataStyles) -> [NSAttributedString.Key: Any]?
}
