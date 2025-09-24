//
//  UIViewController+displayMessage.swift
//  FIT3178-final-app
//
//  Created by Viet Tran on 24/9/2025.
//

import UIKit

//Extensions in Swift allow us to add new functionality to existing classes. We can create
//extensions for our own classes (e.g., custom View Controllers) or existing UIKit classes!
extension UIViewController {
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message,
         preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,
         handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

