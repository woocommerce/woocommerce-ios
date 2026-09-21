import Foundation
import Testing
@testable import WooCommerce

struct LearnMoreAttributedTextTests {

    @Test func test_handle_when_matching_url_without_custom_action_then_presents_url() throws {
        // Given
        let expectedURL = try #require(URL(string: "https://woocommerce.com"))
        let sut = LearnMoreAttributedTextURLHandler(expectedURL: expectedURL, onTapURL: nil)
        var presentedURL: URL?

        // When
        let result = sut.handle(expectedURL) { url in
            presentedURL = url
        }

        // Then
        #expect(result == .handled)
        #expect(presentedURL == expectedURL)
    }

    @Test func test_handle_when_matching_url_with_custom_action_then_calls_custom_action() throws {
        // Given
        let expectedURL = try #require(URL(string: "https://woocommerce.com"))
        var customActionURL: URL?
        var presentedURL: URL?
        let sut = LearnMoreAttributedTextURLHandler(expectedURL: expectedURL, onTapURL: { url in
            customActionURL = url
        })

        // When
        let result = sut.handle(expectedURL) { url in
            presentedURL = url
        }

        // Then
        #expect(result == .handled)
        #expect(customActionURL == expectedURL)
        #expect(presentedURL == nil)
    }

    @Test func test_handle_when_url_does_not_match_then_uses_system_action() throws {
        // Given
        let expectedURL = try #require(URL(string: "https://woocommerce.com"))
        let otherURL = try #require(URL(string: "https://wordpress.com"))
        var customActionURL: URL?
        var presentedURL: URL?
        let sut = LearnMoreAttributedTextURLHandler(expectedURL: expectedURL, onTapURL: { url in
            customActionURL = url
        })

        // When
        let result = sut.handle(otherURL) { url in
            presentedURL = url
        }

        // Then
        #expect(result == .systemAction)
        #expect(customActionURL == nil)
        #expect(presentedURL == nil)
    }
}
