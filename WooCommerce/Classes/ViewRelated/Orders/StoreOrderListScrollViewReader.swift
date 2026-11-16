import SwiftUI
import UIKit

/// Resolves the native scroll view backing a SwiftUI `List` without becoming its delegate.
struct StoreOrderListScrollViewReader: UIViewRepresentable {
    let onResolve: (UIScrollView) -> Void

    func makeUIView(context: Context) -> ObserverView {
        ObserverView(onResolve: onResolve)
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        uiView.onResolve = onResolve
        uiView.resolveScrollView()
    }
}

final class ObserverView: UIView {
    var onResolve: (UIScrollView) -> Void
    private weak var resolvedScrollView: UIScrollView?

    init(onResolve: @escaping (UIScrollView) -> Void) {
        self.onResolve = onResolve
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resolveScrollView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resolveScrollView()
    }

    func resolveScrollView() {
        var candidate = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView {
                guard scrollView !== resolvedScrollView else { return }
                resolvedScrollView = scrollView
                onResolve(scrollView)
                return
            }
            candidate = view.superview
        }
    }
}
