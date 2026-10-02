import SwiftUI

/// Owns cleanup for one POS presentation, independently of screens that cover it.
@MainActor
public final class POSPresentationSession {
    private(set) var isEnded = false
    var onEnd: (() -> Void)?

    nonisolated public init() {}

    func end() {
        guard !isEnded else { return }
        isEnded = true
        let cleanup = onEnd
        onEnd = nil
        cleanup?()
    }
}

/// A full-screen payment presentation can hide POS without ending its session.
public final class POSHostingController<Content: View>: UIHostingController<Content> {
    private let session: POSPresentationSession

    public init(rootView: Content, session: POSPresentationSession) {
        self.session = session
        super.init(rootView: rootView)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // The presenting controller remains attached while a payment screen covers POS.
        if isBeingDismissed || presentingViewController == nil {
            session.end()
        }
    }
}
