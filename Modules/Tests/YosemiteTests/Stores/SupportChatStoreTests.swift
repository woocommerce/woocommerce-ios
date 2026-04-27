import Foundation
import Testing
import YosemiteTestHelpers
@testable import Networking
@testable import Storage
@testable import Yosemite

@MainActor
struct SupportChatStoreTests {
    private let dispatcher: Dispatcher
    private let storageManager: MockStorageManager
    private let network: MockNetwork
    private let remote: MockSupportChatRemote

    private var viewStorage: StorageType { storageManager.viewStorage }
    private var storedChatCount: Int { viewStorage.countObjects(ofType: StoredSupportChat.self) }

    private let sampleSiteID: Int64 = 134
    private let sampleWPComUserID: Int64 = 9001
    private let sampleBotSlug = "woo-chat-allusers"

    init() {
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockSupportChatRemote()
    }

    private func makeStore() -> SupportChatStore {
        SupportChatStore(dispatcher: dispatcher,
                         storageManager: storageManager,
                         network: network,
                         remote: remote)
    }

    // MARK: - registerChat

    @Test func registerChat_inserts_a_row_with_all_fields_populated() async throws {
        // Given
        let store = makeStore()
        let chatID: Int64 = 4242

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "How do I configure shipping?",
                                                          onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then
        #expect(error == nil)
        #expect(storedChatCount == 1)
        let stored = try #require(viewStorage.loadSupportChat(chatID: chatID))
        #expect(stored.chatID == chatID)
        #expect(stored.siteID == sampleSiteID)
        #expect(stored.wpcomUserID == sampleWPComUserID)
        #expect(stored.botSlug == sampleBotSlug)
        #expect(stored.title == "How do I configure shipping?")
        #expect(stored.createdAt != nil)
        #expect(stored.updatedAt != nil)
    }

    @Test func registerChat_when_row_already_exists_then_does_not_insert_duplicate() async throws {
        // Given — one row already persisted
        let store = makeStore()
        let chatID: Int64 = 4242
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "first",
                                                          onCompletion: { _ in continuation.resume() }))
        }
        #expect(storedChatCount == 1)

        // When — register again with the same chatID but a different message
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "second",
                                                          onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then — still one row, original title preserved.
        #expect(error == nil)
        #expect(storedChatCount == 1)
        let stored = try #require(viewStorage.loadSupportChat(chatID: chatID))
        #expect(stored.title == "first")
    }

    @Test func registerChat_clamps_long_first_user_message_to_50_chars_and_trims() async throws {
        // Given
        let store = makeStore()
        let longMessage = "   " + String(repeating: "a", count: 80) + "   "

        // When
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: 1,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: longMessage,
                                                          onCompletion: { _ in continuation.resume() }))
        }

        // Then — leading/trailing whitespace trimmed, then clamped to 50 chars.
        let stored = try #require(viewStorage.loadSupportChat(chatID: 1))
        let title = try #require(stored.title)
        #expect(title.count == 50)
        #expect(title == String(repeating: "a", count: 50))
    }

    // MARK: - touchChat

    @Test func touchChat_bumps_updatedAt_on_existing_row() async throws {
        // Given — register a chat, capture its initial updatedAt.
        let store = makeStore()
        let chatID: Int64 = 4242
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "hi",
                                                          onCompletion: { _ in continuation.resume() }))
        }
        let initialUpdatedAt = try #require(viewStorage.loadSupportChat(chatID: chatID)?.updatedAt)

        // Sleep a beat so the new timestamp is materially different.
        try await Task.sleep(for: .milliseconds(20))

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.touchChat(chatID: chatID, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then
        #expect(error == nil)
        let bumpedUpdatedAt = try #require(viewStorage.loadSupportChat(chatID: chatID)?.updatedAt)
        #expect(bumpedUpdatedAt > initialUpdatedAt)
    }

    @Test func touchChat_when_row_does_not_exist_then_completes_without_error() async {
        // Given
        let store = makeStore()

        // When — touch a chatID that was never registered.
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.touchChat(chatID: 9999, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then — idempotent: no error, no row created.
        #expect(error == nil)
        #expect(storedChatCount == 0)
    }

    // MARK: - loadChatHistory

    @Test func loadChatHistory_returns_rows_sorted_by_updatedAt_descending() async throws {
        // Given — three rows on the same site with distinct updatedAt timestamps.
        let store = makeStore()
        for chatID in Int64(1)...Int64(3) {
            await withCheckedContinuation { continuation in
                store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                              siteID: sampleSiteID,
                                                              wpcomUserID: sampleWPComUserID,
                                                              botSlug: sampleBotSlug,
                                                              firstUserMessage: "chat \(chatID)",
                                                              onCompletion: { _ in continuation.resume() }))
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let summaries = try result.get()
        #expect(summaries.map(\.chatID) == [3, 2, 1])
    }

    @Test func loadChatHistory_filters_by_siteID() async throws {
        // Given — rows on two different sites.
        let store = makeStore()
        let otherSiteID: Int64 = 999
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: 1,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "ours",
                                                          onCompletion: { _ in continuation.resume() }))
        }
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: 2,
                                                          siteID: otherSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "theirs",
                                                          onCompletion: { _ in continuation.resume() }))
        }

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then — only the row scoped to sampleSiteID is returned.
        let summaries = try result.get()
        #expect(summaries.map(\.chatID) == [1])
    }

    @Test func loadChatHistory_when_no_rows_then_returns_empty() async throws {
        // Given
        let store = makeStore()

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let summaries = try result.get()
        #expect(summaries.isEmpty)
    }

    // MARK: - deleteChat

    @Test func deleteChat_removes_the_row() async throws {
        // Given
        let store = makeStore()
        let chatID: Int64 = 4242
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "hi",
                                                          onCompletion: { _ in continuation.resume() }))
        }
        #expect(storedChatCount == 1)

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.deleteChat(chatID: chatID, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then
        #expect(error == nil)
        #expect(storedChatCount == 0)
    }

    @Test func deleteChat_when_row_does_not_exist_then_completes_without_error() async {
        // Given
        let store = makeStore()

        // When
        let error = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.deleteChat(chatID: 9999, onCompletion: { error in
                continuation.resume(returning: error)
            }))
        }

        // Then — idempotent.
        #expect(error == nil)
    }

    // MARK: - fetchChat

    @Test func fetchChat_forwards_to_remote_with_botSlug_and_chatID() async throws {
        // Given
        let store = makeStore()
        remote.whenFetchingChat(thenReturn: .success(.fake()))

        // When
        _ = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.fetchChat(botSlug: sampleBotSlug,
                                                       chatID: 4242,
                                                       completion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(remote.fetchChatInvocations.count == 1)
        let invocation = try #require(remote.fetchChatInvocations.first)
        #expect(invocation.botSlug == sampleBotSlug)
        #expect(invocation.chatID == 4242)
    }

    @Test func fetchChat_propagates_remote_errors() async {
        // Given
        let store = makeStore()
        remote.whenFetchingChat(thenReturn: .failure(NetworkError.timeout()))

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.fetchChat(botSlug: sampleBotSlug,
                                                       chatID: 4242,
                                                       completion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        switch result {
        case .success:
            Issue.record("Expected fetchChat to propagate a failure")
        case .failure(let error):
            #expect(error is NetworkError)
        }
    }
}

// MARK: - Test helper
//
private extension SupportChatResponse {
    static func fake() -> SupportChatResponse {
        SupportChatResponse(chatID: 4242,
                            sessionID: "session",
                            botSlug: "woo-chat-allusers",
                            botVersion: "1.4.3",
                            messages: [])
    }
}
