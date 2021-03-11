import Foundation
import Networking

/// Collection of static functions that creates specific products from a `fake` instance.
///
public enum ProductFactory {

    /// Returns a fake product with a 3 downloadable files
    ///
    public static func productWithDownloadableFiles() -> Product {
        Product.fake().copy(
            downloadable: true,
            downloads: [
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11", name: "Song #1", fileURL: "https://example.com/woo-single-1.ogg"),
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b12", name: "Song #2", fileURL: "https://example.com/woo-single-2.ogg"),
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b13", name: "Song #3", fileURL: "https://example.com/woo-single-3.ogg")
            ],
            downloadLimit: 1,
            downloadExpiry: 1
        )
    }
}
