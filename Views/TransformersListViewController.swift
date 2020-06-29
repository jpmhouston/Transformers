//
//  TransformersListViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class TransformersListViewController: UIViewController, TransformerListTableViewDelegate {
    
    // haven't decided yet if navbar title should be button to start fight
    // and bar button should be to toggle all between joined and benched,
    // or title just a title and bar button to start fight
    //@IBOutlet var fightButtonTitleView: UIView!
    //@IBOutlet var fightButton: UIButton!
    //
    //@IBOutlet var benchedBarButton: UIBarButtonItem!
    //var benchedToggleMode: FightVsBenched = .fight
    
    @IBOutlet var fightButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    
    weak var flowController: TransformersListFlowController?
    var viewModel: TransformersListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var tableViewViewController: TransformerListTableViewController? { locateChildViewControllerByType() }
    
    enum FightVsBenched { case fight, bench }
    
    // MARK: - lifecycle
    
    override func viewDidLoad() {
        //navigationItem.titleView = fightButtonTitleView
        
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        }
    }
    
    func configure() {
        let emptyTransformersList = false
        fightButton.isEnabled = !emptyTransformersList
        
        tableViewViewController?.delegate = self
        tableViewViewController?.viewModel = viewModel
    }
    
    // MARK: - controls
    
    @IBAction func addTransformer(_ sender: UIControl) {
        flowController?.addTransformer()
    }
    
    @IBAction func startBattle(_ sender: UIControl) {
        flowController?.startBattle()
    }
    
//    func setFightToggleBarButtonState() {
//        // TODO: check all fight flags to see if all are set to fight not bench
//        let allFight = true
//        if allFight {
//            benchedBarButton?.image = UIImage(named: "BenchIcon")
//            benchedToggleMode = .fight
//        } else {
//            benchedBarButton?.image = UIImage(named: "FightIcon")
//            benchedToggleMode = .bench
//        }
//    }
    
    // MARK: - TransformerListTableViewDelegate & TransformerListCellDelegate conformance
    
    func selectedCell(withId id: String) {
        flowController?.showTransformer(withId: id)
    }
    
    func deleteCell(withId id: String) {
        flowController?.deleteTransformer(withId: id)
    }
    
    func toggleBenched(forId id: String) {
        flowController?.toggleTransformerBenched(forId: id)
    }
    
    func toggleBenchedAll() {
        flowController?.toggleAllTransformersBenched()
    }
    
}
