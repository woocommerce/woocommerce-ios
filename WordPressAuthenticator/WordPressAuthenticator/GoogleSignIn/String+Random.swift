extension String {

    static func randomString(using characters: Set<Character>, withLength length: Int) -> String {
        let allowedCharactersCount = UInt32(characters.count)

        return (0..<length).reduce("") { accumulator, _ in
           let randomOffset = Int(arc4random_uniform(allowedCharactersCount))
           let randomCharacter = characters[characters.index(characters.startIndex, offsetBy: randomOffset)]
           return accumulator + String(randomCharacter)
        }
    }
}
