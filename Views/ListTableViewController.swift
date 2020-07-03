//
//  ListTableViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-28.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class ListTableViewController: UITableViewController {
    
    @IBOutlet var toggleTapRecognizer: UITapGestureRecognizer!
    @IBOutlet var toggleLongPressRecognizer: UILongPressGestureRecognizer!
    
    weak var flowController: ListFlowControllerProtocol?
    var viewModel: ListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var cellReuseIdentifier = "TransformerListCell"
    
    // keep local copy of data to have a source for diffing against new data from view model
    var transformerData: [ListViewModel.TransformerItem] = []
    
    // MARK: -
    
    override func viewDidLoad() {
        setupGestureRecognizers()
        
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        }
    }
    
    func configure() {
        transformerData = viewModel?.transformers ?? []
        tableView.reloadData()
        
        // TODO: use DifferenceKit to handle optimized cell moves/insertions/deletions & potentially better animations
        // instead of the above:
        
        //let sourceData = transformerData
        //let targetData = viewModel?.transformers ?? []
        //let changeset = StagedChangeset(source: sourceData, target: targetData)
        //tableView.reload(using: changeset, with: .fade) { data in
        //    transformerData = targetData
        //}
        
        // also ListViewModel.TransformerItem would need to add these protocols Equatable, Differentiable
    }
    
    func toggleAllTransformersJoinedOrBenched(forCell cell: ListCell) {
        let currentCellBenched = cell.isBenched
        guard let fc = flowController else {    // to simplify some code below
            return
        }
        
        let joinOption = NSLocalizedString("Set All to Fight!", comment: "")
        let benchOption = NSLocalizedString("Set All to Benched", comment: "")
        let cancel = NSLocalizedString("Cancel", comment: "")
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let joinAction = UIAlertAction(title: joinOption, style: .default, handler: { _ in fc.toggleAllTransformersBenched(false) })
        let benchAction = UIAlertAction(title: benchOption, style: .default, handler: { _ in fc.toggleAllTransformersBenched(true) })
        alert.addAction(currentCellBenched ? joinAction : benchAction) // toggled state first
        alert.addAction(currentCellBenched ? benchAction : joinAction) // same state second
        alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated) // overridden to give somewhere to put a breakpoint during some view debugging, to be removed
    }
    
    // MARK: - data source & delegate methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transformerData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        guard let transformerCell = cell as? ListCell, indexPath.item < transformerData.count else {
            return cell
        }
        let data = transformerData[indexPath.item]
        transformerCell.configure(name: data.name, teamIcon: data.teamIcon, isSpecial: data.isSpecial, rank: data.rank, rating: data.rating, benched: data.isBenched)
        transformerCell.transformerId = data.id
        return transformerCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let transformerCell = tableView.cellForRow(at: indexPath) as? ListCell else {
            return
        }
        flowController?.editTransformer(withId: transformerCell.transformerId)
    }
    
    // implementing this give us a delete swipe action automatically
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        guard editingStyle == .delete, let transformerCell = tableView.cellForRow(at: indexPath) as? ListCell else {
//            return
//        }
//        self?.flowController?.deleteTransformer(withId: transformerCell.transformerId)
//    }
    // but choose to use UITableViewRowAction api to get an edit option too
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let editTitle = NSLocalizedString("Edit", comment: "")
        let benchTitle = NSLocalizedString("Bench", comment: "")
        let joinTitle = NSLocalizedString("Join", comment: "")
        
        // it's probably valid to get the cell when called here and use it in the closures below,
        // seeing as this gets called just as the slide occurs, vs much earlier giving any opportunity
        // for the cell to be reused inbetween
        guard let transformerCell = tableView.cellForRow(at: indexPath) as? ListCell else {
            return []
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: deleteTitle) { [weak self] _, indexPath in
            self?.flowController?.deleteTransformer(withId: transformerCell.transformerId)
        }
        let editAction = UITableViewRowAction(style: .default, title: editTitle) { [weak self] _, indexPath in
            self?.flowController?.editTransformer(withId: transformerCell.transformerId)
        }
        editAction.backgroundColor = UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1) // the indigo i used in IB isn't in iOS10 APIs :^(
        
        let joinOrBenchTitle = transformerCell.isBenched ? joinTitle : benchTitle
        let joinOrBenchAction = UITableViewRowAction(style: .default, title: joinOrBenchTitle) { [weak self] _, indexPath in
            self?.flowController?.toggleTransformerBenched(forId: transformerCell.transformerId)
        }
        joinOrBenchAction.backgroundColor = .gray
        
        return [deleteAction, editAction, joinOrBenchAction]
    }
    
}

