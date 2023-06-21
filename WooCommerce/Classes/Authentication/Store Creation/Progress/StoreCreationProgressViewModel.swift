import UIKit

final class StoreCreationProgressViewModel: ObservableObject {
    /// Conforms to `Double` to use a value for
    /// `ProgressView` in `StoreCreationProgressView`
    ///
    enum Progress: Double, CaseIterable {
        case creatingStore = 0.0
        case buildingFoundations = 1.0
        case organizingStockRoom = 2.0
        case applyingFinishingTouches = 3.0
        case turningOnTheLights = 4.0
        case openingTheDoors = 5.0
        case finished = 6.0
    }

    @Published private var progress: Progress = .creatingStore

    let totalProgressAmount = StoreCreationProgressViewModel.Progress.finished.rawValue

    @Published private(set) var progressValue: Double = StoreCreationProgressViewModel.Progress.creatingStore.rawValue

    var title: String {
        progress.title
    }

    var subtitle: String {
        progress.subtitle
    }

    private var incrementProgressValueTimer: Timer?
    private let estimatedTimePerProgress: Double
    private let progressViewAnimationTimerInterval: TimeInterval

    /// - Parameters:
    ///   - estimatedTimePerProgress:
    ///     Approx interval at which progress will be incremented to next case.
    ///     This value is used to animate the progress view until next increment happens.
    ///
    ///   - progressViewAnimationTimerInterval: Animation timer interval DI for unit test purposes.
    ///
    init(estimatedTimePerProgress: TimeInterval,
         progressViewAnimationTimerInterval: TimeInterval = 0.1) {
        self.estimatedTimePerProgress = estimatedTimePerProgress
        self.progressViewAnimationTimerInterval = progressViewAnimationTimerInterval
        $progress
            .map { $0.rawValue }
            .assign(to: &$progressValue)
    }

    // MARK: Public methods
    //
    func onAppear() {
        incrementProgressValueTimer = Timer.scheduledTimer(withTimeInterval: progressViewAnimationTimerInterval, repeats: true) { [weak self] _ in
            self?.incrementProgressValue()
        }
    }

    func incrementProgress() {
        guard let next = progress.next() else {
            return
        }
        progress = next
    }

    func markAsComplete() {
        progress = .finished
    }
}

private extension StoreCreationProgressViewModel {
    func incrementProgressValue() {
        guard let next = progress.next(),
              progressValue < next.rawValue else {
            return
        }

        // Increment the progress value until next progress increment
        let gapBetweenProgress = next.rawValue - progress.rawValue
        let incrementProgressValueBy = (gapBetweenProgress / (estimatedTimePerProgress / progressViewAnimationTimerInterval))
        progressValue = min(progressValue + incrementProgressValueBy, next.rawValue)
    }
}

private extension StoreCreationProgressViewModel.Progress {
    var title: String {
        switch self {
        case .creatingStore:
            return Localization.Title.step1
        case .buildingFoundations:
            return Localization.Title.step2
        case .organizingStockRoom:
            return Localization.Title.step3
        case .applyingFinishingTouches:
            return Localization.Title.step4
        case .turningOnTheLights:
            return Localization.Title.step5
        case .openingTheDoors, .finished:
            return Localization.Title.step6
        }
    }

    var subtitle: String {
        switch self {
        case .creatingStore:
            return Localization.Subtitle.step1
        case .buildingFoundations:
            return Localization.Subtitle.step2
        case .organizingStockRoom:
            return Localization.Subtitle.step3
        case .applyingFinishingTouches:
            return Localization.Subtitle.step4
        case .turningOnTheLights:
            return Localization.Subtitle.step5
        case .openingTheDoors, .finished:
            return Localization.Subtitle.step6
        }
    }
}

private extension StoreCreationProgressViewModel.Progress {
    enum Localization {
        enum Title {
            static let step1 = NSLocalizedString("Creating Your Store! It'll be just a few minutes",
                                                 comment: "Title text in the store creation loading screen")

            static let step2 = NSLocalizedString("Building the foundations",
                                                 comment: "Title text in the store creation loading screen")

            static let step3 = NSLocalizedString("Organizing the stock room",
                                                 comment: "Title text in the store creation loading screen")

            static let step4 = NSLocalizedString("Applying the finishing touches",
                                                 comment: "Title text in the store creation loading screen")

            static let step5 = NSLocalizedString("Turning on the lights",
                                                 comment: "Title text in the store creation loading screen")

            static let step6 = NSLocalizedString("Opening the doors",
                                                 comment: "Title text in the store creation loading screen")
        }

        enum Subtitle {
            static let step1 = NSLocalizedString(
                "You will be notified once the store is ready! Sit back, relax, and let us work our magic while sharing helpful tips. 🔮",
                comment: "Subtitle text in the store creation loading screen")

            static let step2 = NSLocalizedString(
                "**#Track sales and popular products:** Stay updated on your store's real-time performance. Identify your top-selling products and make informed decisions for maximum profitability.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step3 = NSLocalizedString(
                "**#Manage and create orders:** Handle orders with ease. Scroll, search, and change order status. Create new orders on the fly for in-store or phone purchases. Simplify your order management process.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step4 = NSLocalizedString(
                "**#Take payments in person:** Expand your sales opportunities by accepting payments in person. Use the app to securely process credit card transactions or even connect with compatible card readers for convenient in-person payments.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step5 = NSLocalizedString(
                "**#Add and edit products with a touch:** Add new products, update details, upload images, and manage variations, all from the app. Keep your inventory up to date effortlessly.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step6 = NSLocalizedString(
                "**#Get notified of every sale:** Never miss a beat with instant sale notifications. Receive alerts for each new sale, allowing you to celebrate your success and stay on top of your store's activity.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")
        }
    }
}
