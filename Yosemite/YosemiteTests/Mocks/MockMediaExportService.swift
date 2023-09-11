@testable import Yosemite

struct MockMediaExportService: MediaExportService {
    private let uploadableMedia: UploadableMedia?

    init(uploadableMedia: UploadableMedia?) {
        self.uploadableMedia = uploadableMedia
    }

    func export(_ exportable: ExportableAsset, filename: String?, altText: String?) async throws -> UploadableMedia {
        guard let uploadableMedia else {
            throw NSError(domain: "\(type(of: self))", code: 0, userInfo: nil)
        }
        return uploadableMedia
    }
}
