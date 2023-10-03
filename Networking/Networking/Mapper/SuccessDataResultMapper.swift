/// Mapper: Success Result Wrapped in `data` Key
///
struct SuccessDataResultMapper: Mapper {

    /// (Attempts) to extract the `success` flag from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> Bool {
        let decoder = JSONDecoder()
        let successResponse: SuccessResponse
        if hasDataEnvelope(in: response) {
            successResponse = try decoder.decode(Envelope<SuccessResponse>.self, from: response).data
        } else {
            successResponse = try decoder.decode(SuccessResponse.self, from: response)
        }
        return successResponse.success ?? false
    }
}

private struct SuccessResponse: Decodable {
    let success: Bool?
}
