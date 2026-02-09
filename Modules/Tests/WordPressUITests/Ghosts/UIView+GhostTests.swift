import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `UIView Ghost Tests` {
    @Test func `add ghost layer`() {
        let view = UIView()

        view.startGhostAnimation()

        #expect(view.layer.sublayers?.first(where: { $0 is GhostLayer }) != nil)
    }

    @Test func `do not add ghost layer`() {
        let view = UIView()
        view.isGhostableDisabled = true

        view.startGhostAnimation()

        #expect(view.layer.sublayers?.first(where: { $0 is GhostLayer }) == nil)
    }

    @Test func `do not add ghost layer in subviews`() {
        let subview = UIView()
        let view = UIView()
        view.addSubview(subview)
        view.isGhostableDisabled = true

        view.startGhostAnimation()

        #expect(subview.layer.sublayers?.first(where: { $0 is GhostLayer }) == nil)
    }
}
