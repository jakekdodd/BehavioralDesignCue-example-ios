//
//  BoundlessAPIClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/13/18.
//

import Foundation

internal enum BoundlessAPIEndpoint {
    case track, report, refresh,
            boot, identify, accept, submit

    var url: URL! { return URL(string: path)! }

    var path: String { switch self {
    case .track: return "https://reinforce.boundless.ai/v6/app/track/"
    case .report: return "https://reinforce.boundless.ai/v6/app/report/"
    case .refresh: return "https://reinforce.boundless.ai/v6/app/refresh/"

    case .boot: return "https://reinforce.boundless.ai/v6/app/boot"
    case .identify: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/identity/"
    case .accept: return "https://dashboard-api.usedopamine.com/codeless/pair/customer/accept/"
    case .submit: return "https://dashboard-api.usedopamine.com/codeless/visualizer/customer/submit/"
        }
    }
}

internal protocol BoundlessAPISynchronizable: class {
    var needsSync: Bool { get }
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool?) -> Void)
}

internal class BoundlessAPIClient: HTTPClient {

    internal var credentials: BoundlessCredentials
    internal var version: BoundlessVersion {
        didSet {
            database.set(version.encode(), forKey: "boundlessVersion")
            didSetVersion(oldValue: oldValue)
        }
    }
    internal var config: BoundlessConfiguration {
        didSet {
            database.set(config.encode(), forKey: "boundlessConfig")
            didSetConfiguration(oldValue: oldValue)
        }
    }
    fileprivate var visualizerSession: BoundlessVisualizerSession? {
        didSet {
            database.set(visualizerSession?.encode(), forKey: "boundlessVisualizer")
            didSetVisualizerSession(oldValue: oldValue)
        }
    }
    internal var database: BKUserDefaults = BKUserDefaults.standard

    var reinforcers = [String: Reinforcer]()

    let lock = NSRecursiveLock()
    let coordinationQueue = DispatchQueue(label: "boundless.kit.api")
    var timeDelayAfterTrack: UInt32 = 1
    var timeDelayAfterReport: UInt32 = 5
    var timeDelayAfterRefresh: UInt32 = 3

    init(properties: BoundlessProperties, session: URLSessionProtocol = URLSession.shared) {
        self.credentials = properties.credentials

        if let versionData = database.object(forKey: "boundlessVersion") as? Data,
            let version = BoundlessVersion(data: versionData, database: database) {
            self.version = version
        } else {
            self.version = properties.version
        }

        if let configData = database.object(forKey: "boundlessConfig") as? Data,
            let config = BoundlessConfiguration(data: configData) {
            self.config = config
        } else {
            self.config = BoundlessConfiguration()
        }

        if let sessionData = database.object(forKey: "boundlessVisualizer") as? Data,
            let savedSession = BoundlessVisualizerSession(data: sessionData) {
            self.visualizerSession = savedSession
        } else {
            self.visualizerSession = nil
        }

        super.init(session: session)

        didSetConfiguration(oldValue: nil)
        didSetVisualizerSession(oldValue: nil)
        didSetVersion(oldValue: nil)
    }

    func set(customUserIdentifier id: String?, completion: ((String?, String?) -> Void)? = nil) {
        let oldId = credentials.user.set(customId: id)

        if oldId == credentials.user.id {
            completion?(credentials.user.id, credentials.user.experimentGroup)
        } else {
            if oldId != nil {
                version.trackBatch.clear()
                version.reportBatch.clear()
                version.refreshContainer.clear()
            }
            boot {
                completion?(self.credentials.user.id, self.credentials.user.experimentGroup)
            }
        }
    }

    func commit(_ action: BKAction) {
        version.trackBatch.add(action)
    }

    func commit(_ reinforcement: BKReinforcement) {
        version.reportBatch.add(reinforcement)
    }

    func remove(decisionFor actionId: String) -> BKDecision {
        guard credentials.user.validId else { return BKDecision.neutral(for: actionId) }
        return version.refreshContainer.decision(forActionID: actionId)
    }

