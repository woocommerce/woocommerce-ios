import Foundation
import Yosemite

enum JustInTimeMessagesSourceScreen {
    case dashboard
}

/// Provides the Just in Time Messages content for a given source screen and site. It also tracks the requests success or error.
///
final class JustInTimeMessagesProvider {
    private let stores: StoresManager
    private let analytics: Analytics
    private let appScreenJitmSourceMapping: [JustInTimeMessagesSourceScreen: String] = [.dashboard: "my_store"]

    init(stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.analytics = analytics
    }

    func loadMessage(for screen: JustInTimeMessagesSourceScreen, siteID: Int64) async throws -> JustInTimeMessageViewModel? {
        guard let source = appScreenJitmSourceMapping[screen] else {
            DDLogInfo("Could not load JITM for \(screen) because there is no mapping for the given screen")
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let action = JustInTimeMessageAction.loadMessage(
                siteID: siteID,
                screen: source,
                hook: .adminNotices) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(messages):
                        guard let message = messages.first else {
                            return continuation.resume(returning: nil)
                        }
                        self.analytics.track(event:
                                .JustInTimeMessage.fetchSuccess(source: source,
                                                                messageID: message.messageID,
                                                                count: Int64(messages.count)))
                        let viewModel = JustInTimeMessageViewModel(
                            justInTimeMessage: message,
                            screenName: source,
                            siteID: siteID)
                        continuation.resume(returning: viewModel)
                    case let .failure(error):
                        self.analytics.track(event:
                                .JustInTimeMessage.fetchFailure(source: source,
                                                                error: error))
                        continuation.resume(throwing: error)
                    }
                }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
