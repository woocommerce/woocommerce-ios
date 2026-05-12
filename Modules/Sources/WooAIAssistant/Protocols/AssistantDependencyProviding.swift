/// Aggregate DI the app target supplies when mounting the assistant.
public protocol AssistantDependencyProviding: Sendable {
    var analytics: AssistantAnalyticsProviding { get }
    var externalNavigation: AssistantExternalNavigationProviding { get }
    var externalViews: AssistantExternalViewProviding { get }
}
