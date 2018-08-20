//
//  UIView+UIView+DopamineAnimation.swift
//  BoundlessKit
//
//  Created by Akash Desai on 9/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox
import AVFoundation

// call all these in main queue DispatchQueue.main
public extension UIView {

    @objc
    public func showPopover(content: UIImage? = "❤️".image(),
                            duration: TimeInterval = 1.0,
                            style: UIBlurEffectStyle = UIBlurEffectStyle.light,
                            hapticFeedback: Bool = false,
                            systemSound: UInt32 = 0,
                            completion: (() -> Void)? = nil
        ) {
        let blurEffectView = UIVisualEffectView(effect: nil)
        blurEffectView.frame = self.bounds
        blurEffectView.mask = self.generateMask()
        blurEffectView.contentView.alpha = 0

        self.addSubview(blurEffectView)

        let popupView = UIImageView(image: content)
        popupView.center = blurEffectView.center
        popupView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        blurEffectView.contentView.addSubview(popupView)

        UIView.animate(
            withDuration: 0.3,
            animations: {
                BKAudio.play(systemSound, vibrate: hapticFeedback)
                blurEffectView.effect = UIBlurEffect(style: style)
                blurEffectView.contentView.alpha = 1
                popupView.transform = .identity
        },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.7,
                    delay: duration,
                    animations: {
                        popupView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                        blurEffectView.contentView.alpha = 0
                        blurEffectView.effect = nil
                },
                    completion: { _ in
                        blurEffectView.removeFromSuperview()
                        completion?()
                })
        })
    }

    @objc
    public func showEmojiSplosion(at location: CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 0.6,
                                  scaleSpeed: CGFloat = 0.2,
                                  scaleRange: CGFloat = 0.2,
                                  lifetime: Float = 3.0,
                                  lifetimeRange: Float = 0.5,
                                  fadeout: Float = -0.2,
                                  quantity birthRate: Float = 6.0,
                                  bursts birthCycles: Double = 1.0,
                                  velocity: CGFloat = -50,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = -150,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 45,
                                  spin: CGFloat = 0,
                                  hapticFeedback: Bool = false,
                                  systemSound: UInt32 = 0,
                                  completion: (() -> Void)? = nil
        ) {
        guard let content = content else {
            BKLog.debug(error: "Received nil image content!")
            return
        }
        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = location
            emitter.beginTime = CACurrentMediaTime() - 0.9

            let cell = CAEmitterCell()
            cell.contents = content
            cell.birthRate = birthRate
            cell.lifetime = lifetime
            cell.lifetimeRange = lifetimeRange
            cell.spin = spin.degreesToRadians()
            cell.spinRange = cell.spin / 8
            cell.velocity = velocity
            cell.velocityRange = cell.velocity / 3
            cell.xAcceleration = xAcceleration
            cell.yAcceleration = yAcceleration
            cell.scale = scale
            cell.scaleSpeed = scaleSpeed
            cell.scaleRange = scaleRange
            cell.emissionLongitude = angle.degreesToRadians()
            cell.emissionRange = range.degreesToRadians()
            if fadeout > 0 {
                cell.alphaSpeed = -1.0 / fadeout
                cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeout))
            } else if fadeout < 0 { // fadein
                cell.alphaSpeed = 1.0 / -fadeout
                cell.color = cell.color?.copy(alpha: 0)
            }
            emitter.emitterCells = [cell]

            self.layer.addSublayer(emitter)
