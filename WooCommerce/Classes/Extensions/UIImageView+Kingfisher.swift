import UIKit
import Kingfisher

/// Wrapper Extension for Kingfisher
///
extension UIImageView {

    typealias ImageDownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)
    typealias ImageDownloadResultBlock = ((_ success: Bool) -> Void)

    // Base method to download and cache images
    //
    func setImage(
        with url: String?,
        placeholder: UIImage? = nil,
        progressBlock: ImageDownloadProgressBlock? = nil,
        completionHandler: ImageDownloadResultBlock? = nil) {

        let url = URL(string: url ?? "")
        kf.setImage(with: url, placeholder: placeholder, progressBlock: progressBlock) { (result) in
            switch result {
            case .success:
                completionHandler?(true)
                break
            case .failure:
                completionHandler?(false)
                break
            }
        }
    }

}
