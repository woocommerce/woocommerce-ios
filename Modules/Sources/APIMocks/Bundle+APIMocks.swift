import Foundation

extension Bundle {
    static var apiMocks: Bundle {
#if DEBUG
        // Workaround for https://forums.swift.org/t/swift-5-3-swiftpm-resources-in-tests-uses-wrong-bundle-path/37051
        if let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"],
           let bundle = Bundle(path: "\(testBundlePath)/Modules_APIMocks.bundle") {
            return bundle
        }
#endif
        return Bundle.module
    }
}
