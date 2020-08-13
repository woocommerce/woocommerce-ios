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
    }

    /// Must be called by the `ViewController` during the `viewDidAppear()` event. This will
    /// update the visibility of the in-app feedback card.
    ///
    /// The visibility is updated on `viewDidAppear()` to consider scenarios when the app is
    /// never terminated.
    ///
    func onViewDidAppear() {
        updateIsInAppFeedbackCardVisibleValue()
    }

    /// Calculates and updates the value of `isInAppFeedbackCardVisibleSubject`.
    private func updateIsInAppFeedbackCardVisibleValue() {
        // Abort right away if we don't need to calculate the real value.
        let isEnabled = canDisplayInAppFeedbackCard && featureFlagService.isFeatureFlagEnabled(.inAppFeedback)
        guard isEnabled else {
            return isInAppFeedbackCardVisibleSubject.send(isEnabled)
        }

        let action = AppSettingsAction.loadInAppFeedbackCardVisibility { [weak self] result in
            guard let self = self else {
                return
            }

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
