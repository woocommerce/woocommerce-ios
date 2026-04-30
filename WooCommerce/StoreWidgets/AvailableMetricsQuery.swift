import AppIntents

/// Drives the Edit Widget UI for the `metrics` parameter on `StoreStatsConfigurationIntent`.
///
/// Backs the entity-array `IntentParameter` initializer, which renders a section (titled by the
/// parameter `title`) of N inline rows per widget family — N is enforced by the parameter's
/// `size:` map. Tapping a row opens the picker populated by `suggestedEntities()`.
///
/// The picker shows the full catalog regardless of auth mode. Metrics whose data sources
/// require WPCom/Jetpack (`visitors`, `conversion`) come back as `.unavailable` for self-hosted
/// users and render as the standard "-" placeholder in the cell — see
/// `StoreInfoFormatter.Constants.valuePlaceholderText`. Filtering the picker by auth mode is
/// tracked as a follow-up.
///
struct AvailableMetricsQuery: EntityQuery {
    func entities(for identifiers: [StoreInfoMetricType.ID]) async throws -> [StoreInfoMetricType] {
        StoreInfoMetricType.allCases.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [StoreInfoMetricType] {
        StoreInfoMetricType.allCases
    }
}
