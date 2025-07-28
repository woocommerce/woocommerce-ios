import Photos
import UIKit

public protocol ExportableAsset {}

extension PHAsset: ExportableAsset {}

extension UIImage: ExportableAsset {}
