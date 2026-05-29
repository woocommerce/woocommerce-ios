import Foundation
import SwiftUI
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct MessageBubbleRenderingTests {

    private let docsURL = URL(string: "https://woocommerce.com/document/woocommerce-ios/")!

    @Test
    func test_renderedText_when_content_has_markdown_link_then_run_carries_link_url() {
        // Given
        let content = "Read more [here](https://woocommerce.com/document/woocommerce-ios/)."
        let bubble = MessageBubble(message: ChatMessage(role: .assistant, segments: [], isStreaming: false))

        // When
        let rendered = bubble.renderedText(content, linkColor: .assistantLink)

        // Then
        let linkRun = rendered.runs.first { $0.link != nil }
        #expect(linkRun?.link == docsURL)
    }

    @Test
    func test_renderedText_when_content_has_markdown_link_then_link_run_is_underlined_and_colored() {
        // Given
        let content = "Read more [here](https://woocommerce.com/document/woocommerce-ios/)."
        let bubble = MessageBubble(message: ChatMessage(role: .assistant, segments: [], isStreaming: false))

        // When
        let rendered = bubble.renderedText(content, linkColor: .assistantLink)

        // Then
        let linkRun = rendered.runs.first { $0.link != nil }
        #expect(linkRun?.underlineStyle == .single)
        #expect(linkRun?.foregroundColor == Color.assistantLink)
    }

    @Test
    func test_renderedText_when_content_has_no_markdown_then_text_is_unstyled_and_unchanged() {
        // Given
        let content = "You can access the WooCommerce iOS app documentation."
        let bubble = MessageBubble(message: ChatMessage(role: .assistant, segments: [], isStreaming: false))

        // When
        let rendered = bubble.renderedText(content, linkColor: .assistantLink)

        // Then
        #expect(String(rendered.characters) == content)
        for run in rendered.runs {
            #expect(run.link == nil)
            #expect(run.underlineStyle == nil)
            #expect(run.foregroundColor == nil)
        }
    }

    @Test
    func test_renderedText_when_content_has_bold_markdown_then_inline_styling_is_preserved() {
        // Given
        let content = "This is **important** text."
        let bubble = MessageBubble(message: ChatMessage(role: .assistant, segments: [], isStreaming: false))

        // When
        let rendered = bubble.renderedText(content, linkColor: .assistantLink)

        // Then
        #expect(String(rendered.characters) == "This is important text.")
        let boldRun = rendered.runs.first { $0.inlinePresentationIntent == .stronglyEmphasized }
        #expect(boldRun != nil)
    }
}
