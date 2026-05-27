import Foundation

/// Maps the `GET /wc-pos/v1/staff` JSON response into `[POSStaffMember]`.
///
struct POSStaffMapper: Mapper {
    func map(response: Data) throws -> [POSStaffMember] {
        let decoder = JSONDecoder()
        return try decoder.decode(POSStaffEnvelope.self, from: response).staff
    }
}

private struct POSStaffEnvelope: Decodable {
    let staff: [POSStaffMember]
}
