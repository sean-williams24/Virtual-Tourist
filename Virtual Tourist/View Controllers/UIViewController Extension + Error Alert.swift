//
//  UIViewController Extension + Error Alert.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 17/09/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showErrorAlert(title: String, error: String) {
        let ac = UIAlertController(title: title, message: error, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
}