    func synchronize(successful: @escaping (Bool) -> Void = {_ in}) {
        coordinationQueue.async {
            guard self.lock.try() else {
                successful(false)
                return
            }
            defer { self.lock.unlock() }

            guard self.credentials.user.validId && (self.version.refreshContainer.needsSync || self.version.reportBatch.needsSync || self.version.trackBatch.needsSync) else {
                successful(true)
                return
            }

            BKLog.debug("Starting api synchronization...")
            let sema = DispatchSemaphore(value: 0)
            var lastSuccess: Bool?
            var goodProgress = true
            defer {
                BKLog.debug("Finished api synchronization.")
                successful(goodProgress)
            }

            self.version.trackBatch.synchronize(with: self) { success in
                lastSuccess = success
                sema.signal()
            }
            guard sema.wait(timeout: .now() + 3) == .success else { return }

            if let lastSuccess = lastSuccess {
                goodProgress = goodProgress && lastSuccess
                if goodProgress {
                    sleep(self.timeDelayAfterTrack)
                } else {
                    return
                }
            }

            self.version.reportBatch.synchronize(with: self) { success in
                lastSuccess = success
                sema.signal()
            }
            guard sema.wait(timeout: .now() + 3) == .success else { return }

            if let lastSuccess = lastSuccess {
                goodProgress = goodProgress && lastSuccess
                if goodProgress {
                    sleep(self.timeDelayAfterReport)
                } else {
                    return
                }
            }

            self.version.refreshContainer.synchronize(with: self) { success in
                lastSuccess = success
                sema.signal()
            }
            guard sema.wait(timeout: .now() + 3) == .success else { return }

            if let lastSuccess = lastSuccess {
                goodProgress = goodProgress && lastSuccess
                if goodProgress {
                    sleep(self.timeDelayAfterRefresh)
                } else {
                    return
                }
            }
        }
    }

    func boot(completion: @escaping () -> Void = {}) {
        let initialBoot = (version.database.initialBootDate == nil)
        var payload = credentials.json
        payload["inProduction"] = credentials.inProduction
        payload["currentVersion"] = version.name ?? "nil"
        payload["currentConfig"] = config.configID ?? "nil"
        payload["initialBoot"] = initialBoot
        post(url: BoundlessAPIEndpoint.boot.url, jsonObject: payload) { response in
            self.confirmBoot()
            if let status = response?["status"] as? Int {
                if status == 205 {
                    if let configDict = response?["config"] as? [String: Any],
                        let config = BoundlessConfiguration.convert(from: configDict) {
                        self.config = config
                    }
                    if let versionDict = response?["version"] as? [String: Any],
                        let newVersion = BoundlessVersion.convert(from: versionDict, database: self.version.database) {
                        newVersion.reportBatch.clear()
                        newVersion.refreshContainer.clear()
                        self.version = newVersion
                    }
                }

                self.version.refreshContainer.synchronize(with: self)
            }
            completion()
            }.start()
    }

    fileprivate let serialQueue = DispatchQueue(label: "CodelessAPIClientSerial")
    fileprivate let concurrentQueue = DispatchQueue(label: "CodelessAPIClientConcurrent", attributes: .concurrent)
}

//// Adhering to BoundlessConfiguration
//
//
fileprivate extension BoundlessAPIClient {
    func didSetConfiguration(oldValue: BoundlessConfiguration?) {
        let newValue = config

        self.version.refreshContainer.enabled = newValue.reinforcementEnabled
        self.version.reportBatch.enabled = newValue.reinforcementEnabled
        self.version.trackBatch.enabled = newValue.trackingEnabled
        self.version.reportBatch.desiredMaxCountUntilSync = newValue.reportBatchSize
        self.version.trackBatch.desiredMaxCountUntilSync = newValue.trackBatchSize

        BoundlessContext.locationEnabled = newValue.locationObservations
        BKLog.preferences.printEnabled = newValue.consoleLoggingEnabled

        if (oldValue?.applicationState != newValue.applicationState || oldValue?.trackingEnabled != newValue.trackingEnabled) {
            if (newValue.trackingEnabled && newValue.applicationState) {
                NotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationState(_:)), names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, names: [.UIApplicationDidBecomeActive, .UIApplicationWillResignActive], object: nil)
            }
        }

        if (oldValue?.applicationViews != newValue.applicationViews || oldValue?.trackingEnabled != newValue.trackingEnabled) {
            if (newValue.trackingEnabled && newValue.applicationViews) {
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(self.trackApplicationViews(_:)), names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
            } else {
                BoundlessNotificationCenter.default.removeObserver(self, names: [.UIViewControllerDidAppear, .UIViewControllerDidDisappear], object: nil)
            }
        }

    }

    @objc func trackApplicationState(_ notification: Notification) {
        let tag = "ApplicationState"
        let actionID: String
        var metadata: [String: Any] = ["tag": tag]

        switch notification.name {
        case Notification.Name.UIApplicationDidBecomeActive:
            actionID = "UIApplicationDidBecomeActive"
            metadata["time"] = BoundlessTime.start(for: self, tag: tag)

        case Notification.Name.UIApplicationWillResignActive:
            actionID = "UIApplicationWillResignActive"
            metadata["time"] = BoundlessTime.end(for: self, tag: tag)

        default:
            return
        }

        commit(BKAction(actionID, metadata))
    }

    @objc func trackApplicationViews(_ notification: Notification) {
        if let target = notification.userInfo?["target"] as? NSObject,
            let selector = notification.userInfo?["selector"] as? Selector {
            let tag = "ApplicationView"
            let actionID = "\(NSStringFromClass(type(of: target)))-\(NSStringFromSelector(selector))"
            var metadata: [String: Any] = ["tag": tag]

            switch selector {
            case #selector(UIViewController.viewDidAppear(_:)):
                metadata["time"] = BoundlessTime.start(for: target)

            case #selector(UIViewController.viewDidDisappear(_:)):
                metadata["time"] = BoundlessTime.end(for: target)

            default:
                return
            }

            commit(BKAction(actionID, metadata))
        }
    }
}

