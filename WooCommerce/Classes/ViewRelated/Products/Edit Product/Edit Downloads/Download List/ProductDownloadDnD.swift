import Foundation
import CoreServices
import Yosemite

/// A wrapper around ProductDownload, to make it compatible in using as Drag and Drop data source in an table view. Represents a ProductDownload entity.
///
public class ProductDownloadDnD: NSObject, Codable {
    public let download: ProductDownload

    /// ProductDownloadDnD initializer.
    ///
    public init(download: ProductDownload) {
        self.download = download
    }

    /// Public initializer for ProductDownloadDnD
    ///
    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let download = try container.decode(ProductDownload.self, forKey: .download)
        self.init(download: download)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(download, forKey: .download)
    }
}

extension ProductDownloadDnD: NSItemProviderReading, NSItemProviderWriting {
    public static var readableTypeIdentifiersForItemProvider: [String] {
        return [(kUTTypeUTF8PlainText) as String]
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
          //Here we decode the object back to it's class representation and return it
          let counter = try decoder.decode(ProductDownloadDnD.self, from: data)
            return counter as! Self
        } catch {
          throw CodableError.decodeFailure
        }
    }

    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [(kUTTypeUTF8PlainText) as String]
    }

    public func loadData(withTypeIdentifier typeIdentifier: String,
                         forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
          do {
            //Here the object is encoded to a JSON data object and sent to the completion handler
            let data = try JSONEncoder().encode(self)
              progress.completedUnitCount = 100
              completionHandler(data, nil)
          } catch {
            completionHandler(nil, CodableError.encodeFailure)
          }
        return progress
    }
}

/// Defines all the ProductDownload CodingKeys.
///
private extension ProductDownloadDnD {
    enum CodingKeys: String, CodingKey {
        case download = "download"
    }

    enum CodableError: Error {
        case invalidDataType, decodeFailure, encodeFailure
    }
}
