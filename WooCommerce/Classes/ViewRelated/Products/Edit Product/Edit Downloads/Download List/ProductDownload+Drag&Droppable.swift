import Foundation
import CoreServices
import Yosemite

extension ProductDownload: NSItemProviderReading, NSItemProviderWriting {
    public static var readableTypeIdentifiersForItemProvider: [String] {
        return [(kUTTypeUTF8PlainText) as String]
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
          //Here we decode the object back to it's class representation and return it
          let counter = try decoder.decode(ProductDownload.self, from: data)
            return counter as! Self
        } catch {
          throw ProductDownloadFileError.decodeFailure
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
            completionHandler(nil, ProductDownloadFileError.encodeFailure)
          }
        return progress
    }
}

enum ProductDownloadFileError: Error {
    case invalidDataType, decodeFailure, encodeFailure
}
