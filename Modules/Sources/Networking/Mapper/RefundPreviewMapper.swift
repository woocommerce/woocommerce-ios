import Foundation


/// Mapper: RefundPreview (v4 `POST refunds/preview` response)
///
struct RefundPreviewMapper: Mapper {

    /// (Attempts) to convert a dictionary into a RefundPreview.
    ///
    func map(response: Data) throws -> RefundPreview {
        let decoder = JSONDecoder()

        if hasDataEnvelope(in: response) {
            return try decoder.decode(RefundPreviewEnvelope.self, from: response).preview
        } else {
            return try decoder.decode(RefundPreview.self, from: response)
        }
    }
}


/// RefundPreviewEnvelope Disposable Entity
///
/// The preview endpoint returns the document in the `data` key when tunneled. This entity
/// allows us to parse it with JSONDecoder.
///
private struct RefundPreviewEnvelope: Decodable {
    let preview: RefundPreview

    private enum CodingKeys: String, CodingKey {
        case preview = "data"
    }
}
