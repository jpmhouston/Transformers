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

class FlowController {
    
    var dataController: DataController
    var networkUtility: NetworkUtility
    var rootViewController: UIViewController?
    var listViewController: ListViewController?
    
    // MARK: -
    
    init() {
        dataController = DataController()
        networkUtility = NetworkUtility()
        networkUtility.delegate = dataController
        
        rootViewController = createListViewController()
    }
    
    // MARK: - list view controller wrangling
    
    func createListViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "List", bundle: nil)
        guard let outerViewController = storyboard.instantiateInitialViewController() else {
            fatalError("Could not find initial view controller in List.storyboard")
        }
        
        guard let viewController: ListViewController = outerViewController.locateViewControllerByType() else {
            fatalError("Could not find list view controller in List.storyboard")
        }
        
        listViewController = viewController
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
        
        return outerViewController
    }
    
    func updateListViewController() {
        // simply set the view controller's viewModel again with a fresh one
        // app uses simple structs as the view models and not complex stateful objects
        listViewController?.viewModel = ListViewModel(withDataController: dataController)
    }
    
    // MARK: - edit view controller wrangling
    
    func createEditViewController(withTransformer existingTransformer: Transformer? = nil) -> UIViewController {
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
    
    func updateEditViewController() {
        // don't save reference to this vc, by locating it via the root we also verify
        // that it's still in the hierarchy
        guard let viewController: EditViewController = rootViewController?.locateViewControllerByType() else {
            return
        }
        
        viewController.viewModel = EditViewModel(withDataController: dataController)
    }
    
    func exitEditViewController(saving: Bool) {
        print("FlowController.exitEditViewController")
        guard let listViewController = listViewController else {
            fatalError("list view controller has gone away")
        }
        
        // probably instead assert this has already been cleaned up, b/c i think i covered all cases
        // of getting here without doing so. the tricky part is
        dataController.dismissEditedTransformer()

        guard let viewController: EditViewController = rootViewController?.locateViewControllerByType() else {
            // its already gone, just update the list screen
            if saving {
                updateListViewController()
            }
            return
        }
        _ = viewController // don't really need this after all, but was nice to validate it was there tho
        
        listViewController.navigationController?.popToViewController(listViewController, animated: true)
        
        // some completion would be helpful, like `present()` has, currently use a quick & dirty
        // technique to know when the view is back
        if saving {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.updateListViewController()
            }
        }
    }
    
    func editViewControllerWasExited() {
        dataController.dismissEditedTransformer()
    }
    
    // MARK: - fight view controller wrangling
    
    func createFightViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Fight", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? FightViewController else {
            fatalError("Could not find initial view controller in Fight.storyboard")
        }
        
        let combatants = dataController.transformersForNextFight
        viewController.battleResult = Transformer.battle(betweenTransformers: combatants)
        
        return viewController
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
        let viewController = createFightViewController()
        listViewController?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func editTransformer(withId id: String) {
        print("FlowController.editTransformer id \(id)")
        guard let transformer = dataController.transformer(withId: id) else {
            return
        }
        let viewController = createEditViewController(withTransformer: transformer)
        listViewController?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func addTransformer() {
        print("FlowController.addTransformer")
        let viewController = createEditViewController()
        listViewController?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func deleteTransformer(withId id: String) {
        print("FlowController.deleteTransformer id \(id)")
        
        networkUtility.deleteTransformer(id) { [weak self] error in
            print("FlowController.deleteTransformer id \(id) - deleteTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.updateListViewController()
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
    func returnedToList() {
        // if we wanted to save the transformer edits when back button used instead of discarding them
        // then we'd do that here or within `editViewControllerWasExited()`, including updating the
        // transformer's list view model
        // don't want to bite that bullet for this assessment app (i've aready gone way overboard as it is)
        editViewControllerWasExited()
    }
    
    func toggleTransformerBenched(forId id: String) {
        print("FlowController.toggleTransformerBenched id \(id)")
        dataController.toggleBenchedState(forId: id)
        updateListViewController()
    }
    
    func toggleAllTransformersBenched(_ benched: Bool) {
        print("FlowController.toggleAllTransformersBenched \(benched)")
        dataController.setAllBenchedState(benched)
        updateListViewController()
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
    
    func saveNewTransformer() {
        print("FlowController.saveNewTransformer")
        guard let newTransformer = dataController.editingTransformer else { return }
        dataController.savingEditedTransformer()
        
        networkUtility.addTransformer(TransformerInput(sourcedFrom: newTransformer)) { [weak self] error in
            print("FlowController.saveNewTransformer - addTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.exitEditViewController(saving: true)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
    func discardNewTransformer() {
        print("FlowController.discardNewTransformer")
        dataController.dismissEditedTransformer()
        exitEditViewController(saving: false)
    }
    
    func discardEditedTransformer(withId id: String) {
        print("FlowController.discardEditedTransformer id \(id)")
        dataController.dismissEditedTransformer()
        exitEditViewController(saving: false)
    }
    
    func updateEditedTransformer(withId id: String) {
        print("FlowController.updateEditedTransformer id \(id)")
        guard let updatedTransformer = dataController.editingTransformer else { return }
        dataController.savingEditedTransformer()
        
        networkUtility.updateTransformer(TransformerInput(sourcedFrom: updatedTransformer)) { [weak self] error in
            print("FlowController.updateEditedTransformer id \(id) - updateTransformer completion")
            if error == nil {
                DispatchQueue.main.async {
                    self?.exitEditViewController(saving: true)
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
                    self?.exitEditViewController(saving: true)
                }
            } else {
                // should invoke an alert here, but for now we get silent failure
            }
        }
    }
    
}
