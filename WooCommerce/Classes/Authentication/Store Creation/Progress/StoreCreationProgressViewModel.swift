import UIKit

final class StoreCreationProgressViewModel: ObservableObject {
    enum Progress: Float, CaseIterable {
        case creatingStore = 0.0
        case buildingFoundations = 1.0
        case organizingStockRoom = 2.0
        case applyingFinishingTouches = 3.0
        case finished = 4.0
    }

    @Published private(set) var progress: Progress = .creatingStore {
        didSet {
            progressValue = progress.rawValue
        }
    }

    let totalProgressAmount = StoreCreationProgressViewModel.Progress.finished.rawValue

    @Published private(set) var progressValue: Float = StoreCreationProgressViewModel.Progress.creatingStore.rawValue

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
    private let timeInterval: TimeInterval
    private let incrementProgressValueBy: Float

    init(timeInterval: TimeInterval = 0.1,
         incrementProgressValueBy: Float = 0.01) {
        self.timeInterval = timeInterval
        self.incrementProgressValueBy = incrementProgressValueBy
    }

    // MARK: Public methods
    //
    func onAppear() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            self?.animateProgressView()
        }
    }

    func incrementProgress() {
        guard let next = progress.next() else {
            return
        }
        self.progress = next
    }

    func markAsComplete() {
        self.progress = .finished
    }
}

private extension StoreCreationProgressViewModel {
    func animateProgressView() {
        guard let next = progress.next(),
              progressValue < next.rawValue else {
            return
        }
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
    func next() -> Self? {
        let all = Self.allCases
        guard let idx = all.firstIndex(of: self) else {
            return nil
        }

        let next = all.index(after: idx)

        if next == all.endIndex {
            return nil
        }

        return all[next]
    }

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
                "There are more than 150 WooCommerce meetups held all over the world! A great way to meet fellow store owners.",
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
