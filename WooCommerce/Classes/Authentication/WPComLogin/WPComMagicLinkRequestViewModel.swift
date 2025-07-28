import Foundation
import WooFoundation
import WordPressAuthenticator
import WordPressUI

final class WPComMagicLinkRequestViewModel: ObservableObject {
    let email: String

    @Published private(set) var isLoading = false
    let avatarURL: URL?

    private let onMagicLinkSent: (String) -> Void
    private let onUseUsernamePassword: () -> Void
    private let onError: (String) -> Void

    private let accountService: WordPressComAccountServiceProtocol
    private let analytics: Analytics

    init(email: String,
         onMagicLinkSent: @escaping (String) -> Void,
         onUseUsernamePassword: @escaping () -> Void,
         onError: @escaping (String) -> Void,
         accountService: WordPressComAccountServiceProtocol = WordPressComAccountService(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.email = email
        self.avatarURL = Gravatar.gravatarUrl(for: email, defaultImage: .mp)

        self.onMagicLinkSent = onMagicLinkSent
        self.onUseUsernamePassword = onUseUsernamePassword
        self.onError = onError

        self.accountService = accountService
        self.analytics = analytics
    }

    @MainActor
    func sendMagicLink() async {
        isLoading = true
        await handleSendingMagicLink()
        isLoading = false
    }

    func useUsernamePassword() {
        onUseUsernamePassword()
    }
}

private extension WPComMagicLinkRequestViewModel {
    @MainActor
    func handleSendingMagicLink() async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                accountService.requestAuthenticationLink(for: email,
                                                         jetpackLogin: false,
                                                         createAccountIfNotFound: false,
                                                         success: {
                    continuation.resume()
                }, failure: { error in
                    continuation.resume(throwing: error)
                })
            }
            onMagicLinkSent(email)
        } catch {
            onError(error.localizedDescription)
            analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, failure: error))
        }
    }
}
