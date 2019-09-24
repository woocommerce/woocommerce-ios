import Foundation


// MARK: - Dictionary: JSON Encoding Helpers
//
extension Dictionary where Key: Encodable, Value: Encodable {

    /// Returns a String with the JSON Representation of the receiver.
    ///
    func toJSONEncoded() -> String? {
        guard let encoded = try? JSONEncoder().encode(self) else {
            return nil
        }

        return String(data: encoded, encoding: .utf8)
    }
}

extension Dictionary where Key: Hashable, Value: Any {

    /// Returns a String with the JSON Representation of the receiver.
    ///
    func toJSONEncoded() -> String? {
        let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [])
        guard let data = jsonData else {return nil}
        return String(data: data, encoding: .utf8)
    }
}
