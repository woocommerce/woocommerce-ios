import Foundation

/// Aggregate DI the app target supplies when mounting the assistant.
/// Mirrors the pattern established by `POSDependencyProviding` in PointOfSale.
public protocol AssistantDependencyProviding: Sendable {
    var analytics: AssistantAnalyticsProviding { get }
    var externalNavigation: AssistantExternalNavigationProviding { get }
    var jwtProvider: AssistantJWTProviding { get }
}
