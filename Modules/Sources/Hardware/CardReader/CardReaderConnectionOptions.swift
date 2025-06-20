import Foundation

public struct CardReaderConnectionOptions {
    public let tapToPayOptions: TapToPayCardReaderConnectionOptions?

    public init(tapToPayOptions: TapToPayCardReaderConnectionOptions?) {
        self.tapToPayOptions = tapToPayOptions
    }
}

public struct TapToPayCardReaderConnectionOptions {
    public let termsOfServiceAcceptancePermitted: Bool

    public init(termsOfServiceAcceptancePermitted: Bool) {
        self.termsOfServiceAcceptancePermitted = termsOfServiceAcceptancePermitted
    }
}
