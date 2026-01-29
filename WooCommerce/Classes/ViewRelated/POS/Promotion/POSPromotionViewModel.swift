import Foundation
import Observation
import protocol WooFoundation.Analytics
import struct WooFoundation.WooCommerceComUTMProvider
import protocol Yosemite.StoresManager

/// View model for the POS Promotion modal flow.
///
@MainActor
@Observable
final class POSPromotionViewModel {
    /// The currently selected step index (0-indexed).
    var selectedStep = 0 {
        didSet {
            guard selectedStep != oldValue else { return }
            trackSlideViewed()
        }
    }

    /// The step descriptions to display in the modal.
    private(set) var stepDescriptions: [String]

    /// When set to true, the modal should dismiss.
    var dismiss: Bool = false

    /// The total number of steps.
    var totalSteps: Int { stepDescriptions.count }

    /// The image name for the modal (same across all steps).
    let imageName: String

    /// The title for the modal (same across all steps).
    let title: String

    /// Whether the user is currently on the final step.
    var isOnFinalStep: Bool {
        selectedStep == stepDescriptions.count - 1
    }

    /// The title for the primary action button.
    var primaryButtonTitle: String {
        isOnFinalStep ? Localization.explorePOS : Localization.next
    }

    private let analytics: Analytics
    private let stores: StoresManager
    private let onDismiss: () -> Void
    private let onShowWebView: (WebViewSheetViewModel) -> Void

    /// Tracks whether the user tapped "Explore" to avoid double-tracking dismissal.
    private var didTapExplore = false

    init(stepDescriptions: [String]? = nil,
         imageName: String = "pos-promotion-header",
         title: String = Localization.title,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         onDismiss: @escaping () -> Void = {},
         onShowWebView: @escaping (WebViewSheetViewModel) -> Void = { _ in }) {
        self.stepDescriptions = stepDescriptions ?? POSPromotionStepsFactory.stepDescriptions()
        self.imageName = imageName
        self.title = title
        self.analytics = analytics
        self.stores = stores
        self.onDismiss = onDismiss
        self.onShowWebView = onShowWebView
    }

    // MARK: - Actions

    /// Called when the primary action button is tapped.
    func primaryActionTapped() {
        if isOnFinalStep {
            didTapExplore = true
            analytics.track(.posPromoModalExploreClicked)
            showWebView()
            dismiss = true
        } else {
            selectedStep += 1
        }
    }

    private func showWebView() {
        let siteID = stores.sessionManager.defaultStoreID
        let utmProvider = WooCommerceComUTMProvider(
            campaign: "pos_promotion_modal",
            source: "my_store",
            content: "pos_promotion_cta",
            siteID: siteID
        )
        guard let url = utmProvider.urlWithUtmParams(string: WooConstants.URLs.posLearnMore.rawValue) else {
            return
        }
        let webViewModel = WebViewSheetViewModel(
            url: url,
            navigationTitle: Localization.explorePOS,
            authenticated: true
        )
        onShowWebView(webViewModel)
    }

    /// Called when the close button is tapped.
    func closeButtonTapped() {
        dismiss = true
    }

    // MARK: - View Lifecycle

    /// Called when the view appears.
    func onAppear() {
        analytics.track(.posPromoModalViewed)
        trackSlideViewed()
    }

    /// Called when the view disappears.
    func onDisappear() {
        if !didTapExplore {
            analytics.track(.posPromoModalDismissed)
        }
        onDismiss()
    }

    // MARK: - Analytics

    private func trackSlideViewed() {
        analytics.track(.posPromoModalSlideViewed, withProperties: ["slide_index": selectedStep])
    }
}

// MARK: - Localization

private enum Localization {
    static let title = NSLocalizedString(
        "posPromotion.title",
        value: "Point of Sale from WooCommerce",
        comment: "This text appears as the title at the top of a promotional modal that introduces users to WooCommerce's Point of Sale feature. The title is displayed across all steps of the promotion flow and helps users understand what product is being promoted."
    )

    static let next = NSLocalizedString(
        "posPromotion.button.next",
        value: "Next",
        comment: "Button label that advances users to the next step in a multi-step Point of Sale (POS) promotion modal that introduces the WooCommerce POS feature."
    )

    static let explorePOS = NSLocalizedString(
        "posPromotion.button.explorePOS",
        value: "Explore WooCommerce POS",
        comment: "This text appears as a button label in the final step of a Point of Sale (POS) promotion modal, which when tapped opens a Safari web page with more information about WooCommerce POS features."
    )
}
