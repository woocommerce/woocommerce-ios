import Combine
import Foundation

/// View model for the second step of `StoreCreationSellingStatusQuestionView`, an optional profiler question about store selling status
/// in the store creation flow.
/// When the user previously indicates that they're already selling online, this view model provides data for the followup question on the platforms they're
/// already selling on.
@MainActor
final class StoreCreationSellingPlatformsQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    /// Other online platforms that the user might be selling. Source of truth:
    /// https://github.com/Automattic/woocommerce.com/blob/trunk/themes/woo/start/config/options.json
    enum Platform: String, CaseIterable {
        case adobe = "adobe-commerce"
        case amazon
        case bigCartel = "big-cartel"
        case bigCommerce = "big-commerce"
        case eBay = "ebay"
        case ecwid
        case etsy
        case facebookMarketplace = "facebook-marketplace"
        case googleShopping = "google-shopping"
        case magento
        case pinterest
        case shopify
        case square
        case squarespace
        case walmart
        case wish
        case wix
        case wordPress
    }

    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    let platforms: [Platform] = Platform.allCases

    @Published private(set) var selectedPlatforms: Set<Platform> = []

    private let onContinue: (StoreCreationSellingStatusAnswer?) -> Void

    init(storeName: String,
         onContinue: @escaping (StoreCreationSellingStatusAnswer?) -> Void) {
        self.topHeader = storeName
        self.onContinue = onContinue
    }
}

extension StoreCreationSellingPlatformsQuestionViewModel: OptionalStoreCreationProfilerQuestionViewModel {
    func continueButtonTapped() async {
        // TODO: submission API.
        onContinue(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: selectedPlatforms))
    }

    func skipButtonTapped() {
        onContinue(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: []))
    }
}

extension StoreCreationSellingPlatformsQuestionViewModel {
    /// Called when a platform is selected.
    func selectPlatform(_ platform: Platform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
}

extension StoreCreationSellingPlatformsQuestionViewModel.Platform {
    var description: String {
        switch self {
        case .adobe:
            return NSLocalizedString(
                "Adobe Commerce",
                comment: "Option in the store creation selling platforms question."
            )
        case .amazon:
            return NSLocalizedString(
                "Amazon",
                comment: "Option in the store creation selling platforms question."
            )
        case .bigCartel:
            return NSLocalizedString(
                "Big Cartel",
                comment: "Option in the store creation selling platforms question."
            )
        case .bigCommerce:
            return NSLocalizedString(
                "Big Commerce",
                comment: "Option in the store creation selling platforms question."
            )
        case .eBay:
            return NSLocalizedString(
                "Ebay",
                comment: "Option in the store creation selling platforms question."
            )
        case .ecwid:
            return NSLocalizedString(
                "Ecwid",
                comment: "Option in the store creation selling platforms question."
            )
        case .etsy:
            return NSLocalizedString(
                "Etsy",
                comment: "Option in the store creation selling platforms question."
            )
        case .facebookMarketplace:
            return NSLocalizedString(
                "Facebook Marketplace",
                comment: "Option in the store creation selling platforms question."
            )
        case .googleShopping:
            return NSLocalizedString(
                "Google Shopping",
                comment: "Option in the store creation selling platforms question."
            )
        case .magento:
            return NSLocalizedString(
                "Magento",
                comment: "Option in the store creation selling platforms question."
            )
        case .pinterest:
            return NSLocalizedString(
                "Pinterest",
                comment: "Option in the store creation selling platforms question."
            )
        case .shopify:
            return NSLocalizedString(
                "Shopify",
                comment: "Option in the store creation selling platforms question."
            )
        case .square:
            return NSLocalizedString(
                "Square",
                comment: "Option in the store creation selling platforms question."
            )
        case .squarespace:
            return NSLocalizedString(
                "Squarespace",
                comment: "Option in the store creation selling platforms question."
            )
        case .walmart:
            return NSLocalizedString(
                "Walmart",
                comment: "Option in the store creation selling platforms question."
            )
        case .wish:
            return NSLocalizedString(
                "Wish",
                comment: "Option in the store creation selling platforms question."
            )
        case .wix:
            return NSLocalizedString(
                "Wix",
                comment: "Option in the store creation selling platforms question."
            )
        case .wordPress:
            return NSLocalizedString(
                "WordPress",
                comment: "Option in the store creation selling platforms question."
            )
        }
    }
}

private extension StoreCreationSellingPlatformsQuestionViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "In which platform are you currently selling?",
            comment: "Title of the store creation profiler question about the store selling platforms."
        )
        static let subtitle = NSLocalizedString(
            "You can choose multiple ones.",
            comment: "Subtitle of the store creation profiler question about the store selling platforms."
        )
    }
}
