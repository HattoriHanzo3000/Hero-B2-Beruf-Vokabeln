//
//  UIFont+Rounded.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import UIKit

extension UIFont {
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded)
        return UIFont(descriptor: descriptor ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor, size: size)
    }
}



