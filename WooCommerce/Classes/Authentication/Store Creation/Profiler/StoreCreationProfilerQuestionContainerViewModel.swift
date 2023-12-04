import Foundation
import Yosemite
import WooFoundation

enum StoreCreationProfilerQuestion: Int, CaseIterable {
    case sellingStatus = 1
    case category
    case country
    case challenges
    case features

    /// Progress to display for the profiler flow
    var progress: Double {
        let incrementBy = 1.0 / Double(Self.allCases.count)
        return Double(self.rawValue) * incrementBy
    }

    var previousQuestion: StoreCreationProfilerQuestion? {
        .init(rawValue: self.rawValue - 1)
    }
}

/// View model for `StoreCreationProfilerQuestionContainer`.
final class StoreCreationProfilerQuestionContainerViewModel: ObservableObject {

    let storeName: String
    private let analytics: Analytics
    private let completionHandler: () -> Void

    private var storeCategory: StoreCreationCategoryAnswer? {
        didSet {
            storeAnswers()
        }
    }
    private var sellingStatus: StoreCreationSellingStatusAnswer? {
        didSet {
            storeAnswers()
        }
    }
    private var storeCountry: CountryCode? {
        didSet {
            storeAnswers()
        }
    }
    private var challenges: [StoreCreationChallengesAnswer] = []
    private var features: [StoreCreationFeaturesAnswer] = []
    private let uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol

    private var answers: StoreProfilerAnswers {
        let sellingPlatforms = sellingStatus?.sellingPlatforms?.map { $0.rawValue }.sorted().joined(separator: ",")
        let sellingStatus = sellingStatus?.sellingStatus
        return StoreProfilerAnswers(sellingStatus: sellingStatus,
                                    sellingPlatforms: sellingPlatforms,
                                    category: storeCategory?.value,
                                    countryCode: storeCountry?.rawValue)
    }

    @Published private(set) var currentQuestion: StoreCreationProfilerQuestion = .sellingStatus

    init(storeName: String,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping () -> Void,
         uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol) {
        self.storeName = storeName
        self.analytics = analytics
        self.completionHandler = onCompletion
        self.uploadAnswersUseCase = uploadAnswersUseCase
    }

    func onAppear() {
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerSellingStatusQuestion))
    }

    func saveSellingStatus(_ answer: StoreCreationSellingStatusAnswer?) {
        if answer == nil {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingStatusQuestion))
        } else if let answer,
                    answer.sellingStatus == .alreadySellingOnline,
                  answer.sellingPlatforms == nil || answer.sellingPlatforms?.isEmpty == true {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingPlatformsQuestion))
        }

        sellingStatus = answer
        currentQuestion = .category
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCategoryQuestion))
    }

    func saveCategory(_ answer: StoreCreationCategoryAnswer?) {
        if answer == nil {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
        }
        storeCategory = answer
        currentQuestion = .country
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCountryQuestion))
    }

    func saveCountry(_ answer: CountryCode) {
        storeCountry = answer
        currentQuestion = .challenges
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerChallengesQuestion))
    }

    func saveChallenges(_ answer: [StoreCreationChallengesAnswer]) {
        if answer.isEmpty {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerChallengesQuestion))
        }
        challenges = answer
        currentQuestion = .features
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerFeaturesQuestion))
    }

    func saveFeatures(_ answer: [StoreCreationFeaturesAnswer]) {
        if answer.isEmpty {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerFeaturesQuestion))
        }
        features = answer
        handleCompletion()
    }

    func backtrackOrDismissProfiler() {
        if let previousQuestion = currentQuestion.previousQuestion {
            currentQuestion = previousQuestion
        } else {
            completionHandler()
        }
    }
}

private extension StoreCreationProfilerQuestionContainerViewModel {
    func handleCompletion() {
        analytics.track(event: .StoreCreation.siteCreationProfilerData(answers,
                                                                       challenges: challenges,
                                                                       features: features))
        completionHandler()
    }

    func storeAnswers() {
        uploadAnswersUseCase.storeAnswers(answers)
    }
}
