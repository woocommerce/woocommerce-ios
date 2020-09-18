import Yosemite

/// Contains editable properties of a product model in the downloabadle files settings.
///
struct ProductDownloadsEditableData: Equatable {
    let downloads: [ProductDownload]
    let downloadLimit: Int64
    let downloadExpiry: Int64
}

extension ProductDownloadsEditableData {
    init(productModel: ProductFormDataModel) {
        self.downloads = productModel.downloads
        self.downloadLimit = productModel.downloadLimit
        self.downloadExpiry = productModel.downloadExpiry
    }
}
