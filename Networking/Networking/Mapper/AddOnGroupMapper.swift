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
        return try decoder.decode(AddOnGroupEnvelope.self, from: response).data
    }
}

/// `AddOnGroupEnvelope` Disposable Entity:
/// `AddOnGroup` endpoints returns it's add-on-groups json in the `data` key.
///
private struct AddOnGroupEnvelope: Decodable {
    let data: [AddOnGroup]
}
