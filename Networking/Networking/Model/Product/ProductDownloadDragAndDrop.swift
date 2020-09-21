import Foundation
import CoreServices

/// A wrapper around `ProductDownload`, to make it compatible in using as Drag and Drop data source in a table view. Represents a `ProductDownload` entity.
/// To make a data draggable and droppable, on an Table/Collection view,
/// the data source object needs to conform to `NSItemProviderReading`
/// and `NSItemProviderWriting` protocol and these 2 protocol again conforms to `NSObjectProtocol`
/// So the top layer object needs to be a subclass of `NSObject`
/// And since the original `ProductDownload` is a struct, we need a new class for this purpose.
///
public final class ProductDownloadDragAndDrop: NSObject, Codable {
    public let downloadableFile: ProductDownload

    /// initializer.
    ///
    public init(downloadableFile: ProductDownload) {
        self.downloadableFile = downloadableFile
        super.init()
    }

    /// Convenience initializer.
    ///
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let download = try container.decode(ProductDownload.self, forKey: .download)
        self.init(downloadableFile: download)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloadableFile, forKey: .download)
    }
}

/// `NSItemProviderWriting` protocol allows a class to export its data to a variety of binary representations.
/// When the cell is dragged, the system takes its data and encode it to a binary form to move that around.
/// Required for making a class Draggable
///
extension ProductDownloadDragAndDrop: NSItemProviderWriting {

    /// Gets called by the system to get information about our encoded data representation while Dragging
    ///
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [(kUTTypeUTF8PlainText) as String]
    }

    public func loadData(withTypeIdentifier typeIdentifier: String,
                         forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
          do {
            //Here the object is encoded to a JSON data object and sent to the completion handler
            let data = try JSONEncoder().encode(self)
              completionHandler(data, nil)
          } catch {
            completionHandler(nil, CodableError.encodeFailure)
          }
        return nil
    }
}

/// `NSItemProviderReading` protocol allows a class to be constructed from a variety of binary representations.
/// When the dragged data is dropped on some places, the encoded binary data needs to be decoded back again into its class representation
/// so that it can be displayed again.
/// Required for making a class Droppable
///
extension ProductDownloadDragAndDrop: NSItemProviderReading {

    /// Represents the encoding and decoding format of the data that we are going to decode while dropping.
    ///  In this case it's kUTTypeUTF8PlainText
    ///
    public static var readableTypeIdentifiersForItemProvider: [String] {
        return [(kUTTypeUTF8PlainText) as String]
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
          //Here we decode the object back to it's class representation and return it
          let counter = try decoder.decode(ProductDownloadDragAndDrop.self, from: data)
            return counter as! Self
        } catch {
          throw CodableError.decodeFailure
        }
    }
}

/// Defines all the `ProductDownloadDragAndDrop` CodingKeys.
///
private extension ProductDownloadDragAndDrop {
    enum CodingKeys: String, CodingKey {
        case download = "download"
    }

    enum CodableError: Error {
        case invalidDataType, decodeFailure, encodeFailure
    }
}
