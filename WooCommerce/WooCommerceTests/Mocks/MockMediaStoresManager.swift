import Yosemite
@testable import WooCommerce

/// MockMediaStoresManager: allows mocking for stats v4 availability and last shown stats version.
///
final class MockMediaStoresManager: DefaultStoresManager {

    /// Optional media to simulate the image upload result.
    ///
    var media: Media?

    init(media: Media?, sessionManager: SessionManager) {
        self.media = media
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let mediaAction = action as? MediaAction {
            onMediaAction(action: mediaAction)
        } else {
            super.dispatch(action)
        }
    }

    private func onMediaAction(action: MediaAction) {
        switch action {
        case .uploadMedia(_, _, _, let onCompletion):
            guard let media = media else {
                onCompletion(.failure(MediaActionError.unknown))
                return
            }
            onCompletion(.success(media))
        case .retrieveMediaLibrary(_, _, _, let onCompletion):
            guard let media = media else {
                onCompletion(.failure(MediaActionError.unknown))
                return
            }
            onCompletion(.success([media]))
        }
    }
}
