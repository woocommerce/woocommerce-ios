import StoreDesignSystem
import SwiftUI
import UIKit

/// Products load error banner for the table header; a tap collapses or expands it.
@MainActor
final class StoreProductListErrorBannerView: UIView {
    private let title: String
    private let message: String
    private let onExpandedStateChange: () -> Void
    private let onTroubleshoot: () -> Void
    private let onContactSupport: () -> Void
    private(set) var isExpanded = true
    // Not `UIHostingConfiguration`: outside a cell it keeps reporting its first height.
    private var hostingController: UIHostingController<BannerContent>?

    init(error: Error,
         onExpandedStateChange: @escaping () -> Void,
         onTroubleshoot: @escaping () -> Void,
         onContactSupport: @escaping () -> Void) {
        let errorType = ErrorTopBannerFactory.ErrorType(error: error)
        title = errorType.title
        message = errorType.info
        self.onExpandedStateChange = onExpandedStateChange
        self.onTroubleshoot = onTroubleshoot
        self.onContactSupport = onContactSupport
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let hostingController = UIHostingController(rootView: makeContent())
        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.safeAreaRegions = []
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.hostingController = hostingController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleExpanded() {
        isExpanded.toggle()
        hostingController?.rootView = makeContent()
        // Settles the new SwiftUI size now, so the caller's re-measure sees it.
        hostingController?.view.invalidateIntrinsicContentSize()
        hostingController?.view.layoutIfNeeded()
        onExpandedStateChange()
    }

    private func makeContent() -> BannerContent {
        BannerContent(title: title,
                      message: message,
                      isExpanded: isExpanded,
                      onToggle: { [weak self] in self?.toggleExpanded() },
                      onTroubleshoot: onTroubleshoot,
                      onContactSupport: onContactSupport)
    }
}

private struct BannerContent: View {
    let title: String
    let message: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTroubleshoot: () -> Void
    let onContactSupport: () -> Void

    var body: some View {
        StoreOrderListErrorBanner(title: title,
                                  message: message,
                                  isExpanded: isExpanded,
                                  onToggle: onToggle,
                                  onTroubleshoot: onTroubleshoot,
                                  onContactSupport: onContactSupport)
            .padding(StorePadding.p5)
    }
}
