//
//  DataViewController.swift
//
//  Created by Akash Desai on 8/6/18.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import UIKit
import UserNotifications

class DataViewController: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    var dataObject: String = ""

    @IBOutlet weak var logView: UITextView!
    var logObject: String {
        get {
            return Helper.shared.logObject
        }
        set {
            Helper.shared.logObject = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateViews),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataLabel!.text = dataObject
        self.logView.text = logObject
    }

    @objc func updateViews() {
        DispatchQueue.main.async {
            self.logView.text = self.logObject
            if !self.logView.text.isEmpty {
                self.logView.scrollRangeToVisible(NSRange(location: self.logView.text.count - 1, length: 0))
            }
        }
    }

    @IBAction func copyDeepLinkURL(_ sender: Any) {
        var message: String
        if let scheme = Bundle.main.externalURLScheme {
            message = "Copied URL! Go into safari and paste in address bar."
            UIPasteboard.general.string = scheme + "://" + dataObject
        } else {
            message = "Could not find external url scheme."
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        self.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
                alert.dismiss(animated: true)
            }
        }
    }

    @IBAction func scheduleNotification(_ sender: Any) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestPermission { granted in
                guard granted else {
                    print("Notification permission denied.")
                    return
                }
                UNUserNotificationCenter.current().scheduleNotification(identifier: "test",
                                                                        body: "New message!",
                                                                        time: 1)
                UIApplication.shared.performSelector(onMainThread: #selector(URLSessionTask.suspend),
                                                     with: nil,
                                                     waitUntilDone: false)
            }
        } else {
            // Fallback on earlier versions
        }
    }

    @IBAction func clearLogObject(_ sender: Any) {
        let clearAlert = UIAlertController(title: "Log",
                                           message: "Do you want to clear the log history?",
                                           preferredStyle: UIAlertControllerStyle.alert)

        clearAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            self.logObject = ""
            self.updateViews()
        }))
        clearAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(clearAlert, animated: true)
    }
}