// MARK: - gesture recognizer
// i've tried putting buttons into tableview & collectionview cells a few times and learned
// that there's some voodoo there, and wanting to handle a long press makes it worse
//
// one solution i've previous tried is to use a UIButton subclass that monitors its own events
// to implement long press but i wasn't about to reinvent that wheel and rediscover the issues
// of buttons in tableview cells
//
// another thing i've done before is what's below, putting the tap and long press geture
// recognizers onto the view controllers and drilling down to ensure they only take effect
// for taps on the icon, a little more involved but works well

extension ListTableViewController: UIGestureRecognizerDelegate {
    
    func setupGestureRecognizers() {
        // nothing extra to setup after all, these checkboxes set thusly in IB are all that's needed:
        // Cancel touches in view Off for both, Delays touches begin On for the tap recognizer
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let result = testOverVisibleCells(forTouch: touch) { transformerCell, touchLocation in
            return transformerCell.joinedBenchedIcon.frame.contains(touchLocation)
        }
        return result
    }
    
    @IBAction func toggleButtonPressed(_ sender: UITapGestureRecognizer) {
        iterateOverVisibleCells(forGestureRecognizer: sender) { transformerCell, touchLocation in
            // don't need to test for touch location within icon, assume that `gestureRecognizer(shouldReceive:)`
            // would have rejected the touch if it wasn't
            self.flowController?.toggleTransformerBenched(forId: transformerCell.transformerId)
        }
    }
    
    @IBAction func toggleButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // the cell seems to highlight during this long press, but if i remember correctly it's not
        // really getting selected (.. yes, i checked, neither willSelectRow or didSelectRow are called)
        
        iterateOverVisibleCells(forGestureRecognizer: sender) { transformerCell, touchLocation in
            // don't need to test for touch location within icon, assume that `gestureRecognizer(shouldReceive:)`
            // would have rejected the touch if it wasn't
            self.toggleAllTransformersJoinedOrBenched(forCell: transformerCell)
        }
    }
    
    // went a bit overboard and factored out the common iteration I had above, supporting the 2 simple variants below
    @discardableResult
    func testOverVisibleCells<T>(_ locationMap: (ListCell) -> CGPoint, _ visit: (ListCell, CGPoint) -> T) -> T? {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return nil }
        for indexPath in indexPaths {
            guard let transformerCell = tableView.cellForRow(at: indexPath) as? ListCell else { continue }
            let touchLocation = locationMap(transformerCell)
            guard transformerCell.bounds.contains(touchLocation) else {
                continue
            }
            return visit(transformerCell, touchLocation)
        }
        return nil
    }
    
    func testOverVisibleCells(forTouch touch: UITouch, _ visit: (ListCell, CGPoint) -> Bool) -> Bool {
        return testOverVisibleCells({ touch.location(in: $0) }, visit) ?? false
    }
    
    func iterateOverVisibleCells(forGestureRecognizer gestureRecognizer: UIGestureRecognizer, _ visit: (ListCell, CGPoint) -> Void) {
        testOverVisibleCells({ gestureRecognizer.location(in: $0) }, visit) // calls generic func below with T = Void, ignores Void? return value
    }
    
}
