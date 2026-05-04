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
        host.disableSafeArea()
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
        weak var scrollView: UIScrollView?

        init(controller: ChatScrollController) {
            self.controller = controller
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let distance = scrollView.contentSize.height
                - scrollView.contentOffset.y
                - scrollView.bounds.height
            let near = distance < 80
            if controller.isNearBottom != near {
                controller.isNearBottom = near
            }
        }

        func scrollToBottom(animated: Bool) {
            guard let sv = scrollView else { return }
            let target = max(0, sv.contentSize.height - sv.bounds.height)
            sv.setContentOffset(CGPoint(x: 0, y: target), animated: animated)
            controller.isNearBottom = true
        }
    }
}

private extension UIHostingController {
    func disableSafeArea() {
        // Allow the SwiftUI content to extend behind the keyboard / safe-area
        // since the outer UIScrollView already adjusts contentInset.
        view.insetsLayoutMarginsFromSafeArea = false
        if #available(iOS 16.0, *) {
            sizingOptions = [.intrinsicContentSize]
        }
    }
}
