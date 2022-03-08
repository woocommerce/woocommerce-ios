import UIKit
import WordPressShared

class LoginProloguePageViewController: UIPageViewController {
    @objc var pages: [UIViewController] = []
    fileprivate var pageControl: UIPageControl?
    fileprivate var bgAnimation: UIViewPropertyAnimator?
    fileprivate struct Constants {
        static let pagerPadding: CGFloat = 9.0
        static let pagerHeight: CGFloat = 0.13
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        // During the Lottie and related view controllers and portions of view controllers, removal,
        // the previous version of this code, without the array length check, crashed in the
        // WooCommerce UI tests.
        //
        // I believe the reason is that the views and flows in this library haven't properly been
        // updated to reflect the simplification in the UX and there are still elements that
        // require this class to exist and be instantiated, even though it might not be used
        // directly.
        if pages.isEmpty == false {
            setViewControllers([pages[0]], direction: .forward, animated: false)
        }
        view.backgroundColor = WordPressAuthenticator.shared.style.prologueBackgroundColor

        addPageControl()
    }

    @objc func addPageControl() {
        let newControl = UIPageControl()

        newControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newControl)

        newControl.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.pagerPadding).isActive = true
        newControl.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        newControl.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        newControl.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Constants.pagerHeight).isActive = true

        newControl.numberOfPages = pages.count
        newControl.addTarget(self, action: #selector(handlePageControlValueChanged(sender:)), for: .valueChanged)
        pageControl = newControl
    }

    @objc func handlePageControlValueChanged(sender: UIPageControl) {
        guard let currentPage = viewControllers?.first,
            let currentIndex = pages.firstIndex(of: currentPage) else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = sender.currentPage > currentIndex ? .forward : .reverse
        setViewControllers([pages[sender.currentPage]], direction: direction, animated: true)
        WordPressAuthenticator.track(.loginProloguePaged)
    }
}

extension LoginProloguePageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        if index > 0 {
            return pages[index - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        if index < pages.count - 1 {
            return pages[index + 1]
        }
        return nil
    }
}

extension LoginProloguePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let toVC = previousViewControllers[0]
        guard let index = pages.firstIndex(of: toVC) else {
            return
        }
        if !completed {
            pageControl?.currentPage = index
        } else {
            WordPressAuthenticator.track(.loginProloguePaged)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let toVC = pendingViewControllers[0]
        guard let index = pages.firstIndex(of: toVC) else {
            return
        }
        pageControl?.currentPage = index
    }
}
