import Foundation
import Testing
@testable import NetworkingCore

@Suite("WordPressRESTAPIRootCache")
struct WordPressRESTAPIRootCacheTests {

    // Each test gets a fresh cache instance — no shared singleton, no tearDown needed.
    let sut = WordPressRESTAPIRootCache()

    // MARK: - Basic Functionality

    @Test func test_root_returns_nil_when_cache_is_empty() {
        // When / Then
        #expect(sut.root(for: "https://example.com") == nil)
    }

    @Test func test_setRoot_then_root_returns_stored_value() {
        // Given
        let siteURL = "https://example.com"
        let root = "https://example.com/wp-json/"

        // When
        sut.setRoot(root, for: siteURL)

        // Then
        #expect(sut.root(for: siteURL) == root)
    }

    @Test func test_setRoot_overwrites_existing_value() {
        // Given
        let siteURL = "https://example.com"
        sut.setRoot("https://example.com/wp-json/", for: siteURL)

        // When
        let updated = "https://example.com/?rest_route=/"
        sut.setRoot(updated, for: siteURL)

        // Then
        #expect(sut.root(for: siteURL) == updated)
    }

    @Test func test_root_normalizes_trailing_slash_in_site_url() {
        // Given
        sut.setRoot("https://example.com/wp-json/", for: "https://example.com")

        // When / Then — trailing slash variant should resolve to the same entry
        #expect(sut.root(for: "https://example.com/") == "https://example.com/wp-json/")
    }

    @Test func test_root_treats_different_site_urls_independently() {
        // Given
        let rootA = "https://site-a.com/wp-json/"
        let rootB = "https://site-b.com/?rest_route=/"
        sut.setRoot(rootA, for: "https://site-a.com")
        sut.setRoot(rootB, for: "https://site-b.com")

        // When / Then
        #expect(sut.root(for: "https://site-a.com") == rootA)
        #expect(sut.root(for: "https://site-b.com") == rootB)
    }

    @Test func test_reset_clears_all_entries() {
        // Given
        sut.setRoot("https://example.com/wp-json/", for: "https://example.com")
        sut.setRoot("https://other.com/wp-json/", for: "https://other.com")

        // When
        sut.reset()

        // Then — reads go through queue.sync, so they naturally wait for the reset barrier
        #expect(sut.root(for: "https://example.com") == nil)
        #expect(sut.root(for: "https://other.com") == nil)
    }

    // MARK: - Thread Safety

    @Test func test_concurrent_writes_are_thread_safe() {
        // Given
        let iterations = 500

        // When — concurrent writes to distinct keys; must not crash
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            sut.setRoot("https://example.com/wp-json/\(i)/", for: "https://site-\(i).com")
        }

        // Then — all written values are readable
        for i in 0..<iterations {
            #expect(sut.root(for: "https://site-\(i).com") == "https://example.com/wp-json/\(i)/")
        }
    }

    @Test func test_concurrent_reads_are_thread_safe() {
        // Given
        let siteURL = "https://example.com"
        sut.setRoot("https://example.com/wp-json/", for: siteURL)

        // When — many concurrent reads; must not crash
        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            _ = sut.root(for: siteURL)
        }

        // Then — value still intact
        #expect(sut.root(for: siteURL) == "https://example.com/wp-json/")
    }

    @Test func test_concurrent_mixed_reads_and_writes_are_thread_safe() {
        // Given
        let iterations = 500
        let siteURL = "https://example.com"
        sut.setRoot("initial", for: siteURL)

        // When — interleaved reads and writes; must not crash or deadlock
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i.isMultiple(of: 2) {
                sut.setRoot("root-\(i)", for: siteURL)
            } else {
                _ = sut.root(for: siteURL)
            }
        }

        // Then — a value is present (one of the writes won the last-write-wins race)
        #expect(sut.root(for: siteURL) != nil)
    }

    @Test func test_concurrent_reset_and_setRoot_are_thread_safe() {
        // Given
        let iterations = 200

        // When — concurrent resets and writes; must not crash or deadlock
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            if i.isMultiple(of: 3) {
                sut.reset()
            } else {
                sut.setRoot("https://example.com/wp-json/", for: "https://site-\(i).com")
            }
        }

        // Then — no assertion on final state needed; absence of crash is the guarantee
    }
}
