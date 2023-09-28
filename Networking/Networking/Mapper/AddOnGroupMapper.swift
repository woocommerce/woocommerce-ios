import Foundation

/// Maps between a raw json response to an array of `AddOnGroups`
///
struct AddOnGroupMapper: Mapper {
    /// Site Identifier associated to the `AddOnGroup` that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because `SiteID` is not returned in any of the `AddOnGroup` endpoints.
    ///
    let siteID: Int64

    func map(response: Data) throws -> [AddOnGroup] {
        let decoder = JSONDecoder()
        decoder.userInfo = [.siteID: siteID]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[AddOnGroup]>.self, from: response).data
        } else {
            return try decoder.decode([AddOnGroup].self, from: response)
        }
    }
}
