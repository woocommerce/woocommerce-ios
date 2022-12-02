struct GoogleClientId {

    let value: String

    init?(string: String) {
        guard string.split(separator: ".").count > 1 else {
            return nil
        }
        self.value = string
    }
}
