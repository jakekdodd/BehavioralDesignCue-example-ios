//
//  StringExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

public extension NSString {
    @objc
    func utf8Decoded() -> NSString {
        if let data = self.data(using: String.Encoding.utf8.rawValue),
            let str = NSString(data: data, encoding: String.Encoding.nonLossyASCII.rawValue) {
            return str as NSString
        } else {
            return self
        }
    }

    @objc
    func image() -> UIImage {
        return image(font: .systemFont(ofSize: 24))
    }

    @objc
    func image(font: UIFont) -> UIImage {
        let size = self.size(withAttributes: [NSAttributedStringKey.font: font])
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(at: .zero, withAttributes: [NSAttributedStringKey.font: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
