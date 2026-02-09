import Testing
import UIKit
import WordPressUI

struct `UIColor Helpers Tests` {

    @Test func `hexString`() {
        #expect(UIColor.red.hexString().lowercased() == "ff0000")

        // hexString works for RGB and grayscale colors
        #expect(UIColor.black.hexString().lowercased() == "000000")
        #expect(UIColor(white: 1, alpha: 1).hexString().lowercased() == "ffffff")
    }
}
