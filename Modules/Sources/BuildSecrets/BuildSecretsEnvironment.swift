import Foundation

enum BuildSecretsEnvironment {
    case live
    case preview
    case test

    static var current: BuildSecretsEnvironment {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .preview
        }

        if NSClassFromString("XCTestCase") != nil {
            return .test
        }

        return .live
    }
}
