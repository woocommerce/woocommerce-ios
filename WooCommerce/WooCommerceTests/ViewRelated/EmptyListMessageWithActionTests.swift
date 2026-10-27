import XCTest
@testable import WooCommerce

@MainActor
final class EmptyListMessageWithActionTests: XCTestCase {

    private struct Expectations {
        static let message = "Yo!"
        static let buttonMessage = "Semite!"
    }

    func testMessageLabelRendersMessage() throws {
        let subject = try makeView()

        subject.messageText = Expectations.message

        XCTAssertEqual(subject.getMessageLabel().text, Expectations.message)
    }

    func testButtonLabelRendersMessage() throws {
        let subject = try makeView()

        subject.actionText = Expectations.buttonMessage

        XCTAssertEqual(subject.getButtonLabel().text, Expectations.buttonMessage)
    }

    func testBackgroundStyle() throws {
        let subject = try makeView()

        XCTAssertEqual(subject.backgroundColor?.cgColor, UIColor.listBackground.cgColor)
    }

    func testMessageLabelStyle() throws {
        let subject = try makeView()

        let label = subject.getMessageLabel()

        XCTAssertEqual(label.textAlignment, NSTextAlignment.center)
        XCTAssertEqual(label.font, UIFont.body)
    }

    func testActionLabelStyle() throws {
        let subject = try makeView()

        let label = subject.getButtonLabel()

        XCTAssertEqual(label.font, UIFont.body)
        XCTAssertEqual(label.textColor, .text)
    }

    private func makeView() throws -> EmptyListMessageWithActionView {
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("EmptyListMessageWithActionView", owner: nil, options: nil))
        return try XCTUnwrap(nib.first as? EmptyListMessageWithActionView)
    }
}
