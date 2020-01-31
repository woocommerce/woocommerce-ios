enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper
    
    /// Production-like build but with more enabled to help people test branches
    /// that might be behind feature flags.
    case alpha

    /// Production build released in the app store
    case appStore

    static var current: BuildConfiguration {
        #if DEBUG
        return testingOverride ?? .localDeveloper
        #elseif ALPHA
        return .alpha
        #else
        return .appStore
        #endif
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
