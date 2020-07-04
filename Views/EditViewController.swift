//
//  EditViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-29.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class EditViewController: UIViewController {
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var teamIcon: UIImageView!
    @IBOutlet var ratingValue: UILabel!
    @IBOutlet var star: UIImageView!
    
    @IBOutlet var joinedBenchedIcon: UIImageView!
    @IBOutlet var joinedBenchedToggle: UISwitch!
    
    @IBOutlet var teamSwitcher: UISegmentedControl!
    @IBOutlet var rankField: UITextField!
    @IBOutlet var strengthField: UITextField!
    @IBOutlet var intelligenceField: UITextField!
    @IBOutlet var speedField: UITextField!
    @IBOutlet var enduranceField: UITextField!
    @IBOutlet var firepowerField: UITextField!
    @IBOutlet var courageField: UITextField!
    @IBOutlet var skillField: UITextField!
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var deleteButtonHiddenConstraint: NSLayoutConstraint!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var keyboardDismissalTapRecognizer: UITapGestureRecognizer!
    
    // public properties:
    
    weak var flowController: EditFlowControllerProtocol?
    var viewModel: EditViewModel? {
        didSet {
            guard isViewLoaded else { return }
            configure()
        }
    }
    
    // private properties:
    
    var contentViewCoordinates: CGPoint?
    var activeField: UITextField?
    var observations: [AnyObject] = []
    
    var isNewTransformer: Bool {
        if let viewModel = viewModel {
            return viewModel.id == nil
        }
        return false // or true doesn't matter, invalid either way. shouldn't call this if viewModel nil
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        // if view model set before `viewDidLoad` then its earlier didSet did nothing, postponed call to `configure` here
        // if view model set after `viewDidLoad` then this below does nothing, the didSet will call `configure`
        if viewModel != nil {
            configure()
        }
        
        setupToScrollWhenKeyboardAppears()
        setupTextFieldNotificationObservations()
    }
    
    func configure() {
        guard let viewModel = viewModel else { return }
        
        // really only need to do this the first time in, not everytime model is updated
        // but it doesn't hurt
        if isNewTransformer {
            navigationItem.title = NSLocalizedString("New Transformer", comment:"")
        } else {
            navigationItem.title = NSLocalizedString("Edit Transformer", comment:"")
        }
        
        if nameField.text != viewModel.name {
            nameField.text = viewModel.name
        }
        star.isHidden = (viewModel.isSpecial == false)
        ratingValue.text = String(viewModel.rating)
        
        teamIcon.setTransformerIcon(withURLString: viewModel.teamIcon)
        
        switch viewModel.team {
        case .autobots: teamSwitcher.selectedSegmentIndex = 0
        case .decepticons: teamSwitcher.selectedSegmentIndex = 1
        }
        
        if viewModel.isBenched {
            joinedBenchedIcon.image = UIImage(named: "BenchIcon")
            joinedBenchedToggle.isOn = false
        } else {
            joinedBenchedIcon.image = UIImage(named: "FightIcon")
            joinedBenchedToggle.isOn = true
        }
        
        setFieldIfIntValueNew(rankField, viewModel.rank)
        setFieldIfIntValueNew(strengthField, viewModel.strength)
        setFieldIfIntValueNew(intelligenceField, viewModel.intelligence)
        setFieldIfIntValueNew(speedField, viewModel.speed)
        setFieldIfIntValueNew(enduranceField, viewModel.endurance)
        setFieldIfIntValueNew(firepowerField, viewModel.firepower)
        setFieldIfIntValueNew(courageField, viewModel.courage)
        setFieldIfIntValueNew(skillField, viewModel.skill)
        
        let hideDeleteButton = !viewModel.allowDelete
        deleteButton.isHidden = hideDeleteButton
        deleteButtonHiddenConstraint.isActive = hideDeleteButton
    }
    
    func setFieldIfIntValueNew(_ field: UITextField, _ value: Int) {
        if isNewTransformer && value == 0 && (field.text == nil || field.text!.isEmpty) {
            return // special case when creating new transformer, don't replace empty fields with "0"
        }
        let valueString = String(value)
        if field.text != valueString {
            field.text = valueString
        }
    }
    
    func validateBeforeSave() -> Bool {
        // would be good to be validating on every edit, blank or reused names and maybe also empty
        // value fields. should somehow quietly indicating when invalid, red field outline or something,
        // and proactively disable save button instead of alerting after the fact as below
        // would then be closer to allowing automatic saves when back button used, currently going back
        // is essentially a cancel
        
        guard let viewModel = viewModel else { return false }
        switch viewModel.validate() {
        case .nameEmpty:
            validationAlert(withMessage: NSLocalizedString("Cannot save a Transformer with an empty name.", comment: ""), makingFieldEditable: nameField)
            return false
        case .nameNotUnique:
            validationAlert(withMessage: NSLocalizedString("This name already used. Cannot save a Transformer unless its name is unique.", comment: ""), makingFieldEditable: nameField)
            return false
        case .rankOutOfBounds:
            validationAlert(withMessage: NSLocalizedString("Cannot save a Transformer with a Rank less than 1", comment: ""), makingFieldEditable: rankField)
            return false
        case .valueOutOfBouds:
            // don't expect this to happen because of the keyboard used, and while there's nothing
            // preventing anything being pasted into the fields, anything invalid that isn't intercepted
            // by code in this vc should round trip through the viewModel to become 0
            // so this case isn't handled well - don't have a mechanism for making the right field editable anyway
            validationAlert(withMessage: NSLocalizedString("Transformer statistics values must be valid", comment: ""))
            return false
        default:
            return true
        }
    }
    
    func validationAlert(withMessage message: String, makingFieldEditable field: UITextField? = nil) {
        var focusField: ((UIAlertAction) -> Void)? = nil
        if let field = field {
            focusField = { _ in
                // performing later on the main thread will (i think) help alert to be more cleaned up
                // before doing something affecting the view controller / scrollview / keyboard etc
                // (cargocultish?)
                DispatchQueue.main.async {
                    field.becomeFirstResponder()
                }
            }
        }
        
        let title = NSLocalizedString("Unable to Save", comment: "")
        let ok = NSLocalizedString("OK", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ok, style: .default, handler: focusField))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - controls
    
    func setupTextFieldNotificationObservations() {
        NotificationCenter.default.addObserver(self, selector: #selector(fieldDidChange), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    @objc func fieldDidChange(_ notification: Notification) {
        guard let field = notification.object as? UITextField else { return }
        if field == nameField {
            nameChanged()
        } else {
            intFieldChanged(field)
        }
    }
    
    func nameChanged() {
        guard let viewModel = viewModel else { return }
        guard nameField.text != nil && nameField.text!.isEmpty == false && nameField.text! != viewModel.name else {
            return // // don't save empty name back to the model, or edit with no new change
        }
        flowController?.changedTransformerName(nameField.text!, forId: viewModel.id)
    }
    
    func intFieldChanged(_ field: UITextField) {
        guard let viewModel = viewModel else { return }
        if field == rankField {
            if let value = changedFieldIntValue(field, viewModel.rank) {
                flowController?.changedTransformerRank(value, forId: viewModel.id)
            }
        } else if field == strengthField {
            if let value = changedFieldIntValue(field, viewModel.strength) {
                flowController?.changedTransformerStrength(value, forId: viewModel.id)
            }
        } else if field == intelligenceField {
            if let value = changedFieldIntValue(field, viewModel.intelligence) {
                flowController?.changedTransformerIntelligence(value, forId: viewModel.id)
            }
        } else if field == speedField {
            if let value = changedFieldIntValue(field, viewModel.speed) {
                flowController?.changedTransformerSpeed(value, forId: viewModel.id)
            }
        } else if field == enduranceField {
            if let value = changedFieldIntValue(field, viewModel.endurance) {
                flowController?.changedTransformerEndurance(value, forId: viewModel.id)
            }
        } else if field == firepowerField {
            if let value = changedFieldIntValue(field, viewModel.firepower) {
                flowController?.changedTransformerFirepower(value, forId: viewModel.id)
            }
        } else if field == courageField {
            if let value = changedFieldIntValue(field, viewModel.courage) {
                flowController?.changedTransformerCourage(value, forId: viewModel.id)
            }
        } else if field == skillField {
            if let value = changedFieldIntValue(field, viewModel.skill) {
                flowController?.changedTransformerSkill(value, forId: viewModel.id)
            }
        } else {
            return
        }
    }
    
    func changedFieldIntValue(_ field: UITextField, _ priorValue: Int) -> Int? {
        var fieldValue: Int = 0
        if let text = field.text {
            // handle paste of non-digits or negative number by resetting to "0" here
            if let intValue = Int(text), intValue >= 0 {
                fieldValue = intValue
            } else {
                field.text = "0"
                // the above may cause fieldDidChange to be called again, will it be recursively??
                // that may be a small problem which could result in `changedTransformerXxxx()` called twice
                //
                // i'm imagining a simple, clever worked-around by making `priorValue` an autoclosure!
                // the interrupting recursion would occur *here*, and once we're back out the test below will
                // find `priorValue()` then be 0 rather than the captured value preceeding the recursion.
                // swift ftw! don't want to take time testing this out though
            }
        }
        
        return fieldValue != priorValue ? fieldValue : nil
    }
    
    @IBAction func teamSwitcherChanged(_ sender: UISegmentedControl) {
        guard let viewModel = viewModel else { return }
        switch teamSwitcher.selectedSegmentIndex {
        case 0:
            if viewModel.team != .autobots {
                flowController?.changedTransformerTeam(.autobots, forId: viewModel.id)
            }
        case 1:
            if viewModel.team != .decepticons {
                flowController?.changedTransformerTeam(.decepticons, forId: viewModel.id)
            }
        default: break
        }
    }
    
    @IBAction func joinedBenchedSwitchChanged(_ sender: UISwitch) {
        let benched = !joinedBenchedToggle.isOn
        guard let viewModel = viewModel, benched != viewModel.isBenched else { return }
        flowController?.changedTransformerBenched(joinedBenchedToggle.isOn == false, forId: viewModel.id)
    }
    
    @IBAction func savePressed(_ sender: UIButton) {
        guard let viewModel = viewModel else { return }
        
        guard validateBeforeSave() == true else {
            return
        }
        
        if let id = viewModel.id {
            flowController?.updateEditedTransformer(withId: id)
        } else {
            flowController?.saveNewTransformer()
        }
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        guard let viewModel = viewModel else { return }
        if let id = viewModel.id {
            flowController?.discardEditedTransformer(withId: id)
        } else {
            flowController?.discardNewTransformer()
        }
    }
    
    @IBAction func deletePressed(_ sender: UIButton) {
        guard let viewModel = viewModel, let id = viewModel.id else { return }
        flowController?.deleteEditedTransformer(withId: id)
    }
    
}

// MARK: - keyboard

// i meant to dig through my old code to find best technique for handling textfields / scrollview / keyboard
// but couldn't find what i wanted, what's below is from  https://stackoverflow.com/a/27342830/59273
// and is close but still janky until i ripped out some of its bad geometry.
// after setting up this much, something in UIKit is scrolling to keep field visible. good enough and i'm
// not going to spend time on it

extension EditViewController {
    
    func setupToScrollWhenKeyboardAppears() {
        guard let view = view else { return }
        keyboardDismissalTapRecognizer.addTarget(view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(keyboardDismissalTapRecognizer)
        
        contentViewCoordinates = contentView.frame.origin
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardOnScreen), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardOffScreen), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc func keyboardOnScreen(_ notification: NSNotification) {
        guard let info = notification.userInfo as NSDictionary?,
            let nsValue = info.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue else {
            return
        }
        let kbHeight = nsValue.cgRectValue.size.height
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: kbHeight, right: 0.0)
        
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardOffScreen(_ notification: NSNotification){
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
}
