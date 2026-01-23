import Foundation

public enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper

    /// Production-like build but with more enabled to help people test branches
    /// that might be behind feature flags.
    case alpha

    /// Production build released in the app store
    case appStore

    public static var current: BuildConfiguration {
        let appConfigName = Bundle.main.object(forInfoDictionaryKey: "BuildConfigurationName") as? String
        if appConfigName == "Debug" {
            #if DEBUG
            return testingOverride ?? .localDeveloper
            #else
            return .localDeveloper
            #endif
        } else if appConfigName == "Release-Alpha" {
            return .alpha
        } else {
            return .appStore
        }
    }

    public var isProduction: Bool {
        switch self {
        case .localDeveloper, .alpha:
            return false
        case .appStore:
            return true
        }
    }

    static func ~=(a: BuildConfiguration, b: Set<BuildConfiguration>) -> Bool {
        return b.contains(a)
    }

    #if DEBUG
    private static var testingOverride: BuildConfiguration?

    func test(_ closure: () -> ()) {
        BuildConfiguration.testingOverride = self
        closure()
        BuildConfiguration.testingOverride = nil
    }
    #endif
}
