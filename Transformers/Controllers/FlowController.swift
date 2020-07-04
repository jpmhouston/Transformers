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
//  the app, however going with only 1 for this. I've divided up support for
//  various view controllers into separate protocols though.
//
//  The goal with the view controllers is to have their dependencies defined
//  as protocols and injected so that they can more easily be exercised in a
//  test build, separate test app, or even a playground.

import UIKit

class FlowController: UISplitViewControllerDelegate {
    
    var dataController: DataController
    var networkUtility: NetworkUtility
    var rootViewController: UIViewController?
    var splitViewController: UISplitViewController?
    
    // MARK: -
    
    init() {
        dataController = DataController()
        #if DEBUG
        networkUtility = FlowController.makeNetworkUtility(fake: true)
        #else
        networkUtility = NetworkUtility()
        #endif
        networkUtility.delegate = dataController
        
        createRootViewController()
    }
    
    #if DEBUG
    static func makeNetworkUtility(fake: Bool) -> NetworkUtility {
        return fake ? FakeNetworkUtility() : NetworkUtility()
    }
    #endif
    
    // MARK: - split view controller
    
    func createRootViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let splitViewController = storyboard.instantiateInitialViewController() as? UISplitViewController else {
            fatalError("Could not find the root view controller in Main.storyboard")
        }
        guard let master = splitViewController.viewControllers.first as? UINavigationController, let detail = splitViewController.viewControllers.last as? UINavigationController else {
            fatalError("Could not find the master and detail view controllers in Main.storyboard")
        }
        
        self.splitViewController = splitViewController
        rootViewController = splitViewController
        
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.delegate = self
        
        let listViewController = createListViewController()
        listViewController.fightButtonShouldBeHidden = true
        master.viewControllers = [listViewController]
        
        let fightViewController = createFightViewController()
        detail.viewControllers = [fightViewController]
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        // fight button is needed when collapsed, there's no other way to get to the fight view controller
        listViewController.fightButtonShouldBeHidden = false
        
        guard let detail = secondaryViewController as? UINavigationController, let detailShowing = detail.viewControllers.last else {
            return true
        }
        
        // return false means let the split view do its default of pushing the child of the secondary onto the master
        // ie. if detail is showing an editor, collapsing pushes in on after the list
        if detailShowing is EditViewController {
            return false
        }
        // true to mean we handle incorporating the secondary ourselves, by doing nothing its not incorporated
        // and the master is used as-is, ie. if detail isn't showing an editor, collapsing shows just the list
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        // fight button is unnecessary when uncollapsed, the constant detail is the fight view controller
        listViewController.fightButtonShouldBeHidden = true
        
        guard let master = primaryViewController as? UINavigationController, let masterShowing = master.viewControllers.last else {
            return nil
        }
        
