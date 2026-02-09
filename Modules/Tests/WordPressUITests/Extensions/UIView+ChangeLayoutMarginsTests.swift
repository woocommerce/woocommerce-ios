import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `UIView ChangeLayoutMargins Tests` {

    let view: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return view
    }()

    @Test func `change only top layout margin`() {
        view.changeLayoutMargins(top: 10)

        #expect(view.layoutMargins.top == 10)
        #expect(view.layoutMargins.left == 5)
        #expect(view.layoutMargins.bottom == 5)
        #expect(view.layoutMargins.right == 5)
    }

    @Test func `change only left layout margin`() {
        view.changeLayoutMargins(left: 10)

        #expect(view.layoutMargins.top == 5)
        #expect(view.layoutMargins.left == 10)
        #expect(view.layoutMargins.bottom == 5)
        #expect(view.layoutMargins.right == 5)
    }

    @Test func `change only bottom layout margin`() {
        view.changeLayoutMargins(bottom: 10)

        #expect(view.layoutMargins.top == 5)
        #expect(view.layoutMargins.left == 5)
        #expect(view.layoutMargins.bottom == 10)
        #expect(view.layoutMargins.right == 5)
    }

    @Test func `change only right layout margin`() {
        view.changeLayoutMargins(right: 10)

        #expect(view.layoutMargins.top == 5)
        #expect(view.layoutMargins.left == 5)
        #expect(view.layoutMargins.bottom == 5)
        #expect(view.layoutMargins.right == 10)
    }
}
