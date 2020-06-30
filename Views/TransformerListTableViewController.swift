//
//  TransformerListTableViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-28.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class TransformerListTableViewController: UITableViewController {
    
    @IBOutlet var benchToggleTapRecognizer: UITapGestureRecognizer!
    @IBOutlet var benchToggleLongPressRecognizer: UILongPressGestureRecognizer!
    
    weak var flowController: TransformersListFlowControllerProtocol?
    var viewModel: TransformersListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var cellReuseIdentifier = "TransformerListCell"
    
    var deleteAction: UITableViewRowAction?
    
    // keep local copy of data to have a source for diffing against new data from view model
    var transformerData: [TransformersListViewModel.TransformerItem] = []
    
    // MARK: -
    
    override func viewDidLoad() {
        buildCellSwipeActions()
        
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        }
    }
    
    func configure() {
        transformerData = viewModel?.transformers ?? []
        tableView.reloadData()
        
        // TODO: use DifferenceKit to give us cell animations
        // instead of the above:
        
        //let sourceData = transformerData
        //let targetData = viewModel?.transformers ?? []
        //let changeset = StagedChangeset(source: sourceData, target: targetData)
        //tableView.reload(using: changeset, with: .fade) { data in
        //    transformerData = targetData
        //}
        
        // also somewhere need to do:
        //extension TransformerItem: Equatable, Differentiable
    }
    
    func buildCellSwipeActions() {
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        deleteAction = UITableViewRowAction(style: .destructive, title: deleteTitle) { [weak self] action, indexPath in
            guard let transformerCell = self?.tableView.cellForRow(at: indexPath) as? TransformerListCell else { return }
            self?.flowController?.deleteTransformer(withId: transformerCell.transformerId)
        }
    }
    
    func toggleAllTransformersJoinedOrBenched(forCell cell: TransformerListCell) {
        let currentCellBenched = cell.isBenched
        guard let fc = flowController else { return } // to simplify some code below
        
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
    
    // MARK: - data source & delegate methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transformerData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        guard let transformerCell = cell as? TransformerListCell, indexPath.item < transformerData.count else {
            return cell
        }
        let data = transformerData[indexPath.item]
        transformerCell.configure(name: data.name, teamIconURL: data.teamIcon, isSpecial: data.isSpecial, rank: data.rank, rating: data.rating, benched: data.isBenched)
        transformerCell.transformerId = data.id
        return transformerCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { return }
        flowController?.editTransformer(withId: transformerCell.transformerId)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let deleteAction = deleteAction else { return [] }
        return [deleteAction]
    }
    
}

// MARK: -

extension TransformerListTableViewController: UIGestureRecognizerDelegate {
    
    // MARK: gesture recognizer
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return testOverVisibleCells(forTouch: touch) { transformerCell, touchLocation in
            transformerCell.joinedBenchedIcon.frame.contains(touchLocation)
        }
    }
    
    @IBAction func toggleBenchButtonPressed(_ sender: UITapGestureRecognizer) {
        iterateOverVisibleCells(forGestureRecognizer: sender) { transformerCell, touchLocation in
            // don't need to test for touch location within icon, assume that `gestureRecognizer(shouldReceive:)`
            // would have rejected the touch if it wasn't
            self.flowController?.toggleTransformerBenched(forId: transformerCell.transformerId)
        }
    }
    
    @IBAction func toggleBenchButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
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
    func testOverVisibleCells<T>(_ locationMap: (TransformerListCell) -> CGPoint, _ visit: (TransformerListCell, CGPoint) -> T) -> T? {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return nil }
        for indexPath in indexPaths {
            guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { continue }
            let touchLocation = locationMap(transformerCell)
            guard transformerCell.bounds.contains(touchLocation) else {
                continue
            }
            return visit(transformerCell, touchLocation)
        }
        return nil
    }
    
    func testOverVisibleCells(forTouch touch: UITouch, _ visit: (TransformerListCell, CGPoint) -> Bool) -> Bool {
        return testOverVisibleCells({ touch.location(in: $0) }, visit) ?? false
    }
    
    func iterateOverVisibleCells(forGestureRecognizer gestureRecognizer: UIGestureRecognizer, _ visit: (TransformerListCell, CGPoint) -> Void) {
        testOverVisibleCells({ gestureRecognizer.location(in: $0) }, visit) // calls generic func below with T = Void, ignores Void? return value
    }
    
}