//            BKLog.debug("💥 Emojisplosion on <\(NSStringFromClass(type(of: self)))> at <\(location)>!")
            BKAudio.play(systemSound, vibrate: hapticFeedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + birthCycles) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(lifetime + lifetimeRange)) {
                    emitter.removeFromSuperlayer()
//                    BKLog.debug("💥 Emojisplosion done")
                    completion?()
                }
            }
        }
    }

    @objc
    public func showShimmy(count: Int = 2, duration: TimeInterval = 5.0, translation: Int = 10, speed: Float = 3, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {

        let path = UIBezierPath()
        path.move(to: .zero)
        for _ in 1...count {
            path.addLine(to: CGPoint(x: translation, y: 0))
            path.addLine(to: CGPoint(x: -translation, y: 0))
        }
        path.close()

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.repeatCount = 1
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.path = path.cgPath
        animation.speed = speed

        CoreAnimationDelegate(didStart: {
            BKAudio.play(systemSound, vibrate: hapticFeedback)
        }, didStop: completion).start(view: self, animation: animation)
    }

    @available(iOS 9.0, *)
    @objc
    public func showPulse(count: Float = 1, duration: TimeInterval = 0.86, scale: CGFloat = 1.4, velocity: CGFloat = 5.0, damping: CGFloat = 2.0, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {

        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.repeatCount = count
        pulse.duration = duration/TimeInterval(pulse.repeatCount)
        pulse.toValue = scale
        pulse.autoreverses = true
        pulse.initialVelocity = velocity
        pulse.damping = damping

        CoreAnimationDelegate(didStop: completion).start(view: self, animation: pulse)
    }

    @objc
    public func showVibrate(vibrateCount: Int = 6, vibrateDuration: TimeInterval = 1.0, vibrateTranslation: Int = 10, vibrateSpeed: Float = 3, scale: CGFloat = 0.8, scaleCount: Float = 1, scaleDuration: TimeInterval = 0.3, scaleVelocity: CGFloat = 20, scaleDamping: CGFloat = 10, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {

        let path = UIBezierPath()
        path.move(to: .zero)
        if vibrateCount >= 1 {
            for _ in 1...vibrateCount {
                path.addLine(to: CGPoint(x: vibrateTranslation, y: 0))
                path.addLine(to: CGPoint(x: -vibrateTranslation, y: 0))
            }
        }
        path.close()

        var animations = [CAAnimation]()

        let vibrateAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        vibrateAnimation.repeatCount = 1
        vibrateAnimation.duration = vibrateDuration / TimeInterval(vibrateAnimation.repeatCount)
        vibrateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        vibrateAnimation.path = path.cgPath
        vibrateAnimation.speed = vibrateSpeed
        animations.append(vibrateAnimation)

        if #available(iOS 9.0, *) {
            let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
            scaleAnimation.repeatCount = scaleCount > 0 ? scaleCount : 1
            scaleAnimation.duration = scaleDuration / TimeInterval(scaleAnimation.repeatCount)
            scaleAnimation.toValue = scaleCount > 0 ? scale : 1
            scaleAnimation.autoreverses = true
            scaleAnimation.initialVelocity = scaleVelocity
            scaleAnimation.damping = scaleDamping
            animations.append(vibrateAnimation)
        }

        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = max(vibrateDuration, scaleDuration)

        CoreAnimationDelegate(willStart: {startAnimation in
            startAnimation()
        }, didStart: {
            BKAudio.play(systemSound, vibrate: hapticFeedback)
        }, didStop: {
            completion?()
        }).start(view: self, animation: group)
    }

    @objc
    public func rotate360Degrees(count: Float = 2, duration: CFTimeInterval = 1.0, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.duration = duration
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = 2.0 * Float.pi * count
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

        CoreAnimationDelegate(
            didStart: {
                BKAudio.play(systemSound, vibrate: hapticFeedback)
        }, didStop: completion).start(view: self, animation: rotateAnimation)
    }

    @objc
    public func showGlow(count: Float = 2, duration: Double = 3.0, color: UIColor = UIColor(red: 255/255.0, green: 26/255.0, blue: 251/255.0, alpha: 0.7), alpha: CGFloat = 0.7, timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {

        let glowView = self.generateMask(color: color)
        glowView.alpha = 0

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = alpha
        animation.repeatCount = count
        animation.duration = duration/TimeInterval(count*2)
        animation.autoreverses = true
        animation.timingFunction = timingFunction

        CoreAnimationDelegate(
            willStart: { start in
                self.addSubview(glowView)
                start()
        },
            didStart: {
                BKAudio.play(systemSound, vibrate: hapticFeedback)
        },
            didStop: {
                glowView.removeFromSuperview()
                completion?()
        }).start(view: glowView, animation: animation)
    }

    @objc
    public func showSheen(duration: Double = 2.0, color: UIColor? = nil, heightMultiplier: CGFloat = 1, widthMultiplier: CGFloat = 1.667, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (() -> Void)? = nil) {
        guard let bundle = Bundle.boundlessKit,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) else {
                BKLog.debug(error: "Could not find sheen image asset")
                return
        }

        if let color = color {
            image = image.tint(tintColor: color)
        }
        let imageView = UIImageView(image: image)
        let height = self.frame.height * heightMultiplier
        let width: CGFloat =  self.frame.height * widthMultiplier
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)

        let containerView = UIImageView(frame: CGRect(origin: .zero, size: self.bounds.size))
        containerView.mask = self.generateMask()
        containerView.addSubview(imageView)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false

        CoreAnimationDelegate(
            willStart: { start in
                self.addSubview(containerView)
                start()
        },
            didStart: {
                BKAudio.play(systemSound, vibrate: hapticFeedback)
        },
            didStop: {
                containerView.removeFromSuperview()
                completion?()
        }).start(view: imageView, animation: animation)
    }
}

private class CoreAnimationDelegate: NSObject, CAAnimationDelegate {
    let willStart: (@escaping()->Void)->Void
    let didStart: (() -> Void)?
    let didStop: (() -> Void)?

    init(willStart: @escaping (@escaping()->Void)->Void = {startAnimation in startAnimation()}, didStart: (() -> Void)? = nil, didStop: (() -> Void)? = nil) {
        self.willStart = willStart
        self.didStart = didStart
        self.didStop = didStop
    }

    func start(view: UIView, animation: CAAnimation) {
        willStart {
            animation.delegate = self
            view.layer.add(animation, forKey: nil)
        }
    }

    func animationDidStart(_ anim: CAAnimation) {
        didStart?()
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            didStop?()
        }
    }
}
