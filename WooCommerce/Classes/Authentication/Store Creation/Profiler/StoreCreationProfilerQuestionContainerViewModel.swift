import Foundation
import Yosemite

enum StoreCreationProfilerQuestion {
    case sellingStatus
    case category
    case country
    case challenges
    case features
}

/// View model for `StoreCreationProfilerQuestionContainer`.
final class StoreCreationProfilerQuestionContainerViewModel: ObservableObject {

    let storeName: String
    private let analytics: Analytics
    private let completionHandler: (SiteProfilerData?) -> Void

    private var storeCategory: StoreCreationCategoryAnswer?
    private var sellingStatus: StoreCreationSellingStatusAnswer?
    private var storeCountry: SiteAddress.CountryCode = .US
    private var challenges: [StoreCreationChallengesAnswer] = []
    private var features: [StoreCreationFeaturesAnswer] = []

    @Published private(set) var currentQuestion: StoreCreationProfilerQuestion = .sellingStatus

    init(storeName: String,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (SiteProfilerData?) -> Void) {
        self.storeName = storeName
        self.analytics = analytics
        self.completionHandler = onCompletion
    }

    func saveSellingStatus(_ answer: StoreCreationSellingStatusAnswer?) {
        if answer == nil {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
        }
        sellingStatus = answer
        currentQuestion = .category
    }

    func saveCategory(_ answer: StoreCreationCategoryAnswer?) {
        if answer == nil {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
        }
        storeCategory = answer
        currentQuestion = .country
    }

    func saveCountry(_ answer: SiteAddress.CountryCode) {
        storeCountry = answer
        currentQuestion = .challenges
    }

    func saveChallenges(_ answer: [StoreCreationChallengesAnswer]) {
        if answer.isEmpty {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerChallengesQuestion))
        }
        challenges = answer
        currentQuestion = .features
    }

    func saveFeatures(_ answer: [StoreCreationFeaturesAnswer]) {
        if answer.isEmpty {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerFeaturesQuestion))
        }
        features = answer
        handleCompletion()
    }

    func dismissProfiler() {
        // TODO: show confirm alert if needed
        completionHandler(nil)
    }

    private func handleCompletion() {
        // TODO: update profiler data with challenges and features
        let profilerData: SiteProfilerData = {
            let sellingPlatforms = sellingStatus?.sellingPlatforms?.map { $0.rawValue }.sorted().joined(separator: ",")
            return .init(name: storeName,
                         category: storeCategory?.value,
                         sellingStatus: sellingStatus?.sellingStatus,
                         sellingPlatforms: sellingPlatforms,
                         countryCode: storeCountry.rawValue)
        }()
        completionHandler(profilerData)
    }
}
