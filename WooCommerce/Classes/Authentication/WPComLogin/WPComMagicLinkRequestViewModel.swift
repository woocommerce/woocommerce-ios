import Foundation
import WordPressUI

class WPComMagicLinkRequestViewModel: ObservableObject {
    let email: String

    private(set) var avatarURL: URL?
    @Published private(set) var isLoading = false

    init(email: String) {
        self.email = email

        self.avatarURL = Gravatar.gravatarUrl(for: email, defaultImage: .mp)
    }

    func sendMagicLink() {
        // TODO
    }
}
