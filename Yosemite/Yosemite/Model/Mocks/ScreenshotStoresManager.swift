import Foundation
import Storage

public final class ScreenshotStoresManager: MockStoresManager {
    public init(storageManager: StorageManagerType) {
        super.init(objectGraph: ScreenshotObjectGraph(), storageManager: storageManager)
    }
}