        // returning nil lets the split view try its normal handling where it pop the master's last view controller
        // and pushes it onto the detail. if the only thing on the nav controller is the list, then return a new
        // fight view controller to use as the detail view
        if (masterShowing is ListViewController) == false {
            return nil
        } else {
            return createFightViewController()
        }
    }
    
    
    // MARK: - list view controller
    
    func createListViewController() -> ListViewController {
        let storyboard = UIStoryboard(name: "List", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? ListViewController else {
            fatalError("Could not find list view controller in List.storyboard")
        }
        
        viewController.flowController = self
        
        // if data controller has been loaded with models already, or idk has been made to use offline storage,
        // and not currently empty then start the list view controller with a model, otherwise leave it without
        // until loading from the network. would be good for it to show an activity indicator during thie time
        if !dataController.isTransformerListEmpty {
            viewController.viewModel = ListViewModel(withDataController: dataController)
        }
        
        networkUtility.loadTransformerList() { error in
            print("FlowController.createListViewController - loadTransformerList completion")
            if error == nil {
                DispatchQueue.main.async {
                    viewController.viewModel = ListViewModel(withDataController: self.dataController)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
        
        return viewController
    }
    
    var listViewController: ListViewController {
        guard let viewController: ListViewController = splitViewController?.locateViewControllerByType() else {
            fatalError("Could not re-locate the list view controller")
        }
        return viewController
    }
    
    func updateListViewController() {
//        guard let viewController = listViewController else {
//            return
//        }
        
        // simply set the view controller's viewModel again with a fresh one
        // app uses simple structs as the view models and not complex stateful objects
        listViewController.viewModel = ListViewModel(withDataController: dataController)
        
        // when split view expanded, always update the fight view controller, which is probably visible
        updateFightViewControllerIfSplitViewExpanded()
    }
    
    // MARK: - edit view controller
    
    func createEditViewController(withTransformer existingTransformer: Transformer? = nil) -> EditViewController {
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? EditViewController else {
            fatalError("Could not find initial view controller in Edit.storyboard")
        }
        
        let transformer = existingTransformer ?? Transformer()
        dataController.startEditingTransformer(transformer)
        
        viewController.flowController = self
        viewController.viewModel = EditViewModel(withDataController: dataController)
        
        return viewController
    }
    
    func presentEditViewController(withTransformer existingTransformer: Transformer? = nil) {
        // if already editing the same transformer, or existing and editor id both nil, this is the user
        // tapping again in the master side list again, or tapping the + again, redundantly. just return
        if let currentViewController = editViewController {
            if let viewModel = currentViewController.viewModel, viewModel.id == nil && existingTransformer == nil {
                return
            }
            if let viewModelId = currentViewController.viewModel?.id, let id = existingTransformer?.id, id == viewModelId {
                return
            }
            
            // already editing some another transformer, dismiss that first
            dismissEditViewController(saving: false, animated: false)
        }
        
        let viewController = createEditViewController(withTransformer: existingTransformer)
        
        if splitViewController?.isCollapsed != true, let detail = splitViewController?.viewControllers.last as? UINavigationController {
            detail.pushViewController(viewController, animated: true)
        } else {
            splitViewController?.showDetailViewController(viewController, sender: nil)
        }
    }
    
    var editViewController: EditViewController? {
        guard let viewController: EditViewController = splitViewController?.locateViewControllerByType() else {
            return nil
        }
        return viewController
    }
    
    func updateEditViewController() {
        guard let viewController = editViewController else {
            return
        }
        viewController.viewModel = EditViewModel(withDataController: dataController)
    }
    
    func dismissEditViewController(ifMatchingId id: String? = nil, saving: Bool, animated: Bool = true) {
        print("FlowController.dismissEditViewController")
        
        let viewController = editViewController
        
        // if id passed in, only dismiss if id's match
        if let id = id, let viewController = viewController, viewController.viewModel?.id != id {
            return
        }
        
        // data controller holds some state about the transformer being edited, ensure its cleaned up
        // yes, leaky abstraction, not the best
        // maybe instead assert its already been cleaned up, b/c i think i covered all cases of getting here without doing so
        dataController.dismissEditedTransformer()
        
        // is view controller is not already gone, remove it here
        if let viewController = viewController, viewController.navigationController?.viewControllers.last == viewController {
            viewController.navigationController?.popViewController(animated: animated)
        }
        
        if saving {
            updateListViewController()
            updateFightViewControllerIfSplitViewExpanded()
        }
    }
    
    func editViewControllerWasDismissed() {
        dataController.dismissEditedTransformer()
    }
    
    // MARK: - fight view controller
    
    func createFightViewController() -> FightViewController {
        let storyboard = UIStoryboard(name: "Fight", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? FightViewController else {
            fatalError("Could not find initial view controller in Fight.storyboard")
        }
        
        let combatants = dataController.transformersForNextFight
        viewController.battleResult = Transformer.battle(betweenTransformers: combatants)
        
        return viewController
    }
    
    func presentFightViewController() {
        let viewController = createFightViewController()
        splitViewController?.showDetailViewController(viewController, sender: nil)
    }
    
    var fightViewController: FightViewController? {
        guard let viewController: FightViewController = splitViewController?.locateViewControllerByType() else {
            return nil
        }
        return viewController
    }
    
    func updateFightViewController() {
        guard let viewController = fightViewController else {
            return
        }
        
        let combatants = dataController.transformersForNextFight
        viewController.battleResult = Transformer.battle(betweenTransformers: combatants)
    }
    
    func updateFightViewControllerIfSplitViewExpanded() {
        if splitViewController?.isCollapsed == false {
            updateFightViewController()
        }
    }
    
}


// protocols of functions to be called from view controllers to handle transitions
// to remove that logic and interdependence from the view controllers themselves

// MARK: - TransformersList support

protocol ListFlowControllerProtocol: class {
    func startBattle()
    func editTransformer(withId id: String)
    func addTransformer()
    func deleteTransformer(withId id: String)
    func returnedToList()
    func toggleTransformerBenched(forId id: String)
    func toggleAllTransformersBenched(_ benched: Bool)
}

extension FlowController: ListFlowControllerProtocol {
    
    func startBattle() {
        print("FlowController.startBattle")
        presentFightViewController()
    }
    
    func editTransformer(withId id: String) {
        print("FlowController.editTransformer id \(id)")
        guard let transformer = dataController.transformer(withId: id) else {
            return
        }
        presentEditViewController(withTransformer: transformer)
    }
    
    func addTransformer() {
        print("FlowController.addTransformer")
        presentEditViewController()
    }
    
    func deleteTransformer(withId id: String) {
        print("FlowController.deleteTransformer id \(id)")
        
        networkUtility.deleteTransformer(id) { [weak self] error in
            print("FlowController.deleteTransformer id \(id) - deleteTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    // remove the showing edit view controller if its editing this very same transformer
                    self?.dismissEditViewController(ifMatchingId: id, saving: false)
                    
                    // calls to dismissEditViewController normally do these already, but only when
                    // called with saving:true, need to explicitly call these here
                    self?.updateListViewController()
                    self?.updateFightViewControllerIfSplitViewExpanded()
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
    func returnedToList() {
        // if we wanted to save the transformer edits when back button used instead of discarding them
        // then we'd do that here or within `editViewControllerWasDismissed()`, including updating the
        // transformer's list view model
        // don't want to bite that bullet for this assessment app (i've aready gone way overboard as it is)
        editViewControllerWasDismissed()
    }
    
    func toggleTransformerBenched(forId id: String) {
        print("FlowController.toggleTransformerBenched id \(id)")
        dataController.toggleBenchedState(forId: id)
        updateListViewController()
        updateFightViewControllerIfSplitViewExpanded()
    }
    
    func toggleAllTransformersBenched(_ benched: Bool) {
        print("FlowController.toggleAllTransformersBenched \(benched)")
        dataController.setAllBenchedState(benched)
        updateListViewController()
        updateFightViewControllerIfSplitViewExpanded()
    }
    
}

// MARK: - TransformerEditor support

protocol EditFlowControllerProtocol: class {
    func changedTransformerName(_ newName: String, forId id: String?)
    func changedTransformerTeam(_ newTeam: Transformer.Team, forId id: String?)
    func changedTransformerBenched(_ newIsBenched: Bool, forId id: String?)
    func changedTransformerRank(_ newValue: Int, forId id: String?)
    func changedTransformerStrength(_ newValue: Int, forId id: String?)
    func changedTransformerIntelligence(_ newValue: Int, forId id: String?)
    func changedTransformerSpeed(_ newValue: Int, forId id: String?)
    func changedTransformerEndurance(_ newValue: Int, forId id: String?)
    func changedTransformerFirepower(_ newValue: Int, forId id: String?)
    func changedTransformerCourage(_ newValue: Int, forId id: String?)
    func changedTransformerSkill(_ newValue: Int, forId id: String?)
    func saveNewTransformer()
    func discardNewTransformer()
    func discardEditedTransformer(withId id: String)
    func updateEditedTransformer(withId id: String)
    func deleteEditedTransformer(withId id: String)
}

extension FlowController: EditFlowControllerProtocol {
    
    func changedTransformerName(_ newName: String, forId id: String?) {
        dataController.updateEditingTransformerName(newName)
        updateEditViewController()
    }
    
    func changedTransformerTeam(_ newTeam: Transformer.Team, forId id: String?) {
        dataController.updateEditingTransformerTeam(newTeam)
        updateEditViewController()
    }
    
    func changedTransformerBenched(_ newIsBenched: Bool, forId id: String?) {
        dataController.updateEditingTransformerBenched(newIsBenched, forId: id)
        updateEditViewController()
    }
    
    func changedTransformerRank(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerRank(newValue)
        updateEditViewController()
    }
    
    func changedTransformerStrength(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerStrength(newValue)
        updateEditViewController()
    }
    
    func changedTransformerIntelligence(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerIntelligence(newValue)
        updateEditViewController()
    }
    
    func changedTransformerSpeed(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerSpeed(newValue)
        updateEditViewController()
    }
    
    func changedTransformerEndurance(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerEndurance(newValue)
        updateEditViewController()
    }
    
    func changedTransformerFirepower(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerFirepower(newValue)
        updateEditViewController()
    }
    
    func changedTransformerCourage(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerCourage(newValue)
        updateEditViewController()
    }
    
    func changedTransformerSkill(_ newValue: Int, forId id: String?) {
        dataController.updateEditingTransformerSkill(newValue)
        updateEditViewController()
    }
    
    func discardNewTransformer() {
        print("FlowController.discardNewTransformer")
        dataController.dismissEditedTransformer()
        dismissEditViewController(saving: false)
    }
    
    func discardEditedTransformer(withId id: String) {
        print("FlowController.discardEditedTransformer id \(id)")
        dataController.dismissEditedTransformer()
        dismissEditViewController(saving: false)
    }
    
    func saveNewTransformer() {
        print("FlowController.saveNewTransformer")
        guard let newTransformer = dataController.editingTransformer else { return }
        dataController.savingEditedTransformer()
        
        networkUtility.addTransformer(TransformerInput(sourcedFrom: newTransformer)) { [weak self] error in
            print("FlowController.saveNewTransformer - addTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.dismissEditViewController(saving: true)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
    func updateEditedTransformer(withId id: String) {
        print("FlowController.updateEditedTransformer id \(id)")
        guard let updatedTransformer = dataController.editingTransformer else { return }
        dataController.savingEditedTransformer()
        
        networkUtility.updateTransformer(TransformerInput(sourcedFrom: updatedTransformer)) { [weak self] error in
            print("FlowController.updateEditedTransformer id \(id) - updateTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.dismissEditViewController(saving: true)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
    func deleteEditedTransformer(withId id: String) {
        print("FlowController.deleteEditedTransformer id \(id)")
        
        networkUtility.deleteTransformer(id) { [weak self] error in
            print("FlowController.deleteEditedTransformer id \(id) - deleteTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.dismissEditViewController(saving: true)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
}
