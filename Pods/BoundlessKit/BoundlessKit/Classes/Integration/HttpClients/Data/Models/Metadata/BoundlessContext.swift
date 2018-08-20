//
//  BoundlessContext.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal class BoundlessContext: NSObject {
    static var locationEnabled = false

    static let queue = DispatchQueue(label: NSStringFromClass(BoundlessContext.self), attributes: .concurrent)

    class func getContext(completion:@escaping([String: Any]) -> Void) {
        queue.async {
            var context = [String: Any]()
            let group = DispatchGroup()

            if locationEnabled {
                group.enter()
                BoundlessLocation.shared.getLocation { locationInfo in
                    if let locationInfo = locationInfo {
                        context["locationInfo"] = locationInfo
                    }
                    group.leave()
                }
            }

            group.notify(queue: DispatchQueue.global()) {
                completion(context)
            }
        }
    }
}

import CoreLocation
private class BoundlessLocation: NSObject {
    public static let shared = BoundlessLocation()

    private var locationManager: CLLocationManager?
    private var enabled: Bool = false
    private var current: CLLocation?
    private var expiresAt = Date()
    public var timeAccuracy: TimeInterval = 30 //seconds

    private var queue = OperationQueue()

    private override init() {
        super.init()
        guard let infoPlist = Bundle.main.infoDictionary,
            infoPlist["NSLocationWhenInUseUsageDescription"] != nil || infoPlist["NSLocationAlwaysAndWhenInUseUsageDescription"] != nil || infoPlist["NSLocationAlwaysUsageDescription"] != nil else {
                return
        }
        enabled = true
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }
    }

    public func getLocation(callback: @escaping ([String: Any]?)->Void) {
        if !enabled {
            callback(nil)
        } else if Date() < expiresAt {
            callback(locationInfo)
        } else {
            if !self.queue.isSuspended {
                self.queue.isSuspended = true
                DispatchQueue.main.async {
                    self.locationManager?.startUpdatingLocation()
                }
            }
            self.queue.addOperation {
                callback(self.locationInfo)
            }
        }
    }

    private var locationInfo: [String: Any]? {
        get {
            if let lastLocation = self.current {
                let utc = Int64(1000*lastLocation.timestamp.timeIntervalSince1970)
                let timezoneOffset = Int64(1000*NSTimeZone.default.secondsFromGMT())
                let localTime = utc + timezoneOffset
                var locationInfo: [String: Any] = ["utc": utc,
                                                   "timezoneOffset": timezoneOffset,
                                                   "localTime": localTime,
                                                   "latitude": lastLocation.coordinate.latitude,
                                                   "horizontalAccuracy": lastLocation.horizontalAccuracy,
                                                   "longitude": lastLocation.coordinate.longitude,
                                                   "verticalAccuracy": lastLocation.verticalAccuracy,
                                                   "altitude": lastLocation.altitude,
                                                   "speed": lastLocation.speed,
                                                   "course": lastLocation.course
                ]
                if let floor = lastLocation.floor?.level {
                    locationInfo["floor"] = floor
                }
                return locationInfo
            } else {
                return nil
            }
        }
    }
}

extension BoundlessLocation: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        enabled = (status == .authorizedAlways || status == .authorizedWhenInUse)
        queue.isSuspended = false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager?.stopUpdatingLocation()
        expiresAt = Date().addingTimeInterval(timeAccuracy)
        if let location = locations.last {
            current = location
        }
        queue.isSuspended = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        enabled = false
        queue.isSuspended = false
    }
}
