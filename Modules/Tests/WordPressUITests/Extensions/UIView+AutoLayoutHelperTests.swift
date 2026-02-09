import Testing
import UIKit
@testable import WordPressUI

@MainActor
struct `UIView AutoLayout Helper Tests` {
    let view = UIView(frame: .zero)
    let subview = UIView(frame: .zero)

    // MARK: tests for `pinSubviewToAllEdges`

    @Test func `pinSubviewToAllEdges with zero insets`() throws {
        view.addSubview(subview)
        view.pinSubviewToAllEdges(subview)

        let topConstraint = try getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.topAnchor && $0.secondAnchor == subview.topAnchor })
        #expect(topConstraint.constant == 0)

        let leadingConstraint = try getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        #expect(leadingConstraint.constant == 0)

        let trailingConstraint = try getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        #expect(trailingConstraint.constant == 0)

        let bottomConstraint = try getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        #expect(bottomConstraint.constant == 0)
        #expect(bottomConstraint.secondAnchor == subview.bottomAnchor)
    }

    @Test func `pinSubviewToAllEdges with non-zero insets`() throws {
        view.addSubview(subview)
        let insets = UIEdgeInsets(top: 10, left: 12, bottom: 17, right: 25)
        view.pinSubviewToAllEdges(subview, insets: insets)

        // Self.top = subview.top - insets.top
        let topConstraint = try getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.topAnchor && $0.secondAnchor == subview.topAnchor })
        #expect(topConstraint.constant == -insets.top)

        // Self.leading = subview.leading - insets.left
        let leadingConstraint = try getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        #expect(leadingConstraint.constant == -insets.left)

        // Self.trailing = subview.trailing + insets.right
        let trailingConstraint = try getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        #expect(trailingConstraint.constant == insets.right)

        // Self.bottom = subview.bottom + insets.bottom
        let bottomConstraint = try getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        #expect(bottomConstraint.constant == insets.bottom)
    }

    // MARK: tests for `pinSubviewToSafeArea`

    @Test func `pinSubviewToSafeArea with zero insets`() throws {
        view.addSubview(subview)
        view.pinSubviewToSafeArea(subview)

        let topConstraint = try getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.safeAreaLayoutGuide.topAnchor && $0.secondAnchor == subview.topAnchor })
        #expect(topConstraint.constant == 0)

        let leadingConstraint = try getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.safeAreaLayoutGuide.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        #expect(leadingConstraint.constant == 0)

        let trailingConstraint = try getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.safeAreaLayoutGuide.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        #expect(trailingConstraint.constant == 0)

        let bottomConstraint = try getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.safeAreaLayoutGuide.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        #expect(bottomConstraint.constant == 0)
    }

    @Test func `pinSubviewToSafeArea with non-zero insets`() throws {
        view.addSubview(subview)
        let insets = UIEdgeInsets(top: 10, left: 12, bottom: 17, right: 25)
        view.pinSubviewToSafeArea(subview, insets: insets)

        // Self safe area.top = subview.top - insets.top
        let topConstraint = try getConstraint(from: view,
                                          filter: { $0.firstAnchor == view.safeAreaLayoutGuide.topAnchor && $0.secondAnchor == subview.topAnchor })
        #expect(topConstraint.constant == -insets.top)

        // Self safe area.leading = subview.leading - insets.left
        let leadingConstraint = try getConstraint(from: view,
                                              filter: { $0.firstAnchor == view.safeAreaLayoutGuide.leadingAnchor && $0.secondAnchor == subview.leadingAnchor })
        #expect(leadingConstraint.constant == -insets.left)

        // Self safe area.trailing = subview.trailing + insets.right
        let trailingConstraint = try getConstraint(from: view,
                                               filter: { $0.firstAnchor == view.safeAreaLayoutGuide.trailingAnchor && $0.secondAnchor == subview.trailingAnchor })
        #expect(trailingConstraint.constant == insets.right)

        // Self safe area.bottom = subview.bottom + insets.bottom
        let bottomConstraint = try getConstraint(from: view,
                                             filter: { $0.firstAnchor == view.safeAreaLayoutGuide.bottomAnchor && $0.secondAnchor == subview.bottomAnchor })
        #expect(bottomConstraint.constant == insets.bottom)
    }

    private func getConstraint(from view: UIView, filter: (NSLayoutConstraint) -> Bool) throws -> NSLayoutConstraint {
        let constraints = view.constraints.filter(filter)
        #expect(constraints.count == 1, "Exactly one constraint corresponding to the given filter should have been created")
        return try #require(constraints.first)
    }
}
