import UIKit
import Yosemite
import Lottie


class LottieTestViewController: UIViewController {

    @IBOutlet weak var animationView: AnimationView!

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let starAnimation = Animation.named("prologue-stats")
        animationView.animation = starAnimation
        animationView.play { (finished) in
          /// Animation finished
        }

    }



}
