import UIKit

/// A cell which allows embedding a `ListSelectorViewController`, which will appear inside another table view
///
class ContainerListSelectorTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    
    private var embeddedViewController: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(presenterViewController: UIViewController, embeddedViewController: UIViewController) {
        self.embeddedViewController = embeddedViewController
        
        if let childVC = self.embeddedViewController {
            presenterViewController.addChild(childVC)
            containerView.addSubview(childVC.view)
            childVC.didMove(toParent: presenterViewController)
            
            cellHeightConstraint.constant = childVC.view.frame.height
            
            NSLayoutConstraint.activate([
            childVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            childVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            //childVC.view.translatesAutoresizingMaskIntoConstraints = false
        }
        
    }
}
