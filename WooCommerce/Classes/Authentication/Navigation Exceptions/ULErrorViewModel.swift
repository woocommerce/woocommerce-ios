import UIKit

protocol ULErrorViewModel {
    var image: UIImage { get }
    var text: NSAttributedString { get }
    var isAuxiliaryButtonVisible: Bool { get }
    var auxiliaryButtonTitle: String { get }
    var primaryButtonTitle: String { get }
    var secondaryButtonTitle: String { get }

    func didTapPrimaryButton(in viewController: UIViewController?)
    func didTapSecondaryButton(in viewController: UIViewController?)
    func didTapAuxiliaryButton(in viewController: UIViewController?)
}
