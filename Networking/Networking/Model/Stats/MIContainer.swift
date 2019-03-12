import Foundation

/**
 This is a generic container data container used to hold an (unkeyed) data array
 of which its elements can be multiple types. Additionally, the field names
 are stored in a separate array where the specific index of a field name element
 corresponds to its matching element in the `data` array.

 Why do we have this insanity? To deal with JSON payloads that can look like this:
 ````
        {
        "fields": [
            "period",
            "orders",
            "total_sales",
            "total_tax",
            "total_shipping",
            "currency",
            "gross_sales"
        ],
        "data": [
            [ "2018-06-01", 2, 14.24, 9.98, 0.28, "USD", 14.120000000000001 ],
             [ 2018, 2, 123123, 9.98, 0.0, "USD", 0]
        ]
        ...
        }
 ````

 A few accessor methods are also provided that will ensure the correct type is returned for a given field. This container
 will be especially useful when dealing with data returned from the stats endpoints. 😃
*/
public struct MIContainer {
    let data: [Any]
    let fieldNames: [String]

    func fetchStringValue<T: RawRepresentable>(for field: T) -> String where T.RawValue == String {
        guard let index = fieldNames.index(of: field.rawValue) else {
            return ""
        }

        // 😢 As crazy as it sounds, sometimes the server occasionally returns
        // String values as Ints — we need to account for this.
        if self.data[index] is Int {
            if let intValue = self.data[index] as? Int {
                return String(intValue)
            }
            return ""
        } else {
            return self.data[index] as? String ?? ""
        }
    }

    func fetchIntValue<T: RawRepresentable>(for field: T) -> Int where T.RawValue == String {
        guard let index = fieldNames.index(of: field.rawValue),
            let returnValue = self.data[index] as? Int else {
                return 0
        }
        return returnValue
    }

    func fetchDoubleValue<T: RawRepresentable>(for field: T) -> Double where T.RawValue == String {
        guard let index = fieldNames.index(of: field.rawValue) else {
            return 0
        }

        if self.data[index] is Int {
            let intValue = self.data[index] as? Int ?? 0
            return Double(intValue)
        } else {
            return self.data[index] as? Double ?? 0
        }
    }
}
