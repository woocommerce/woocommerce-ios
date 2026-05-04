import SwiftUI

@MainActor
final class ChatScrollController: ObservableObject {

    @Published var isNearBottom: Bool = true

    var scrollToBottomHandler: ((Bool) -> Void)?

    func scrollToBottom(animated: Bool) {
        scrollToBottomHandler?(animated)
    }
}
