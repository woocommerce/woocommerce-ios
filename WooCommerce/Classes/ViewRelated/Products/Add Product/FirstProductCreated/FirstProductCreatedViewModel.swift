import Yosemite

final class FirstProductCreatedViewModel: ObservableObject {
    @Published var isSharePopoverPresented = false

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
         eligibilityChecker: ShareProductAIEligibilityChecker? = nil,
         analytics: Analytics = ServiceLocator.analytics) {
        self.productURL = productURL
        self.productName = productName
        self.showShareProductButton = showShareProductButton

        let eligibilityChecker = eligibilityChecker ?? DefaultShareProductAIEligibilityChecker(site: ServiceLocator.stores.sessionManager.defaultSite)
        self.canGenerateShareProductMessageUsingAI = eligibilityChecker.canGenerateShareProductMessageUsingAI

        self.analytics = analytics
        self.isPad = isPad
        self.shareSheet = ShareSheet(activityItems: [productName, productURL])
    }

    func didTapShareProduct() {
        analytics.track(.firstCreatedProductShareTapped)

        if !canGenerateShareProductMessageUsingAI && isPad {
            isSharePopoverPresented = true
        } else {
            launchAISharingFlow?()
        }
    }
}
