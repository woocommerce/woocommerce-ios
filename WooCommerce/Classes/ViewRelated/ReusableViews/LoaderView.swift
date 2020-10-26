import UIKit

// LoaderView with view size, with indicator placed on center of loaderView
extension UIViewController {

    func showLoader(view: UIView) -> UIView {
        let loadingView = UIView(frame: view.bounds)
        let indicator: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicator.center = loadingView.center
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        loadingView.pinSubviewAtCenter(indicator)
        view.addSubview(loadingView)
        view.pinSubviewToAllEdges(loadingView)
        loadingView.bringSubviewToFront(view)
        return loadingView
    }

    func hideLoader(loadingView: UIView?) {
        loadingView?.fadeOut { _ in
            loadingView?.removeFromSuperview()
        }
    }
}
