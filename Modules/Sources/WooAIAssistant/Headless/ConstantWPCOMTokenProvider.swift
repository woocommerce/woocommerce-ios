struct ConstantWPCOMTokenProvider: WPCOMTokenProviding {
    let value: String

    func token() async throws -> String { value }
}
