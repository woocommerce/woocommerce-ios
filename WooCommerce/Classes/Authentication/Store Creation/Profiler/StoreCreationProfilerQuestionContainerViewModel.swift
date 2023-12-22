import Foundation
import Experiments
import Yosemite
import WooFoundation

enum StoreCreationProfilerQuestion: Int, CaseIterable {
    case sellingStatus = 1
    case category
    case country
    case theme

    var analyticStep: WooAnalyticsEvent.StoreCreation.Step {
        switch self {
        case .sellingStatus:
            return .profilerSellingStatusQuestion
        case .category:
            return .profilerCategoryQuestion
        case .country:
            return .profilerCountryQuestion
        case .theme:
            return .themePicker
        }
    }
}

/// View model for `StoreCreationProfilerQuestionContainer`.
final class StoreCreationProfilerQuestionContainerViewModel: ObservableObject {

    private let siteID: Int64
    let storeName: String
    let themesCarouselViewModel: ThemesCarouselViewModel

    /// profiler question list
    var questions: [StoreCreationProfilerQuestion] {
        let defaultQuestions: [StoreCreationProfilerQuestion] = [.sellingStatus, .category, .country]
        guard featureFlagService.isFeatureFlagEnabled(.lightweightStorefront) else {
            return defaultQuestions
        }
        return defaultQuestions + [.theme]
    }

    /// Progress to display for the profiler flow
    var progress: Double {
        let incrementBy = 1.0 / Double(questions.count)
        return Double(currentQuestion.rawValue) * incrementBy
    }

    var previousQuestion: StoreCreationProfilerQuestion? {
        .init(rawValue: currentQuestion.rawValue - 1)
    }

    private let featureFlagService: FeatureFlagService
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
    private let uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol
    private let themeInstaller: ThemeInstallerProtocol

    private var answers: StoreProfilerAnswers {
        let sellingPlatforms = sellingStatus?.sellingPlatforms?.map { $0.rawValue }.sorted().joined(separator: ",")
        let sellingStatus = sellingStatus?.sellingStatus
        return StoreProfilerAnswers(sellingStatus: sellingStatus,
                                    sellingPlatforms: sellingPlatforms,
                                    category: storeCategory?.value,
                                    countryCode: storeCountry?.rawValue)
    }

    private var currentQuestionIndex: Int = 0

    @Published private(set) var currentQuestion: StoreCreationProfilerQuestion = .sellingStatus

    init(siteID: Int64,
         storeName: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onCompletion: @escaping () -> Void,
         uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol,
         themeInstaller: ThemeInstallerProtocol = DefaultThemeInstaller()) {
        self.siteID = siteID
        self.storeName = storeName
        self.analytics = analytics
        self.completionHandler = onCompletion
        self.uploadAnswersUseCase = uploadAnswersUseCase
        self.themeInstaller = themeInstaller
        self.themesCarouselViewModel = .init(mode: .storeCreationProfiler, stores: stores)
        self.featureFlagService = featureFlagService
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
        moveToNextQuestionIfAvailable()
    }

    func saveCategory(_ answer: StoreCreationCategoryAnswer?) {
        if answer == nil {
            analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
        }
        storeCategory = answer
        moveToNextQuestionIfAvailable()
    }

    func saveCountry(_ answer: CountryCode) {
        storeCountry = answer
        moveToNextQuestionIfAvailable()
    }

    func saveTheme(_ theme: WordPressTheme?) {
        if let theme {
            themeInstaller.scheduleThemeInstall(themeID: theme.id, siteID: siteID)
        }
        moveToNextQuestionIfAvailable()
    }

    func backtrackOrDismissProfiler() {
        if let previousQuestion {
            currentQuestion = previousQuestion
        } else {
            completionHandler()
        }
    }
}

private extension StoreCreationProfilerQuestionContainerViewModel {
    func moveToNextQuestionIfAvailable() {
        currentQuestionIndex += 1
        if let question = questions[safe: currentQuestionIndex] {
            currentQuestion = question
            analytics.track(event: .StoreCreation.siteCreationStep(step: currentQuestion.analyticStep))
        } else {
            handleCompletion()
        }
    }

    func handleCompletion() {
        analytics.track(event: .StoreCreation.siteCreationProfilerData(answers))
        completionHandler()
    }

    func storeAnswers() {
        uploadAnswersUseCase.storeAnswers(answers)
    }
}
