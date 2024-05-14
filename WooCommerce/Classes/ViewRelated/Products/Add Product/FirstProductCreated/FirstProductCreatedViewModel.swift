import Yosemite
import protocol WooFoundation.Analytics

final class FirstProductCreatedViewModel: ObservableObject {
    @Published var isSharePopoverPresented = false
    @Published var isShareSheetPresented = false

    let productURL: URL
    let productName: String
    let showShareProductButton: Bool
    let shareSheet: ShareSheet

    var launchAISharingFlow: (() -> Void)?

    private let canGenerateShareProductMessageUsingAI: Bool
    private let isPad: Bool
    private let analytics: Analytics

    init(productURL: URL,
         productName: String,
         showShareProductButton: Bool,
         isPad: Bool = UIDevice.isPad(),
         eligibilityChecker: ShareProductAIEligibilityChecker = DefaultShareProductAIEligibilityChecker(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.productURL = productURL
        self.productName = productName
        self.showShareProductButton = showShareProductButton

        let eligibilityChecker = eligibilityChecker
        self.canGenerateShareProductMessageUsingAI = eligibilityChecker.canGenerateShareProductMessageUsingAI

        self.analytics = analytics
        self.isPad = isPad
        self.shareSheet = ShareSheet(activityItems: [productName, productURL])
    }

    func didTapShareProduct() {
        analytics.track(.firstCreatedProductShareTapped)

        guard !canGenerateShareProductMessageUsingAI else {
            launchAISharingFlow?()
            return
        }

        if isPad {
            isSharePopoverPresented = true
        } else {
            isShareSheetPresented = true
        }
    }
}
