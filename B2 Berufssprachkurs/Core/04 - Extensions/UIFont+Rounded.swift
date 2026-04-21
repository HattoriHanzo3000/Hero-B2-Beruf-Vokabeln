//
//  UIFont+Rounded.swift
//  B2 Berufssprachkurs
//
//  System rounded font for UIKit chrome.
//  Created: 18.11.25.
//

import UIKit

extension UIFont {
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: roundedDescriptor, size: size)
    }
}
