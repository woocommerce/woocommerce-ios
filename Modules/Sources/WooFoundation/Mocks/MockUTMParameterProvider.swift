import Foundation

public struct MockUTMParameterProvider: UTMParametersProviding {
    public var limitToHosts: [String]?

    public var parameters: [UTMParameterKey: String?]

    public init(parameters: [UTMParameterKey: String?] = [.medium: "woo_ios"]) {
        self.parameters = parameters
    }
}
