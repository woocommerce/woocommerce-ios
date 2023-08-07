import UIKit
import Yosemite

final class StoreCreationProfilerCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let storeName: String
    private let analytics: Analytics
    private let completionHandler: (SiteProfilerData?) -> Void

    private var storeCategory: StoreCreationCategoryAnswer?
    private var sellingStatus: StoreCreationSellingStatusAnswer?
    private var storeCountry: SiteAddress.CountryCode = .US

    init(storeName: String,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (SiteProfilerData?) -> Void) {
        self.storeName = storeName
        self.navigationController = navigationController
        self.analytics = analytics
        self.completionHandler = onCompletion
    }

    func start() {
        showSellingStatusQuestion()
    }
}

// MARK: - Navigation
private extension StoreCreationProfilerCoordinator {

    func showSellingStatusQuestion() {
        let questionController = StoreCreationSellingStatusQuestionHostingController(onContinue: { [weak self] sellingStatus in
            guard let self else { return }
            if sellingStatus?.sellingStatus == .alreadySellingOnline && sellingStatus?.sellingPlatforms?.isEmpty == true {
                self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingPlatformsQuestion))
            }
            self.sellingStatus = sellingStatus
            self.showCategoryQuestion()
        }, onSkip: { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingStatusQuestion))
            self.sellingStatus = nil
            self.showCategoryQuestion()
        })

        navigationController.setViewControllers([questionController], animated: true)
        questionController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(dismissProfiler))

        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerSellingStatusQuestion))
    }

    func showCategoryQuestion() {
        let questionController = StoreCreationCategoryQuestionHostingController(viewModel:
                .init(onContinue: { [weak self] category in
                    guard let self else { return }
                    self.storeCategory = category
                    self.showStoreCountryQuestion()
                }, onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
                    self.storeCategory = nil
                    self.showStoreCountryQuestion()
                })
        )
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCategoryQuestion))
    }

    func showStoreCountryQuestion() {
        let questionController = StoreCreationCountryQuestionHostingController(viewModel:
                .init(onContinue: { [weak self] countryCode in
                    guard let self else { return }
                    self.storeCountry = countryCode
                    self.showChallengesQuestion()
                }, onSupport: { [weak self] in
                    self?.showSupport()
                })
        )
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCountryQuestion))
    }

    func showChallengesQuestion() {
        let questionController = StoreCreationChallengesQuestionHostingController(viewModel:
                .init { [weak self] challenges in
                    guard let self else { return }
                    self.showFeaturesQuestion()
                } onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerChallengesQuestion))
                    self.showFeaturesQuestion()
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerChallengesQuestion))
    }

    func showFeaturesQuestion() {
        let questionController = StoreCreationFeaturesQuestionHostingController(viewModel:
                .init { [weak self] features in
                    guard let self else { return }
                    self.handleCompletion()
                } onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerFeaturesQuestion))
                    self.handleCompletion()
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerFeaturesQuestion))
    }
}

// MARK: - Helpers
private extension StoreCreationProfilerCoordinator {
    @objc
    func dismissProfiler() {
        // TODO: show confirm alert if needed
        completionHandler(nil)
    }

    func handleCompletion() {
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

    func showSupport() {
        let sourceTag = "origin:store-creation"
        let supportForm = SupportFormHostingController(viewModel: .init(sourceTag: sourceTag))
        supportForm.show(from: navigationController)
    }
}
