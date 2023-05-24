import Foundation
import Yosemite

/// ViewModel for the privacy banner
///
final class PrivacyBannerViewModel: ObservableObject {

    /// Stores the value for the analytics choice.
    ///
    @Published var analyticsEnabled: Bool = false

    /// Determines if the save button should show a loading state.
    ///
    @Published private(set) var isLoading: Bool = false

    /// Determines if the view should be enabled.
    ///
    @Published private(set) var isViewEnabled: Bool = true

    /// Completion handler.
    ///
    @MainActor private let onCompletion: (Result<Destination, PrivacyBannerViewModel.Error>) -> ()

    /// Stores & Session.
    ///
    private let stores: StoresManager

    /// Analytics Manager
    ///
    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping (Result<Destination, PrivacyBannerViewModel.Error>) -> ()) {
        self.analyticsEnabled = analytics.userHasOptedIn
        self.stores = stores
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    /// Submit changes and notifies via the `completion` block.
    ///
    @MainActor func submitChanges(destination: Destination) async {
        // Set Loading state
        isLoading = true
        isViewEnabled = false

        // Perform update
        let useCase = UpdateAnalyticsSettingUseCase(stores: stores, analytics: analytics)
        do {
            try await useCase.update(optOut: !analyticsEnabled)
            onCompletion(.success(destination))
        } catch {
            onCompletion(.failure(.sync(analyticsOptOut: !analyticsEnabled, intendedDestination: destination)))
        }

        // Revert Loading state
        isLoading = false
        isViewEnabled = true

        // Analytics
        trackAnalytics(from: destination)
    }

    /// Track analytics based on the destination provided by the view.
    /// Dismiss ----> Save
    /// Settings ----> Settings
    ///
    private func trackAnalytics(from destination: Destination) {
        switch destination {
        case .dismiss:
            analytics.track(event: .PrivacyChoicesBanner.saveButtonTapped())
        case .settings:
            analytics.track(event: .PrivacyChoicesBanner.settingsButtonTapped())
        }
    }
}

// MARK: Definitions
extension PrivacyBannerViewModel {
    /// View destination after submitting changes
    ///
    enum Destination {
        case settings
        case dismiss
    }

    /// Defined errors.
    ///
    enum Error: Swift.Error {
        case sync(analyticsOptOut: Bool, intendedDestination: Destination)
    }
}