//// Translate Action-Reward Mappings to Reinforcers
//
//
fileprivate extension BoundlessAPIClient {
    func didSetVersion(oldValue: BoundlessVersion?) {
        if oldValue?.name != version.name {
            mountVersion()
        }
    }

    func mountVersion() {
        serialQueue.async {
            var mappings: [String: [String: Any]] = self.config.reinforcementEnabled ? {
                var mappings = self.version.mappings
                if let visualizer = self.visualizerSession {
                    for (actionID, value) in visualizer.mappings {
                        mappings[actionID] = value
                    }
                }
                return mappings
                }() : [:]

            for (actionID, value) in mappings {
                var reinforcer: Reinforcer = {
                    self.reinforcers[actionID]?.reinforcementIDs = []
                    return self.reinforcers[actionID]
                    }() ?? {
                        let reinforcer = Reinforcer(forActionID: actionID)
                        self.reinforcers[actionID] = reinforcer
                        return reinforcer
                    }()

                if self.config.integrationMethod == "manual" {
                    if let manual = value["manual"] as? [String: Any],
                        let reinforcements = manual["reinforcements"] as? [String],
                        !reinforcements.isEmpty {
                        // BKLog.debug("Manual reinforcement found for actionID <\(actionID)>")
                        reinforcer.reinforcementIDs.append(contentsOf: reinforcements)
                    }
                } else if self.config.integrationMethod == "codeless" {
                    if let codeless = value["codeless"] as? [String: Any],
                        let reinforcements = codeless["reinforcements"] as? [[String: Any]],
                        !reinforcements.isEmpty {
                        let codelessReinforcer: CodelessReinforcer = reinforcer as? CodelessReinforcer ?? {
                            let codelessReinforcer = CodelessReinforcer(copy: reinforcer)
                            BoundlessNotificationCenter.default.addObserver(codelessReinforcer, selector: #selector(codelessReinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                            reinforcer = codelessReinforcer
                            self.reinforcers[actionID] = codelessReinforcer
                            return codelessReinforcer
                            }()
                        // BKLog.debug("Codeless reinforcement found for actionID <\(actionID)>")
                        for reinforcementDict in reinforcements {
                            if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                                codelessReinforcer.codelessReinforcements[codelessReinforcement.primitive] = codelessReinforcement
                            }
                        }
                    }
                }
            }

            for (actionID, value) in self.reinforcers.filter({mappings[$0.key] == nil}) {
                if value is CodelessReinforcer {
                    BoundlessNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
                }
                self.reinforcers.removeValue(forKey: actionID)
            }
        }
    }
}

//// Dashboard Visualizer Connection
//
//
extension BoundlessAPIClient {
    fileprivate func didSetVisualizerSession(oldValue: BoundlessVisualizerSession?) {
        serialQueue.async {
            if oldValue == nil && self.visualizerSession != nil {
                Reinforcer.scheduleSetting = .random
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(BoundlessAPIClient.doNothing(notification:)), names: .visualizerNotifications, object: nil)
                // listen for all notifications since notification names not known prior
                BoundlessNotificationCenter.default.addObserver(self, selector: #selector(BoundlessAPIClient.submitToDashboard(notification:)), name: nil, object: nil)
            } else if oldValue != nil && self.visualizerSession == nil {
                Reinforcer.scheduleSetting = .reinforcement
                BoundlessNotificationCenter.default.removeObserver(self)
            }
        }
    }

