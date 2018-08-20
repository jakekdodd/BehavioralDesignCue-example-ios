//
//  RootViewController.swift
//
//  Created by Akash Desai on 8/6/18.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UIPageViewControllerDelegate {

    var pageViewController: UIPageViewController?
    lazy var modelController = ModelController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the page view controller and add it as a child view controller.
        self.pageViewController = UIPageViewController(transitionStyle: .pageCurl,
                                                       navigationOrientation: .horizontal,
                                                       options: nil)
        self.pageViewController!.delegate = self

        let startingViewController = self.modelController.viewControllerAtIndex(0, storyboard: self.storyboard!)!
        self.pageViewController!.setViewControllers([startingViewController], direction: .forward, animated: false)
        self.pageViewController!.dataSource = self.modelController

        self.addChildViewController(self.pageViewController!)
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect
        // so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)
    }

    @discardableResult
    func setPages(forViewController currentViewController: DataViewController, withOrientation orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation) -> UIPageViewControllerSpineLocation {
        if orientation == .portrait
            || orientation == .portraitUpsideDown
            || UIDevice.current.userInterfaceIdiom == .phone {
            // In portrait orientation or on iPhone:
            //      Set the spine position to "min" and the page view controller's
            //      view controllers array to contain just one view controller.
            //      Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation
            //      sets the doubleSided property to true, so set it to false here.
            let viewControllers = [currentViewController]
            self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true)

            self.pageViewController!.isDoubleSided = false
            return .min
        }

        // In landscape orientation:
        //      Set set the spine location to "mid" and
        //      the page view controller's view controllers array to contain two view controllers.
        //      If the current page is even, set it to contain the current and next view controllers;
        //      if it is odd, set the array to contain the previous and current view controllers.
        var viewControllers: [UIViewController]

        let indexOfCurrentViewController = modelController.indexOfViewController(currentViewController)
        if (indexOfCurrentViewController == 0) || (indexOfCurrentViewController % 2 == 0) {
            let nextViewController = modelController.pageViewController(pageViewController!,
                                                                             viewControllerAfter: currentViewController)
            viewControllers = [currentViewController, nextViewController!]
        } else {
            let previousViewController = modelController.pageViewController(pageViewController!,
                                                                            viewControllerBefore: currentViewController)
            viewControllers = [previousViewController!, currentViewController]
        }
        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true)

        return .mid
    }

    // MARK: - Shortcut action

    func jumpToPageFor(_ data: String) {
        if let currentViewController = modelController.viewControllerForData(data, storyboard: self.storyboard!) {
            setPages(forViewController: currentViewController)
        }
    }

    // MARK: - UIPageViewController delegate methods

    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        guard let dvc = pageViewController.viewControllers?.first as? DataViewController else {
            return UIPageViewControllerSpineLocation.min
        }
        return setPages(forViewController: dvc, withOrientation: orientation)
    }

}
