import Foundation
import Storage


//
//
public protocol ReadOnlyRepresentation {

    ///
    ///
    func isReadOnlyRepresentation(of storageEntity: Any) -> Bool
}
