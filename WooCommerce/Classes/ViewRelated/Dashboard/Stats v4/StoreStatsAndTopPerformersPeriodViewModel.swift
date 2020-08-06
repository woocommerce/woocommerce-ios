import Yosemite
import class AutomatticTracks.CrashLogging

/// ViewModel for `StoreStatsAndTopPerformersPeriodViewController`.
///
/// This was created after `StoreStatsAndTopPerformersPeriodViewController` existed so not
/// all data-loading are in here.
///
final class StoreStatsAndTopPerformersPeriodViewModel {

    /// If applicable, present the in-app feedback card. The in-app feedback card may still not be
    /// presented depending on the constraints. But setting this to `false`, will ensure that it
    /// will never be presented.
    let canDisplayInAppFeedbackCard: Bool

    /// An Observable that informs the UI whether the in-app feedback card should be displayed or not.
    var isInAppFeedbackCardVisible: Observable<Bool> {
        isInAppFeedbackCardVisibleSubject
    }
    private let isInAppFeedbackCardVisibleSubject = BehaviorSubject(false)

    private let featureFlagService: FeatureFlagService
    private let storesManager: StoresManager

    /// Create an instance of `self`.
    ///
    /// - Parameter canDisplayInAppFeedbackCard: If applicable, present the in-app feedback card.
    ///     The in-app feedback card may still not be presented depending on the constraints.
    ///     But setting this to `false`, will ensure that it will never be presented.
    ///
    init(canDisplayInAppFeedbackCard: Bool,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.canDisplayInAppFeedbackCard = canDisplayInAppFeedbackCard
        self.featureFlagService = featureFlagService
        self.storesManager = storesManager

        updateIsInAppFeedbackCardVisibleValue()
    }

    /// Calculates and updates the value of `isInAppFeedbackCardVisibleSubject`.
    private func updateIsInAppFeedbackCardVisibleValue() {
        // Abort right away if we don't need to calculate the real value.
        let isEnabled = canDisplayInAppFeedbackCard && featureFlagService.isFeatureFlagEnabled(.inAppFeedback)
        if !isEnabled {
            return isInAppFeedbackCardVisibleSubject.send(isEnabled)
        }

        let action = AppSettingsAction.loadInAppFeedbackCardVisibility { result in
            switch result {
            case .success(let shouldBeVisible):
                self.isInAppFeedbackCardVisibleSubject.send(shouldBeVisible)
            case .failure(let error):
                CrashLogging.logError(error)
                // We'll just send a `false` value. I think this is the safer bet.
                self.isInAppFeedbackCardVisibleSubject.send(false)
            }
        }
        storesManager.dispatch(action)
    }
}
