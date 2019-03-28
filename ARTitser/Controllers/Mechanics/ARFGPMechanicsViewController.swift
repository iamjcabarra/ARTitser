//
//  ARFGPMechanicsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 02/04/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGPMechanicsViewController: UIPageViewController {
    
    var pageControl = UIPageControl()
    var currentPage = 0
    var skipButton = UIButton()
    
    fileprivate lazy var pages: [UIViewController] = {
        return [
            getViewController(withIdentifier: "arfMechanicsPage1"),
            getViewController(withIdentifier: "arfMechanicsPage2"),
            getViewController(withIdentifier: "arfMechanicsPage3"),
            getViewController(withIdentifier: "arfMechanicsPage4"),
            getViewController(withIdentifier: "arfMechanicsPage5"),
            getViewController(withIdentifier: "arfMechanicsPage6"),
            getViewController(withIdentifier: "arfMechanicsPage7"),
            getViewController(withIdentifier: "arfMechanicsPage8"),
            getViewController(withIdentifier: "arfMechanicsPage9")
        ]
    }()
    
    // MARK - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(hex: "0458AB")
        
        dataSource = self
        delegate = self
        
        configurePageControl()
        configureSkipButton()
        
        if let firstViewController = pages.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    // MARK: - Handle Orientation
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async(execute: {
            self.skipButton.removeFromSuperview()
            self.pageControl.removeFromSuperview()
            self.configurePageControl()
            self.configureSkipButton()
        })
    }
    
    // MARK: - Private Methods
    
    /// Instantiate view controller from the storyboard.
    ///
    /// - parameter identifier: View controller's Storyboard ID
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController {
        return UIStoryboard(name: "ARFGPStoryboard", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    /// Instantiates UIPageControl object and adds it to the class
    /// main view.
    fileprivate func configurePageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 115, width: UIScreen.main.bounds.width, height: 50))
        pageControl.backgroundColor = UIColor(hex: "0458AB")
        pageControl.numberOfPages = pages.count - 1
        pageControl.currentPage = currentPage
        pageControl.tintColor = UIColor(hex: "FFFFFF")
        pageControl.pageIndicatorTintColor = UIColor(hex: "CCCCCC")
        pageControl.currentPageIndicatorTintColor = UIColor(hex: "FFFFFF")
        pageControl.center.x = view.center.x
        view.addSubview(pageControl)
    }
    
    /// Instantiates UIButton object and adds it to the class main
    /// view.
    fileprivate func configureSkipButton() {
        skipButton = UIButton(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 65, width: UIScreen.main.bounds.width - 50, height: 50))
        skipButton.backgroundColor = UIColor.clear
        skipButton.layer.borderWidth = 2
        skipButton.layer.borderColor = UIColor(hex: "FFFFFF").cgColor
        skipButton.layer.cornerRadius = 25.0
        skipButton.setTitle("SKIP", for: .normal)
        skipButton.setTitleColor(UIColor(hex: "FFFFFF"), for: .normal)
        skipButton.center.x = view.center.x
        skipButton.addTarget(self, action: #selector(skipButtonAction(_:)), for: .touchUpInside)
        view.addSubview(skipButton)
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the main view controller as user clicks on
    /// skip button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func skipButtonAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Page View Controller Data Source

extension ARFGPMechanicsViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else { return nil }
        guard pages.count > previousIndex else { return nil }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else { return nil }
        guard pages.count > nextIndex else { return nil }
        return pages[nextIndex]
    }
    
}

// MARK: - Page View Controller Delegate

extension ARFGPMechanicsViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        currentPage = pages.index(of: pageContentViewController)!
        pageControl.currentPage = currentPage
    }
    
}
