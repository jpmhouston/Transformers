//
//  ListViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//
//  Contains the table view controller to isolate the handling of the bar button items
//

import UIKit

class ListViewController: UIViewController {
    
    @IBOutlet var fightButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var emptyListMessageView: UIView!
    @IBOutlet var EmptyListMessageViewWhenSplitWiewExpanded: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    // public properties:
    
    weak var flowController: ListFlowControllerProtocol?
    var viewModel: ListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var fightButtonShouldBeHidden: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            updateFightButtonVisibility()
        }
    }
    
    // private properties:
    
    var tableViewViewController: ListTableViewController? {
        locateChildViewControllerByType()
    }
    
    var hadDisappeared = false
    
    // MARK: - lifecycle
    
    override func viewDidLoad() {
        tableViewViewController?.flowController = flowController
        
        updateFightButtonVisibility()
        
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        } else {
            // if vc appearing without a view model then show a progress indicator
            // expecting load to eventually finish and view model to be set
            showLoadingIndicator()
        }
    }
    
    // overriding viewWillAppear/Disappear is a low-rent way to detect transitions
    // to and from pushed view controller, it suffers from some false positives
    // but it should be good enough in a pinch
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if hadDisappeared {
            flowController?.returnedToList()
            
            // after reappearing, assume view mode is bound to be updated imminently
            // looks better if the message is hidden off the bat
            showContainer()
        }
        hadDisappeared = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        hadDisappeared = true
    }
    
    func configure() {
        let emptyList = viewModel?.transformers.isEmpty ?? true
        if emptyList {
            showMessage()
        } else {
            showContainer()
        }
        fightButton.isEnabled = !emptyList
        
        tableViewViewController?.viewModel = viewModel
    }
    
    func updateFightButtonVisibility() {
        // relies on the fightButton property not being weak so it can be removed as the left bar item and then added again
        if fightButtonShouldBeHidden && navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem = nil
        } else if fightButtonShouldBeHidden && navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = fightButton
        }
    }
    
    func showLoadingIndicator() {
        containerView.isHidden = true
        emptyListMessageView.isHidden = true
        EmptyListMessageViewWhenSplitWiewExpanded.isHidden = true
        loadingIndicator.startAnimating()
    }
    
    func showMessage() {
        containerView.isHidden = true
        if splitViewController?.isCollapsed ?? true {
            emptyListMessageView.isHidden = false
            EmptyListMessageViewWhenSplitWiewExpanded.isHidden = true
        } else {
            emptyListMessageView.isHidden = true
            EmptyListMessageViewWhenSplitWiewExpanded.isHidden = false
        }
        loadingIndicator.stopAnimating()
    }
    
    func showContainer() {
        containerView.isHidden = false
        emptyListMessageView.isHidden = true
        EmptyListMessageViewWhenSplitWiewExpanded.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - controls
    
    @IBAction func addTransformer(_ sender: UIBarButtonItem) {
        flowController?.addTransformer()
    }
    
    @IBAction func startBattle(_ sender: UIBarButtonItem) {
        flowController?.startBattle()
    }
    
}
