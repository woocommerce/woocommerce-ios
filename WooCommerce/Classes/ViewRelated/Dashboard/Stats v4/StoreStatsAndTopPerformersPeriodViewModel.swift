
import Foundation

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

    /// Create an instance of `self`.
    ///
    /// - Parameter canDisplayInAppFeedbackCard: If applicable, present the in-app feedback card.
    ///     The in-app feedback card may still not be presented depending on the constraints.
    ///     But setting this to `false`, will ensure that it will never be presented.
    ///
    init(canDisplayInAppFeedbackCard: Bool,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.canDisplayInAppFeedbackCard = canDisplayInAppFeedbackCard
        self.featureFlagService = featureFlagService

        updateIsInAppFeedbackCardVisibleValue()
    }

    /// Calculates and updates the value of `isInAppFeedbackCardVisibleSubject`.
    private func updateIsInAppFeedbackCardVisibleValue() {
        let isVisible = canDisplayInAppFeedbackCard && featureFlagService.isFeatureFlagEnabled(.inAppFeedback)
        isInAppFeedbackCardVisibleSubject.send(isVisible)
    }
}
