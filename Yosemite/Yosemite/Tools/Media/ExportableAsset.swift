import Photos

public protocol ExportableAsset {}

extension PHAsset: ExportableAsset {}

extension UIImage: ExportableAsset {}
