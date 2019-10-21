enum BuildConfiguration: String {
    /// Development build, usually run from Xcode
    case localDeveloper

    /// Production build released in the app store
    case appStore

    static var current: BuildConfiguration {
        #if DEBUG
            return testingOverride ?? .localDeveloper
        #else
            return .appStore
        #endif
    }

    static func ~= (a: BuildConfiguration, b: Set<BuildConfiguration>) -> Bool {
        return b.contains(a)
    }

    #if DEBUG
        private static var testingOverride: BuildConfiguration?

            func test(_ closure: () -> Void)
        {
            BuildConfiguration.testingOverride = self
            closure()
            BuildConfiguration.testingOverride = nil
        }
    #endif
}
