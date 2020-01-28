@testable import Yosemite

struct MockMediaExportService: MediaExportService {
    private let uploadableMedia: UploadableMedia?

    init(uploadableMedia: UploadableMedia?) {
        self.uploadableMedia = uploadableMedia
    }

    func export(_ exportable: ExportableAsset, onCompletion: @escaping MediaExportCompletion) {
        let error = uploadableMedia == nil ? NSError(domain: "\(type(of: self))", code: 0, userInfo: nil): nil
        onCompletion(uploadableMedia, error)
    }
}
