//
//  FlowController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-24.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//
//  I prefer something other than the app delegate to own and setup objects
//  such as view controllers and data/network managers. In a more complex app
//  I'd want to abstract those two away from each other as well, allow
//  the option of an alternate app target divorced from initial platform UI,
//  be it another platform or perhaps even command-line interface to assist
//  backend testing.
//
//  I'd also prefer a root flow controller and children for major sections of
//  the app, however going with only 1 for this.
//

import UIKit

class FlowController {
    
    var dataController: DataController
    var networkUtility: NetworkUtility
    var rootViewController: UIViewController?
    var transformersListViewController: TransformersListViewController?
    
    init() {
        dataController = DataController()
        networkUtility = NetworkUtility()
        networkUtility.delegate = dataController
        
        rootViewController = startTransformersList()
    }
    
    // MARK: manage TransformersList view controller
    
    func startTransformersList() -> UIViewController {
        let storyboard = UIStoryboard(name: "TransformersList", bundle: nil)
        guard let outerViewController = storyboard.instantiateInitialViewController() else {
            fatalError("Could not find initial view controller in TransformersList storyboard")
        }
        
        guard let viewController: TransformersListViewController = outerViewController.locateViewControllerByType() else {
            fatalError("Could not find TransformersList view controller in TransformersList storyboard")
        }
        
        transformersListViewController = viewController
        transformersListViewController?.flowController = self
        transformersListViewController?.viewModel = TransformersListViewModel() // withDataController: dataController
        
        return outerViewController
    }
    
    // public funcs to be called from view controllers to handle transitions
    // to remove that logic and interdependence from the view controllers themselves
    
    func startBattle() {
        print("startBattle")
    }
    
    func showTransformer(withId id: String) {
        print("showTransformer id \(id)")
    }
    
    func addTransformer() {
        print("addTransformer")
    }
    
    func deleteTransformer(withId id: String) {
        print("deleteTransformer id \(id)")
    }
    
    func toggleTransformerBenched(forId id: String) {
        print("toggleTransformerBenched id \(id)")
    }
    
    func toggleAllTransformersBenched() {
        print("benchOrJoinAll")
    }
    
    
}

struct TransformersListViewModel { } // TODO: implement this elsewhere

// don't let view controller code have to know whether there's only 1 flow controller
// vs a separate one for each
typealias TransformersListFlowController = FlowController
