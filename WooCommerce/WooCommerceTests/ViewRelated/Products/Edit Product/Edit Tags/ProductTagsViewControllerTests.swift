import Testing
import UIKit
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct ProductTagsViewControllerTests {
    @Test func test_paste_when_text_contains_tabs_then_undo_restores_empty_text() async throws {
        // Given
        let sut = ProductTagsViewController(product: .fake(), completion: { _ in })
        let window = UIWindow()
        window.rootViewController = sut
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        sut.loadViewIfNeeded()
        let textView = try #require(sut.value(forKey: "textView") as? UITextView)
        textView.text = ""
        #expect(textView.becomeFirstResponder())
        textView.undoManager?.removeAllActions()

        let pastedText = "First tag\t\t,\t\tSecond tag"

        // When
        textView.paste(itemProviders: [NSItemProvider(object: pastedText as NSString)])
        for _ in 0..<100 {
            if textView.text.isNotEmpty {
                break
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        // Then
        #expect(textView.text == pastedText)
        let undoManager = try #require(textView.undoManager)
        #expect(undoManager.canUndo)
        undoManager.undo()
        #expect(textView.text.isEmpty)
    }

    @Test func test_text_view_did_change_when_pasted_text_contains_tabs_then_preserves_text_and_selection() throws {
        // Given
        let sut = ProductTagsViewController(product: .fake(), completion: { _ in })
        sut.loadViewIfNeeded()
        let textView = try #require(sut.value(forKey: "textView") as? UITextView)
        let pastedText = "First tag\t\t,\t\tSecond tag"
        let selection = NSRange(location: (pastedText as NSString).length, length: 0)
        textView.text = pastedText
        textView.selectedRange = selection

        // When
        sut.textViewDidChange(textView)

        // Then
        #expect(textView.text == pastedText)
        #expect(textView.selectedRange == selection)
    }
}
