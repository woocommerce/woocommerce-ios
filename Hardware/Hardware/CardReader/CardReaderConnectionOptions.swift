import Foundation

public struct CardReaderConnectionOptions {
    public let builtInOptions: BuiltInCardReaderConnectionOptions?

    public init(builtInOptions: BuiltInCardReaderConnectionOptions?) {
        self.builtInOptions = builtInOptions
    }
}

public struct BuiltInCardReaderConnectionOptions {
    public let termsOfServiceAcceptancePermitted: Bool

    public init(termsOfServiceAcceptancePermitted: Bool) {
        self.termsOfServiceAcceptancePermitted = termsOfServiceAcceptancePermitted
    }
}
