import Foundation
import SwiftUI

/// Banner to inform the users how custom fields are saved.
///
struct CustomFieldsListTopBanner: UIViewRepresentable {
    typealias Callback = () -> ()

    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Closure to be invoked when the "Dismiss" button is pressed.
    ///
    private var onDismiss: Callback? = nil

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.width = width
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func makeUIView(context: Context) -> UIView {
        let expandButton = TopBannerViewModel.TopButtonType.chevron {
            context.coordinator.bannerWrapper.invalidateIntrinsicContentSize() // Forces the view to recalculate it's size as it collapses/expands
        }
        let dismissButton = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            onDismiss?()
        }

        let viewModel = TopBannerViewModel(title: Localization.title,
                                                               infoText: Localization.description,
                                                               icon: .speakerIcon.withRenderingMode(.alwaysTemplate),
                                                               iconTintColor: .primary,
                                                               isExpanded: !UIDevice.current.orientation.isLandscape, // Collapsed by default in landscape mode
                                                               topButton: expandButton,
                                                               actionButtons: [dismissButton])
        let mainBanner = TopBannerView(viewModel: viewModel)

        // Set the current super view width and the real view to be displayed inside the wrapper.
        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.setBanner(mainBanner)
        return context.coordinator.bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerWrapper.width = width
    }

    /// Returns a copy of the view with `onDismiss` handling.
    ///
    func onDismiss(_ handler: @escaping Callback) -> CustomFieldsListTopBanner {
        var copy = self
        copy.onDismiss = handler
        return copy
    }
}

// MARK: Coordinator
extension CustomFieldsListTopBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}

// MARK: Localization
private extension CustomFieldsListTopBanner {
    enum Localization {
        static let title = NSLocalizedString(
            "customFieldsListTopBanner.title",
            value: "View and edit custom fields",
            comment: "Title of the banner when there are unsaved custom fields")
        static let description = NSLocalizedString(
            "customFieldsListTopBanner.description",
            value: "When saving changes to custom fields, they will take effect immediately.",
            comment: "Content of the banner when there are unsaved custom fields")
        static let dismiss = NSLocalizedString(
            "customFieldsListTopBanner.dismiss",
            value: "Dismiss",
            comment: "Dismiss button title")
    }
}
