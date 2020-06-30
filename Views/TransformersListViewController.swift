//
//  TransformersListViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//
//  Contains the table view controller to isolate the handling of the bar button items
//

import UIKit

class TransformersListViewController: UIViewController {
    
    @IBOutlet var fightButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    
    @IBOutlet var emptyListMessageView: UIView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    weak var flowController: TransformersListFlowControllerProtocol?
    var viewModel: TransformersListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var hadDisappeared = false
    
    var tableViewViewController: TransformerListTableViewController? {
        locateChildViewControllerByType()
    }
    
    // MARK: - lifecycle
    
    override func viewDidLoad() {
        tableViewViewController?.flowController = flowController
        
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        } else {
            // if vc appearing without a view model then show a progress indicator
            // expecting load to eventually finish and view model to be set
            emptyListMessageView.isHidden = true
            loadingIndicator.startAnimating()
        }
    }
    
    // overriding viewWillAppear/Disappear is a low-rent way to detect transitions
    // to and from pushed view controller, it suffers from some false positives
    // but it should be good enough in a pinch
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if hadDisappeared {
            flowController?.returnedToTransformersList()
            
            // after reappearing, don't want that message and make sure indicator is gone
            emptyListMessageView.isHidden = true
            loadingIndicator.stopAnimating()
        }
        hadDisappeared = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        hadDisappeared = true
    }
    
    func configure() {
        loadingIndicator.stopAnimating()
        
        let emptyList = viewModel?.transformers.isEmpty ?? true
        fightButton.isEnabled = !emptyList
        emptyListMessageView.isHidden = !emptyList
        
        tableViewViewController?.viewModel = viewModel
    }
    
    // MARK: - controls
    
    @IBAction func addTransformer(_ sender: UIControl) {
        flowController?.addTransformer()
    }
    
    @IBAction func startBattle(_ sender: UIControl) {
        flowController?.startBattle()
    }
    
}
