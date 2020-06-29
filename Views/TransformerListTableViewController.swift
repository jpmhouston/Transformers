//
//  TransformerListTableViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-28.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

protocol TransformerListTableViewDelegate: class {
    func selectedCell(withId id: String)
    func deleteCell(withId id: String)
    func toggleBenched(forId id: String)
    func toggleBenchedAll()
}

// MARK: -

class TransformerListTableViewController: UITableViewController {
    
    @IBOutlet var benchToggleTapRecognizer: UITapGestureRecognizer!
    @IBOutlet var benchToggleLongPressRecognizer: UILongPressGestureRecognizer!
    
    weak var delegate: TransformerListTableViewDelegate?
    var viewModel: TransformersListViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    var cellReuseIdentifier = "TransformerListCell"
    
    var deleteAction: UITableViewRowAction?
    
    // keep local copy of data to have a source for diffing against new data from view model
    // TODO: change to use [TransformersListViewModel.TransformerItem] or something
    var transformerData: [(name: String, isSpecial: Bool, rank: Int, rating: Int, benched: Bool)] = []
    
    // MARK: -
    
    override func viewDidLoad() {
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        benchToggleTapRecognizer.delegate = self
        benchToggleLongPressRecognizer.delegate = self
        benchToggleLongPressRecognizer.cancelsTouchesInView = true
        tableView.addGestureRecognizer(benchToggleTapRecognizer)
        tableView.addGestureRecognizer(benchToggleLongPressRecognizer)
        
        buildCellSwipeActions()
        
        if viewModel != nil {
            configure()
        }
    }
    
    func configure() {
        //transformerData = viewModel.transformerList
        transformerData = [(name: "Optimus Prime", isSpecial: true, rank: 10, rating: 20, benched: false)]
        
        // TODO: use DifferenceKit to give us cell animations
    }
    
    func buildCellSwipeActions() {
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        deleteAction = UITableViewRowAction(style: .destructive, title: deleteTitle) { [weak self] action, indexPath in
            guard let transformerCell = self?.tableView.cellForRow(at: indexPath) as? TransformerListCell else { return }
            self?.delegate?.deleteCell(withId: transformerCell.transformerId)
        }
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
        transformerCell.configure(name: data.name, teamIconURL: nil, isSpecial: data.isSpecial, rank: data.rank, rating: data.rating, benched: data.benched)
        transformerCell.transformerId = "000"
        return transformerCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { return }
        delegate?.selectedCell(withId: transformerCell.transformerId)
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
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return false }
        for indexPath in indexPaths {
            guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { continue }
            let touchLocation = touch.location(in: transformerCell)
            guard transformerCell.bounds.contains(touchLocation) else {
                continue
            }
            if transformerCell.joinedBenchedIcon.frame.contains(touchLocation) {
                return true
            }
        }
        return false
    }
    
    @IBAction func toggleBenchButtonPressed(_ sender: UITapGestureRecognizer) {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in indexPaths {
            guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { continue }
            let touchLocation = sender.location(in: transformerCell)
            guard transformerCell.bounds.contains(touchLocation) else {
                continue
            }
            if transformerCell.joinedBenchedIcon.frame.contains(touchLocation) {
                delegate?.toggleBenched(forId: transformerCell.transformerId)
            } else {
                print("manual select/deselect cell \(indexPath)")
            }
            return
        }
    }
    
    @IBAction func toggleBenchButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // the cell seems to highlight during this long press, but if i remember correctly it's not
        // really getting selected (.. yes, i checked, neither willSelectRow or didSelectRow are called)
        
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in indexPaths {
            guard let transformerCell = tableView.cellForRow(at: indexPath) as? TransformerListCell else { continue }
            let touchLocation = sender.location(in: transformerCell)
            if transformerCell.joinedBenchedIcon.frame.contains(touchLocation) {
                delegate?.toggleBenchedAll()
            }
        }
    }
    
}
