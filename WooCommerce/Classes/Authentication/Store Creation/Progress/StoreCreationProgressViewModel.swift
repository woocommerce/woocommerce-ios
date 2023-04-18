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

    var subtitle: AttributedString {
        var prefix = AttributedString(Localization.funWooFact)
        prefix.font = .headline
        prefix.foregroundColor = .init(.text)

        var attributedText = AttributedString(progress.subtitle)
        attributedText.font = .body
        attributedText.foregroundColor = .init(.text)

        return prefix + " " + attributedText
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
        case .applyingFinishingTouches:
            return Localization.Title.finishingTouches
        case .turningOnTheLights:
            return Localization.Title.turningOnLights
        case .openingTheDoors, .finished:
            return Localization.Title.openingDoors
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
        case .applyingFinishingTouches:
            return Localization.Subtitle.meetups
        case .turningOnTheLights:
            return Localization.Subtitle.wooTeam
        case .openingTheDoors, .finished:
            return Localization.Subtitle.favColor
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

            static let turningOnLights = NSLocalizedString("Turning on the lights",
                                                            comment: "Title text in the store creation loading screen")

            static let openingDoors = NSLocalizedString("Opening the doors",
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

            static let wooTeam = NSLocalizedString(
                "The Woo team is made up of over 350 talented individuals, distributed across 30+ countries.",
                comment: "Subtitle text in the store creation loading screen")

            static let favColor = NSLocalizedString(
                "Our favorite color is purple.",
                comment: "Subtitle text in the store creation loading screen")
        }
    }
}
