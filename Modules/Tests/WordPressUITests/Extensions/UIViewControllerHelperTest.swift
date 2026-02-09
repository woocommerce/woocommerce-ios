import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `UIViewController Helper Tests` {
    let vca = UIViewController()
    let vcb = UIViewController()

    @Test func `add child view controller`() {
        vca.add(vcb)
        #expect(!vca.children.isEmpty, "vca.children shouldn't be empty")
    }

    @Test func `remove child view controller`() {
        vca.remove(vcb)
        #expect(vca.children.isEmpty, "vca.children should be empty")
    }
}
