import UIKit

final class StoreCreationProgressViewModel: ObservableObject {
    /// Conforms to `Double` to use a value for
    /// `ProgressView` in `StoreCreationProgressView`
    ///
    enum Progress: Double, CaseIterable {
        case creatingStore = 0.0
        case extendingStoresCapabilities = 1.0
        case turningOnTheLights = 2.0
        case openingTheDoors = 3.0
        case finished = 4.0
    }

    @Published private var progress: Progress

    let totalProgressAmount = StoreCreationProgressViewModel.Progress.finished.rawValue

    @Published private(set) var progressValue: Double = StoreCreationProgressViewModel.Progress.creatingStore.rawValue

    var title: String {
        progress.title
    }

    var subtitle: String {
        progress.subtitle
    }

    var image: UIImage {
        progress.image
    }

    private var incrementProgressValueTimer: Timer?
    private let estimatedTimePerProgress: Double
    private let progressViewAnimationTimerInterval: TimeInterval

    /// - Parameters:
    ///   - initialProgress: The initial value of the progress for SwiftUI previews.
    ///   - estimatedTimePerProgress:
    ///     Approx interval at which progress will be incremented to next case.
    ///     This value is used to animate the progress view until next increment happens.
    ///
    ///   - progressViewAnimationTimerInterval: Animation timer interval DI for unit test purposes.
    ///
    init(initialProgress: Progress = .creatingStore,
         estimatedTimePerProgress: TimeInterval,
         progressViewAnimationTimerInterval: TimeInterval = 0.1) {
        self.progress = initialProgress
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
        case .extendingStoresCapabilities:
            return Localization.Title.step2
        case .turningOnTheLights:
            return Localization.Title.step3
        case .openingTheDoors, .finished:
            return Localization.Title.step4
        }
    }

    var subtitle: String {
        switch self {
        case .creatingStore:
            return Localization.Subtitle.step1
        case .extendingStoresCapabilities:
            return Localization.Subtitle.step2
        case .turningOnTheLights:
            return Localization.Subtitle.step3
        case .openingTheDoors, .finished:
            return Localization.Subtitle.step4
        }
    }

    var image: UIImage {
        switch self {
        case .creatingStore:
            return .storeCreationProgress1
        case .extendingStoresCapabilities:
            return .storeCreationProgress2
        case .turningOnTheLights:
            return .storeCreationProgress3
        case .openingTheDoors, .finished:
            return .storeCreationProgress4
        }
    }
}

private extension StoreCreationProgressViewModel.Progress {
    enum Localization {
        enum Title {
            static let step1 = NSLocalizedString("Almost there! Your store is taking shape",
                                                 comment: "Title text in the store creation loading screen")

            static let step2 = NSLocalizedString("Extending store's capabilities",
                                                 comment: "Title text in the store creation loading screen")


            static let step3 = NSLocalizedString("Turning on the lights",
                                                 comment: "Title text in the store creation loading screen")

            static let step4 = NSLocalizedString("Opening the doors",
                                                 comment: "Title text in the store creation loading screen")
        }

        enum Subtitle {
            static let step1 = NSLocalizedString(
                "You will be notified once the store is ready!\nSit back, relax, and let us work our magic while sharing helpful tips. 🔮",
                comment: "Subtitle text in the store creation loading screen")

            static let step2 = NSLocalizedString(
                "**#Track sales and popular products:**\n" +
                "Stay on top of real-time sales and popular products to boost your store's profitability.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step3 = NSLocalizedString(
                "**#Manage and create orders:**\n" +
                "Search, update, or create new orders instantly. Simplify your order process.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")

            static let step4 = NSLocalizedString(
                "**#Take payments in person:**\n" +
                "Enhance sales with in-person payments. Secure card transactions with our or compatible readers.",
                comment: "Subtitle text in the store creation loading screen. The text in ** marks is bolded.")
        }
    }
}
