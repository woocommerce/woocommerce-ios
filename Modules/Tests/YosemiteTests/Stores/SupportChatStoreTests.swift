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
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "How do I configure shipping?",
                                                          onCompletion: { continuation.resume() }))
        }

        // Then
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
                                                          onCompletion: { continuation.resume() }))
        }
        #expect(storedChatCount == 1)

        // When — register again with the same chatID but a different message
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "second",
                                                          onCompletion: { continuation.resume() }))
        }

        // Then — still one row, original title preserved.
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
                                                          onCompletion: { continuation.resume() }))
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
                                                          onCompletion: { continuation.resume() }))
        }
        let initialUpdatedAt = try #require(viewStorage.loadSupportChat(chatID: chatID)?.updatedAt)

        // Sleep a beat so the new timestamp is materially different.
        try await Task.sleep(for: .milliseconds(20))

        // When
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.touchChat(chatID: chatID, onCompletion: { continuation.resume() }))
        }

        // Then
        let bumpedUpdatedAt = try #require(viewStorage.loadSupportChat(chatID: chatID)?.updatedAt)
        #expect(bumpedUpdatedAt > initialUpdatedAt)
    }

    @Test func touchChat_when_row_does_not_exist_then_completes_without_error() async {
        // Given
        let store = makeStore()

        // When — touch a chatID that was never registered.
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.touchChat(chatID: 9999, onCompletion: { continuation.resume() }))
        }

        // Then — idempotent: no row created.
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
                                                              onCompletion: { continuation.resume() }))
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        // When
        let summaries = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { summaries in
                continuation.resume(returning: summaries)
            }))
        }

        // Then
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
                                                          onCompletion: { continuation.resume() }))
        }
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: 2,
                                                          siteID: otherSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "theirs",
                                                          onCompletion: { continuation.resume() }))
        }

        // When
        let summaries = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { summaries in
                continuation.resume(returning: summaries)
            }))
        }

        // Then — only the row scoped to sampleSiteID is returned.
        #expect(summaries.map(\.chatID) == [1])
    }

    @Test func loadChatHistory_when_no_rows_then_returns_empty() async {
        // Given
        let store = makeStore()

        // When
        let summaries = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.loadChatHistory(siteID: sampleSiteID, onCompletion: { summaries in
                continuation.resume(returning: summaries)
            }))
        }

        // Then
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
                                                          onCompletion: { continuation.resume() }))
        }
        #expect(storedChatCount == 1)

        // When
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.deleteChat(chatID: chatID, onCompletion: { continuation.resume() }))
        }

        // Then
        #expect(storedChatCount == 0)
    }

    @Test func deleteChat_when_row_does_not_exist_then_completes_without_error() async {
        // Given
        let store = makeStore()

        // When
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.deleteChat(chatID: 9999, onCompletion: { continuation.resume() }))
        }

        // Then — idempotent.
        #expect(storedChatCount == 0)
    }

    // MARK: - markTicketCreated

    @Test func markTicketCreated_sets_hasCreatedTicket_on_existing_row() async throws {
        // Given — register a chat first.
        let store = makeStore()
        let chatID: Int64 = 4242
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.registerChat(chatID: chatID,
                                                          siteID: sampleSiteID,
                                                          wpcomUserID: sampleWPComUserID,
                                                          botSlug: sampleBotSlug,
                                                          firstUserMessage: "hi",
                                                          onCompletion: { continuation.resume() }))
        }
        #expect(viewStorage.loadSupportChat(chatID: chatID)?.hasCreatedTicket == false)

        // When
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.markTicketCreated(chatID: chatID,
                                                               onCompletion: { continuation.resume() }))
        }

        // Then
        let stored = try #require(viewStorage.loadSupportChat(chatID: chatID))
        #expect(stored.hasCreatedTicket == true)
    }

    @Test func markTicketCreated_when_row_does_not_exist_then_completes_without_error() async {
        // Given
        let store = makeStore()

        // When — mark a chatID that was never registered.
        await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.markTicketCreated(chatID: 9999,
                                                               onCompletion: { continuation.resume() }))
        }

        // Then — idempotent: no row created.
        #expect(storedChatCount == 0)
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

    // MARK: - submitFeedback

    @Test func submitFeedback_forwards_to_remote_with_correct_parameters() async throws {
        // Given
        let store = makeStore()
        remote.whenSubmittingFeedback(thenReturn: .success(()))

        // When
        _ = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.submitFeedback(messageID: 123,
                                                            sessionID: "session-abc",
                                                            upvoted: true,
                                                            onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        #expect(remote.submitFeedbackInvocations.count == 1)
        let invocation = try #require(remote.submitFeedbackInvocations.first)
        #expect(invocation.messageID == 123)
        #expect(invocation.sessionID == "session-abc")
        #expect(invocation.upvoted == true)
    }

    @Test func submitFeedback_when_downvoted_then_forwards_false() async throws {
        // Given
        let store = makeStore()
        remote.whenSubmittingFeedback(thenReturn: .success(()))

        // When
        _ = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.submitFeedback(messageID: 456,
                                                            sessionID: "session-xyz",
                                                            upvoted: false,
                                                            onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        let invocation = try #require(remote.submitFeedbackInvocations.first)
        #expect(invocation.upvoted == false)
    }

    @Test func submitFeedback_propagates_remote_errors() async {
        // Given
        let store = makeStore()
        remote.whenSubmittingFeedback(thenReturn: .failure(NetworkError.timeout()))

        // When
        let result = await withCheckedContinuation { continuation in
            store.onAction(SupportChatAction.submitFeedback(messageID: 123,
                                                            sessionID: "session-abc",
                                                            upvoted: true,
                                                            onCompletion: { result in
                continuation.resume(returning: result)
            }))
        }

        // Then
        switch result {
        case .success:
            Issue.record("Expected submitFeedback to propagate a failure")
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
