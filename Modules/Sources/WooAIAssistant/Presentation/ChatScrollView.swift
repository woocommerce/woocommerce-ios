import SwiftUI
import UIKit

struct ChatScrollView<Content: View>: UIViewRepresentable {

    @ObservedObject var controller: ChatScrollController
    let content: Content

    init(controller: ChatScrollController, @ViewBuilder content: () -> Content) {
        self.controller = controller
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.showsVerticalScrollIndicator = true

        let host = UIHostingController(rootView: AnyView(content))
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        host.configureForChatHost()
        scrollView.addSubview(host.view)

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: frameGuide.widthAnchor)
        ])

        context.coordinator.host = host
        context.coordinator.scrollView = scrollView
        controller.scrollToBottomHandler = { [weak coordinator = context.coordinator] animated in
            coordinator?.scrollToBottom(animated: animated)
        }
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.host?.rootView = AnyView(content)
    }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {

        let controller: ChatScrollController
        var host: UIHostingController<AnyView>?
        weak var scrollView: UIScrollView? {
            didSet { observeContentSize() }
        }

        private var contentSizeObserver: NSKeyValueObservation?
        private var pendingBottomPin: Bool = false

        init(controller: ChatScrollController) {
            self.controller = controller
        }

        private func observeContentSize() {
            contentSizeObserver = scrollView?.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
                Task { @MainActor [weak self] in self?.handleContentSizeChange(sv) }
            }
        }

        private func handleContentSizeChange(_ scrollView: UIScrollView) {
            guard pendingBottomPin else { return }
            let target = max(0, scrollView.contentSize.height
                + scrollView.adjustedContentInset.bottom
                - scrollView.bounds.height)
            guard target > scrollView.contentOffset.y else { return }
            scrollView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            controller.isNearBottom = true
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let distance = scrollView.contentSize.height
                + scrollView.adjustedContentInset.bottom
                - scrollView.contentOffset.y
                - scrollView.bounds.height
            let near = distance < 80
            if controller.isNearBottom != near {
                controller.isNearBottom = near
            }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            pendingBottomPin = false
        }

        func scrollToBottom(animated: Bool) {
            guard let sv = scrollView else { return }
            pendingBottomPin = true
            sv.layoutIfNeeded()
            let target = max(0, sv.contentSize.height
                + sv.adjustedContentInset.bottom
                - sv.bounds.height)
            sv.setContentOffset(CGPoint(x: 0, y: target), animated: animated)
            controller.isNearBottom = true
        }
    }
}

private extension UIHostingController {
    // Outer UIScrollView already adjusts contentInset for the keyboard / safe-area,
    // so the hosted SwiftUI content should not double-inset.
    func configureForChatHost() {
        view.insetsLayoutMarginsFromSafeArea = false
        sizingOptions = [.intrinsicContentSize]
    }
}
