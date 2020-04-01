//
//  ContainerTableViewCell.swift
//  WooCommerce
//
//  Created by Paolo Musolino on 01/04/2020.
//  Copyright © 2020 Automattic. All rights reserved.
//

import UIKit

class ContainerTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    
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
            
            NSLayoutConstraint.activate([
            childVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            childVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            childVC.view.heightAnchor.constraint(equalToConstant: 400)
            ])
            
            //childVC.view.translatesAutoresizingMaskIntoConstraints = false
            
    
        }
        
    }
}
