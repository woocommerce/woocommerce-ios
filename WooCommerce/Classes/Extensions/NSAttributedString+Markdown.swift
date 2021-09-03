import Foundation
import Down

extension NSAttributedString {
    convenience init(markdown: String) throws {
        self.init(attributedString: try Down(markdownString: markdown).toAttributedString())
    }
}
