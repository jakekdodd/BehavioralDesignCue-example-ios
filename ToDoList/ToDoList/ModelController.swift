//
//  ModelController.swift
//
//  Created by Akash Desai on 8/6/18.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of month names.
 */

class ModelController: NSObject, UIPageViewControllerDataSource {

    var pageData: [String] = []

    override init() {
        super.init()
        // Create the data model.
        pageData = DateFormatter().monthSymbols
    }

    func viewControllerForData(_ str: String, storyboard: UIStoryboard) -> DataViewController? {
        return viewControllerAtIndex(pageData.index(of: str) ?? -1, storyboard: storyboard)
    }

    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> DataViewController? {
        // Return the data view controller for the given index.
        if self.pageData.isEmpty || index < 0 || index >= self.pageData.count {
            return nil
        }

        // Create a new view controller and pass suitable data.
        if let dvc = storyboard.instantiateViewController(withIdentifier: "DataViewController") as? DataViewController {
        dvc.dataObject = self.pageData[index]
        return dvc
        } else {
            return nil
        }
    }

    func indexOfViewController(_ viewController: DataViewController) -> Int {
        return pageData.index(of: viewController.dataObject) ?? NSNotFound
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? DataViewController else {
            return nil
        }
        var index = self.indexOfViewController(viewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }

        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? DataViewController else {
            return nil
        }
        var index = self.indexOfViewController(viewController)
        if index == NSNotFound {
            return nil
        }

        index += 1
        if index == self.pageData.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

}
