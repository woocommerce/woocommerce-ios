import Foundation
import Storage

public final class ScreenshotStoresManager: MockStoresManager {
    public init(storageManager: any StorageManagerType & Sendable) {
        super.init(objectGraph: ScreenshotObjectGraph(), storageManager: storageManager)
    }
}
