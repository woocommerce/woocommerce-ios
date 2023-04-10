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
        case finished = 4.0
    }

    @Published private var progress: Progress = .creatingStore

    let totalProgressAmount = StoreCreationProgressViewModel.Progress.finished.rawValue

    @Published private(set) var progressValue: Double = StoreCreationProgressViewModel.Progress.creatingStore.rawValue

    var title: String {
        progress.title
    }

    var subtitle: AttributedString {
        var prefix = AttributedString(Localization.funWooFact)
        prefix.font = .headline
        prefix.foregroundColor = .init(.text)

        var attributedText = AttributedString(progress.subtitle)
        attributedText.font = .body
        attributedText.foregroundColor = .init(.text)

        return prefix + " " + attributedText
    }

    private var animationTimer: Timer?
    private let expectNextIncrementToOccurAfter: Double
    private let progressViewAnimationTimerInterval: TimeInterval

    /// - Parameters:
    ///   - expectNextIncrementToOccurAfter:
    ///     Approx interval at which progress will be incremented to next case.
    ///     This value is used to animate the progress view until next increment happens.
    ///
    ///   - progressViewAnimationTimerInterval: Animation timer interval DI for unit test purposes.
    ///
    init(expectNextIncrementToOccurAfter: TimeInterval,
         progressViewAnimationTimerInterval: TimeInterval = 0.1) {
        self.expectNextIncrementToOccurAfter = expectNextIncrementToOccurAfter
        self.progressViewAnimationTimerInterval = progressViewAnimationTimerInterval
        $progress
            .map { $0.rawValue }
            .assign(to: &$progressValue)
    }

    // MARK: Public methods
    //
    func onAppear() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: progressViewAnimationTimerInterval, repeats: true) { [weak self] _ in
            self?.animateProgressView()
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
    func animateProgressView() {
        guard let next = progress.next(),
              progressValue < next.rawValue else {
            return
        }

        // Increment the progress value until next progress increment
        let gapBetweenProgress = next.rawValue - progress.rawValue
        let incrementProgressValueBy = (gapBetweenProgress / (expectNextIncrementToOccurAfter / progressViewAnimationTimerInterval))
        progressValue = min(progressValue + incrementProgressValueBy, next.rawValue)
    }

    enum Localization {
        static let funWooFact = NSLocalizedString("#FunWooFact:", comment: "Prefix for the subtitle text in the store creation loading screen")
    }
}

private extension StoreCreationProgressViewModel.Progress {
    var title: String {
        switch self {
        case .creatingStore:
            return Localization.Title.wooWeAreCreatingYourStore
        case .buildingFoundations:
            return Localization.Title.buildingTheFoundations
        case .organizingStockRoom:
            return Localization.Title.organizingTheStockRoom
        case .applyingFinishingTouches, .finished:
            return Localization.Title.finishingTouches
        }
    }

    var subtitle: String {
        switch self {
        case .creatingStore:
            return Localization.Subtitle.stores
        case .buildingFoundations:
            return Localization.Subtitle.founded
        case .organizingStockRoom:
            return Localization.Subtitle.catOrDog
        case .applyingFinishingTouches, .finished:
            return Localization.Subtitle.meetups
        }
    }
}

private extension StoreCreationProgressViewModel.Progress {
    enum Localization {
        enum Title {
            static let wooWeAreCreatingYourStore = NSLocalizedString("Woo! We are creating your store",
                                                                     comment: "Title text in the store creation loading screen")

            static let buildingTheFoundations = NSLocalizedString("Building the foundations",
                                                                  comment: "Title text in the store creation loading screen")

            static let organizingTheStockRoom = NSLocalizedString("Organizing the stock room",
                                                                  comment: "Title text in the store creation loading screen")

            static let finishingTouches = NSLocalizedString("Applying the finishing touches",
                                                            comment: "Title text in the store creation loading screen")
        }

        enum Subtitle {
            static let stores = NSLocalizedString(
                "Did you know that Woo powers more than 3.5 million stores worldwide? You’re in good company.",
                comment: "Subtitle text in the store creation loading screen")

            static let founded = NSLocalizedString(
                "Did you know that Woo was founded by two South Africans and a Norwegian? "
                + "Here are three alternative ways to say “store” in those countries – Winkel, ivenkile, and butikk.",
                comment: "Subtitle text in the store creation loading screen")

            static let catOrDog = NSLocalizedString(
                "Are you Team Cat or Team Dog? The Woo team is split 50/50!",
                comment: "Subtitle text in the store creation loading screen")

            static let meetups = NSLocalizedString(
                "There are more than 150 WooCommerce meetups held all over the world! A great way to meet fellow store owners.",
                comment: "Subtitle text in the store creation loading screen")
        }
    }
}
