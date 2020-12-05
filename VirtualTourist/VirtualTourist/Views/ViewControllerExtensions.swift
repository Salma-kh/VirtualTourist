//
//  ViewControllerExtensions.swift
//  VirtualTourist
//
//  Created by salma apple on 1/23/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//

import UIKit

extension UIViewController {
    func save() {
        do {
            try CoreData.shared().saveContext()
        } catch {
            displayInfo(Title: "Error", Message: "Error while saving Pin location: \(error)")
        }
    }
    func displayInfo(Title: String = "Info", Message: String, action: (() -> Void)? = nil) {
        UIUpdates {
            let actions = UIAlertController(title: Title, message: Message, preferredStyle: .alert)
            actions.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(actions, animated: true)
        }
    }
    
    func UIUpdates(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
}
