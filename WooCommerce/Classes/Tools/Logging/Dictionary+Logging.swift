import Foundation

extension Dictionary where Key == String {
    /// Manually serializes a value in a dictionary if the value is not already serializable.
    func serializeValuesForLoggingIfNeeded() -> [String: Any] {
        guard JSONSerialization.isValidJSONObject(self) == false else {
            return self
        }

        return reduce([:]) { (properties, entry) -> [String: Any] in
            let (key, value) = entry
            var formattedProperties: [String: Any] = properties
            guard JSONSerialization.isValidJSONObject([key: value]) == false else {
                formattedProperties[key] = value
                return formattedProperties
            }

            if let nsError = value as? NSError {
                formattedProperties[key] = [
                    "Domain": nsError.domain,
                    "Code": nsError.code,
                    "Description": nsError.localizedDescription,
                    "User Info": nsError.userInfo.description
                ]
                return formattedProperties
            }

            formattedProperties[key] = "\(value)"
            return formattedProperties
        }
    }
}
