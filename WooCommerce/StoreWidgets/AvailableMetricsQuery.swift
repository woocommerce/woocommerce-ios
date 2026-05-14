import AppIntents

/// Drives the Edit Widget UI for the `metrics` parameter on `StoreStatsConfigurationIntent`.
///
/// Backs the entity-array `IntentParameter` initializer, which renders a section (titled by the
/// parameter `title`) of N inline rows per widget family — N is enforced by the parameter's
/// `size:` map. Tapping a row opens the picker populated by `suggestedEntities()`.
///
/// Conforms to `EnumerableEntityQuery` because the catalog is finite and static. iOS uses
/// `allEntities()` to materialize the full set upfront so the parameter's `default:` IDs are
/// validated synchronously when the Edit Widget sheet opens — without this, the Metrics
/// section can render empty (or be hidden entirely) on first widget configuration while iOS
/// lazily resolves the defaults through `entities(for:)`.
///
/// The picker shows "None" first, then the full catalog regardless of auth mode. Metrics whose
/// data sources require WPCom/Jetpack (`visitors`, `conversion`) come back as `.unavailable`
/// for self-hosted users and render as the standard "-" placeholder in the cell — see
/// `StoreInfoFormatter.Constants.valuePlaceholderText`. Filtering the picker by auth mode is
/// tracked as a follow-up.
///
struct AvailableMetricsQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [StoreInfoMetricType] {
        StoreInfoMetricType.pickerCases
    }

    func entities(for identifiers: [StoreInfoMetricType.ID]) async throws -> [StoreInfoMetricType] {
        let metricsByID = Dictionary(uniqueKeysWithValues: StoreInfoMetricType.pickerCases.map { ($0.id, $0) })
        return identifiers.compactMap { metricsByID[$0] }
    }

    func suggestedEntities() async throws -> [StoreInfoMetricType] {
        StoreInfoMetricType.pickerCases
    }
}
