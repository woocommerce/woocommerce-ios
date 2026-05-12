import AppIntents
import KeychainAccess

/// Drives the Edit Widget UI for the `metrics` parameter on `StoreStatsConfigurationIntent`.
///
/// Backs the entity-array `IntentParameter` initializer, which renders a section (titled by the
/// parameter `title`) of N inline rows per widget family — N is constrained by the parameter's
/// `size:` map. Tapping a row opens the picker populated by `suggestedEntities()`.
///
/// Conforms to `EnumerableEntityQuery` because the catalog is finite and static. iOS uses
/// `allEntities()` to materialize the full set upfront so the parameter's `default:` IDs are
/// validated synchronously when the Edit Widget sheet opens — without this, the Metrics
/// section can render empty (or be hidden entirely) on first widget configuration while iOS
/// lazily resolves the defaults through `entities(for:)`.
///
/// `suggestedEntities()` is auth-aware so self-hosted users only see metrics that can fetch data
/// with site credentials. `allEntities()` and `entities(for:)` intentionally keep resolving the
/// full catalog so existing widget configurations with hidden metrics continue to load and render
/// their standard "-" placeholder values.
///
struct AvailableMetricsQuery: EnumerableEntityQuery {
    enum AuthenticationMode: Sendable {
        case wpcom
        case siteCredentials
        case unknown
    }

    private let authenticationMode: @Sendable () -> AuthenticationMode

    init() {
        self.init(authenticationMode: { Self.currentAuthenticationMode() })
    }

    init(authenticationMode: @escaping @Sendable () -> AuthenticationMode) {
        self.authenticationMode = authenticationMode
    }

    func allEntities() async throws -> [StoreInfoMetricType] {
        StoreInfoMetricType.allCases
    }

    func entities(for identifiers: [StoreInfoMetricType.ID]) async throws -> [StoreInfoMetricType] {
        let entitiesByIdentifier = Dictionary(uniqueKeysWithValues: StoreInfoMetricType.allCases.map { ($0.id, $0) })
        return identifiers.compactMap { entitiesByIdentifier[$0] }
    }

    func suggestedEntities() async throws -> [StoreInfoMetricType] {
        switch authenticationMode() {
        case .siteCredentials:
            return StoreInfoMetricType.allCases.filter(\.isAvailableWithSiteCredentials)
        case .wpcom, .unknown:
            return StoreInfoMetricType.allCases
        }
    }

    private static func currentAuthenticationMode() -> AuthenticationMode {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        if keychain[WooConstants.authToken] != nil {
            return .wpcom
        }
        if keychain[WooConstants.siteCredentialPassword] != nil ||
            keychain[WooConstants.applicationPassword] != nil {
            return .siteCredentials
        }
        return .unknown
    }
}
