//
//  CGExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension CGImage {
    func blurImage(radius: Int) -> CGImage {
        guard radius != 0 else {
            return self
        }
        let imageToBlur = CIImage(cgImage: self)
        let blurfilter = CIFilter(name: "CIGaussianBlur")!
        blurfilter.setValue(radius, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.value(forKey: kCIOutputImageKey) as! CIImage

        let context = CIContext(options: nil)
        return context.createCGImage(resultImage, from: resultImage.extent)!
    }
}

internal extension CGFloat {
    func degreesToRadians() -> CGFloat {
        return self / 180 * .pi
    }

    init(degrees: CGFloat) {
        self = degrees.degreesToRadians()
    }
}

internal extension CGPoint {
    func withMargins(marginX: CGFloat, marginY: CGFloat) -> CGPoint {
        return CGPoint(x: x + marginX, y: y + marginY)
    }
}
