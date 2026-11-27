import Photos
import UIKit

public protocol ExportableAsset: Sendable {}

extension PHAsset: ExportableAsset {}

extension UIImage: ExportableAsset {}
