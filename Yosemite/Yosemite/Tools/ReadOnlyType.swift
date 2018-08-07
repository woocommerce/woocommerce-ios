import Foundation
import Storage


//
//
public protocol ReadOnlyType {

    ///
    ///
    func isReadOnlyRepresentation(of storageEntity: Any) -> Bool
}
