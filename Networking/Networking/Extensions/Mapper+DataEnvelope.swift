extension Mapper {

    /// Checks whether the JSON data has a `data` key at the root.
    func hasDataEnvelope(in response: Data) -> Bool {
        do {
            _ = try JSONDecoder().decode(Envelope<AnyDecodable>.self, from: response)
            return true
        } catch {
            return false
        }
    }
}