    func confirmBoot() {
        guard !credentials.inProduction && config.integrationMethod == "codeless" else {
            return
        }
        var payload = credentials.json
        payload["deviceName"] = UIDevice.current.name
        payload["appID"] = payload["appId"]

        post(url: BoundlessAPIEndpoint.identify.url, jsonObject: payload) { response in
            guard let response = response else { return }

            switch response["status"] as? Int {
            case 202?:
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    self.confirmBoot()
                }
                break

            case 200?:
                guard let adminName = response["adminName"] as? String,
                    let connectionUUID = response["connectionUUID"] as? String else {
                        self.visualizerSession = nil
                        return
                }

                let pairingAlert = UIAlertController(title: "Visualizer Pairing", message: "Accept pairing request from \(adminName)?", preferredStyle: UIAlertControllerStyle.alert)
                pairingAlert.addAction( UIAlertAction( title: "Yes", style: .default, handler: { _ in
                    payload["connectionUUID"] = connectionUUID
                    self.post(url: BoundlessAPIEndpoint.accept.url, jsonObject: payload) { response in
                        if response?["status"] as? Int == 200 {
                            self.visualizerSession = BoundlessVisualizerSession(connectionUUID: connectionUUID, mappings: [:])
                        } else {
                            self.visualizerSession = nil
                        }
                    }.start()
                }))
                pairingAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
                    self.visualizerSession = nil
                }))
                UIWindow.presentTopLevelAlert(alertController: pairingAlert)

            case 208?:
                if let reconnectedSession = BoundlessVisualizerSession.convert(from: response) {
                    self.visualizerSession = reconnectedSession
                    self.submitToDashboard(actionID: Notification.Name.CodelessUIApplicationDidBecomeActive)
                    self.submitToDashboard(actionID: Notification.Name.CodelessUIApplicationDidFinishLaunching)
                }
                //                else { // /identity endpoint gives back wrongly-formatted visualizer mapping
                //                    self.visualizerSession = nil
                //                }

            default:
                self.visualizerSession = nil
            }
            }.start()
    }

    @objc
    func submitToDashboard(notification: Notification) {
        serialQueue.async {
            guard let session = self.visualizerSession,
                let targetClass = notification.userInfo?["classType"] as? AnyClass,
                let selector = notification.userInfo?["selector"] as? Selector else {
                    BKLog.debug("Failed to send notification <\(notification.name.rawValue)> to dashboard")
                    return
            }
            let sender = notification.userInfo?["sender"] as AnyObject
            let actionID = notification.name.rawValue

            var payload = self.credentials.json
            payload["versionId"] = self.version.name
            payload["connectionUUID"] = session.connectionUUID
            payload["sender"] = (type(of: sender) == NSNull.self) ? "nil" : NSStringFromClass(type(of: sender))
            payload["target"] = NSStringFromClass(targetClass)
            payload["selector"] = NSStringFromSelector(selector)
            payload["actionID"] = actionID
            payload["senderImage"] = ""
            let sema = DispatchSemaphore(value: 0)
            self.post(url: BoundlessAPIEndpoint.submit.url, jsonObject: payload) { response in
                defer { sema.signal() }
                guard response?["status"] as? Int == 200 else {
                    DispatchQueue.global().async {
                        self.visualizerSession = nil
                    }
                    return
                }
                BKLog.print("Sent to dashboard actionID:<\(actionID)>")
                if let visualizerMappings = response?["mappings"] as? [String: [String: Any]] {
                    DispatchQueue.global().async {
                        self.visualizerSession?.mappings = visualizerMappings
                        self.mountVersion()
                    }
                }
                }.start()
            _ = sema.wait(timeout: .now() + 2)
        }
    }

    @objc
    func doNothing(notification: Notification) {
        BKLog.debug("Got notification:\(notification.name.rawValue) ")
    }
}

extension BoundlessAPIClient {
    func submitToDashboard(actionID: String) {
        var components = actionID.components(separatedBy: "-")
        if components.count == 2 {
            let target = components.removeFirst()
            let selector = components.removeFirst()
            var payload = self.credentials.json
            payload["versionId"] = self.version.name
            payload["connectionUUID"] = self.visualizerSession?.connectionUUID
            payload["target"] = target
            payload["selector"] = selector
            payload["actionID"] = actionID
            payload["senderImage"] = ""
            self.post(url: BoundlessAPIEndpoint.submit.url, jsonObject: payload) {_ in}.start()
        }
    }
}

private  struct BoundlessVisualizerSession {
    let connectionUUID: String
    var mappings: [String: [String: Any]]

    init(connectionUUID: String, mappings: [String: [String: Any]]) {
        self.connectionUUID = connectionUUID
        self.mappings = mappings
    }

    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let connectionUUID = unarchiver.decodeObject(forKey: "connectionUUID") as? String else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String: Any]] else { return nil }
        self.init(connectionUUID: connectionUUID, mappings: mappings)
    }

    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(connectionUUID, forKey: "connectionUUID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }

    static func convert(from dict: [String: Any]) -> BoundlessVisualizerSession? {
        guard let connectionUUID = dict["connectionUUID"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }

        return BoundlessVisualizerSession(connectionUUID: connectionUUID, mappings: dict["mappings"] as? [String: [String: Any]] ?? [:])
    }
}
