extension String {

    /// Returns a cryptographically secure string generated with characters from the given `Set<Character>` and with length
    /// `length`.
    ///
    /// - Complexity: O(n) where n is the given `length`.
    static func secureRandomString(using characters: Set<Character>, withLength length: Int) -> String {
        let allowedCharactersCount = UInt32(characters.count)

        var randomBytes = [UInt8](repeating: 0, count: length)
        // Use `SecRandomCopyBytes` to generate cryptographically secure random bytes to use as
        // offsets to create the random string.
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

        // FIXME: Handle errors by returning nil
        guard status == errSecSuccess else {
            fatalError()
        }

        return randomBytes.reduce("") { accumulator, randomByte in
            let randomOffset = Int(randomByte) % Int(allowedCharactersCount)
            let randomCharacter = characters[characters.index(characters.startIndex, offsetBy: randomOffset)]
            return accumulator + String(randomCharacter)
        }
    }
}
