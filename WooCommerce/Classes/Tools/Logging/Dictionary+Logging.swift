import Foundation

extension Dictionary where Key == String {
    /// Manually serializes a value in a dictionary if the value is not already serializable.
    func serializeValuesForLoggingIfNeeded() -> [String: Any] {
        guard JSONSerialization.isValidJSONObject(self) == false else {
            return self
        }

        return reduce(into: [:]) { formattedProperties, entry in
            let (key, value) = entry
            guard JSONSerialization.isValidJSONObject([key: value]) == false else {
                formattedProperties[key] = value
                return
            }

            if let nsError = value as? NSError {
                formattedProperties[key] = [
                    "Domain": nsError.domain,
                    "Code": nsError.code,
                    "Description": nsError.localizedDescription,
                    "User Info": nsError.userInfo.description
                ] as [String: Any]
                return
            }

            formattedProperties[key] = "\(value)"
        }
    }
}
