import Foundation
import Aztec

fileprivate let attrStringHTMLConverter = Aztec.HTMLConverter()

extension NSAttributedString {
    convenience init(format: String, _ arguments: CVarArg...) {
        let formatted = String(format: format, arguments: arguments)
        self.init(attributedString: attrStringHTMLConverter.attributedString(from: formatted, defaultAttributes: nil))
    }
}
