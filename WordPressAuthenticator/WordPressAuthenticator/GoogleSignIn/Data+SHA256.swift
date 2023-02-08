import CommonCrypto

extension Data {

    func sha256Hashed() -> Data {
        Data(sha256Hash())
    }

    func sha256Hashed() -> String {
        sha256Hash().map { String(format: "%02x", $0) }.joined(separator: "")
    }

    private func sha256Hash() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return hash
    }
}
