//
//  FightViewController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-30.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class FightViewController: UITableViewController {
    
    @IBOutlet var blankFooter: UIView!
    @IBOutlet var roundNFooter: UIView!
    @IBOutlet var roundNFooterLabel: UILabel!
    @IBOutlet var finishedFooter: UIView!
    @IBOutlet var finishedSingularLabel: UILabel!
    @IBOutlet var finishedPluralLabel: UILabel!
    
    // public properties:
    
    // this list of combat results is essentially the view model
    var battleResult: Transformer.BattleResult! {
        didSet {
            if isViewLoaded {
                configure()
            }
        }
    }
    
    // private properties:
    
    var autobotsIcon: String?
    var decepticonsIcon: String?
    var roundNFooterLabelTemplate = ""
    var finishedPluralLabelTemplate = ""
    var transparentFooter: UIView!
    var numberOfRounds = 0
    var showingRound = 0               // counting from 1 like the UI does, ie. 2 means showing results from rounds 1 & 2
    var showingFinalResults = false
    var noCombatants = false
    var showBattle = false
    var roundsTimer: Timer?
    var desiredInterval: TimeInterval = FightViewController.slowTimeInterval
    static let slowTimeInterval: TimeInterval = 1.5
    static let fastTimeInterval: TimeInterval = 0.25
    
    override func viewDidLoad() {
        roundNFooterLabelTemplate = roundNFooterLabel.text ?? ""
        finishedPluralLabelTemplate = finishedPluralLabel.text ?? ""
        
        transparentFooter = UIView()
        
        if battleResult != nil {
            configure()
        }
    }
    
    func configure() {
        // seeing that icons come from the set of combatants, i deliberately designed the ui so that
        // if there are no transformers from one team or the other, then icon isn't needed to be displayed
        
        let autobot = battleResult.startingAutobots.first(where: { $0.team == .autobots })
        let decepticon = battleResult.startingDecepticons.first(where: { $0.team == .decepticons })
        
        if let autobot = autobot {
            autobotsIcon = autobot.teamIcon
        }
        if let decepticon = decepticon {
            decepticonsIcon = decepticon.teamIcon
        }
        
        showingRound = 0
        numberOfRounds = battleResult.roundResults.count
        showingFinalResults = false
        showBattle = false
        noCombatants = battleResult.startingAutobots.isEmpty && battleResult.startingDecepticons.isEmpty
        
        assert((battleResult.finalOutcome == nil) == battleResult.roundResults.isEmpty, "Inconsistent battle results state can't be displayed.")
        
        tableView.reloadData()
    }
    
    func startRoundsTimer(withInterval interval: TimeInterval? = nil) {
        print("(re)starting timer, interval is \((interval ?? desiredInterval) > 0.25 ? "slow" : "fast")")
        roundsTimer = Timer.scheduledTimer(withTimeInterval: interval ?? desiredInterval, repeats: true) { [weak self] timer in
            guard let self = self, self.showingRound < self.numberOfRounds || !self.showingFinalResults else {
                // test above checks to see if called extra times, action func below causes
                // and i thought it was better to allow it and detect case here over putting sanity check there
                timer.invalidate()
                return
            }
            if self.showingRound < self.numberOfRounds {
                self.showingRound += 1
                print("timer fired - showing round \(self.showingRound)")
            } else if self.showingRound >= self.numberOfRounds {
                self.showingFinalResults = true
                timer.invalidate()
                print("timer fired - showing final results, stopping timer")
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func speedUpRoundsTimer(_ sender: UIBarButtonItem) {
        desiredInterval = FightViewController.fastTimeInterval
        if let timer = roundsTimer, timer.isValid {
            roundsTimer?.invalidate()
            startRoundsTimer(withInterval: desiredInterval)
        }
    }
    
    @IBAction func start(_ sender: UIControl) {
        startRoundsTimer()
        
        showBattle = true
        tableView.reloadData()
    }
    
    
    // MARK: - data source and delegate functions
    // state of table view is given by `combatants` nil or not, timer started or not, counter `showingRound`
    // with values 0 to `finalRowCount`, and `showingFinalResults`. the code below maps these state values
    // and the battle results into the right set of sections, rows, footers to show
    // this was horrendous to do and error-prone, hence all the verbose assertions below. i would want to
    // do this differently with a function that has one case for every state which call it from each of
    // these methods, returning a tuple of data that's used to produce the same output
    //
    // made somewhat simpler by showing battle with no rounds (ie. vs no opponents) as a special case
    // instead of trying to support a final results sometimes in the second section, sometimes the third.
    // that eliminated many #rounds==0 / #rounds>0 conditions, plus supporting that made no sense anyway.
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if battleResult == nil || noCombatants {
            return 0
        } else if !showBattle {
            return 1                                // before battle displayed, just the lineup section
        } else if showingRound == 0 {
            return 1                                // again show lineup section only before first round shown..
        } else if !showingFinalResults {
            return 2                                // ..then also show the rounds results section..
        } else if showingFinalResults {
            return 3                                // ..and the final results section when its needed
        } else {
            assertionFailure("Expected logic above to cover all cases")
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && battleResult.roundResults.isEmpty {
            return 2
        } else if section == 0 && !showBattle {
            return 2                                // section 0 has the line up, initially it has a second row with start button
        } else if section == 0 && showBattle {
            return 1                                // after pressed, hide the button row
        } else if section == 1 {
            return showingRound                     // section 1 instead has one row for each rounds showing
        } else if section == 2 {
            return 1                                // section 2 has only the final results row
        } else {
            assertionFailure("Expected logic above to cover all cases")
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell = createLineUpCell()
            } else if indexPath.row == 1 && battleResult.roundResults.isEmpty {
                cell = createTeamsNotReadyCell()
            } else if indexPath.row == 1 {
                cell = createStartButtonCell()
            } else {
                assertionFailure("Unexecpted row \(indexPath.row) in section 0")
            }
            
        } else if indexPath.section == 1 {
            if indexPath.row < numberOfRounds {
                let roundResult = battleResult.roundResults[indexPath.row]
                switch roundResult.outcome {
                case .autobotWin, .decepticonWin:
                    cell = createWinnerCell(withRoundResult: roundResult)
                case .tie:
                    cell = createTieCell(withRoundResult: roundResult)
                case .destruction:
                    cell = createAnnihilationCell(withRoundResult: roundResult)
                }
            } else {
                assertionFailure("Unexecpted row \(indexPath.row) in section 1")
            }
            
        } else if indexPath.section == 2 {
            if showingFinalResults && indexPath.row == 0 {
                switch battleResult.finalOutcome! { // ok to force unwrap b/c should not have been a section 2 if nil
                case .autobotWin:
                    cell = createAutobotsWinCell()
                case .decepticonWin:
                    cell = createDecepticonsWinCell()
                case .tie:
                    cell = createTeamsTieCell()
                case .destruction:
                    cell = createTeamsDestroyedCell()
                }
            } else if !showingFinalResults {
                assertionFailure("Unexecpted section being show \(indexPath.section)")
            } else {
                assertionFailure("Unexecpted row \(indexPath.row) in section \(indexPath.section)")
            }
        }
        assert(cell != nil, "Expected logic above to cover all cases")
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 && !showBattle {
            return transparentFooter
            
        // after fight button pressed, top section shows footer announcing round 1, after more rounds change footer to a blank bar
        } else if section == 0 && showingRound == 0 {
            roundNFooterLabel.text = String(format: roundNFooterLabelTemplate, "1")
            return roundNFooter
        } else if section == 0 && showingRound > 0 {
            return blankFooter
            
        // for each round except the last round, rounds section show footer announcing the next round
        } else if section == 1 && showingRound < numberOfRounds {
            roundNFooterLabel.text = String(format: roundNFooterLabelTemplate, String(showingRound + 1))
            return roundNFooter
            
        } else if section == 1 && showingRound == numberOfRounds {
            if numberOfRounds == 1 {
                finishedSingularLabel.isHidden = false
                finishedPluralLabel.isHidden = true
            } else {
                finishedSingularLabel.isHidden = true
                finishedPluralLabel.isHidden = false
                finishedPluralLabel.text = String(format: finishedPluralLabelTemplate, String(numberOfRounds))
            }
            return finishedFooter
        
        } else if section == 2 {
            return transparentFooter
        } else {
            return nil
        }
    }
    
    // MARK: - helpers for each cell
    
    func createLineUpCell() -> FightLineUpCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FightLineUpCell.cellReuseIdentifier), let lineUpCell = cell as? FightLineUpCell else {
            assertionFailure("Could not dequeue FightLineUpCell")
            return nil
        }
        lineUpCell.autobotsIcon.setTransformerIcon(withURLString: autobotsIcon)
        lineUpCell.decepticonsIcon.setTransformerIcon(withURLString: decepticonsIcon)
        fillStackView(lineUpCell.autobotNameStack, withNames: battleResult.startingAutobots.map(\.name))
        fillStackView(lineUpCell.decepticonNameStack, withNames: battleResult.startingDecepticons.map(\.name))
        return lineUpCell
    }
    
    func createTeamsNotReadyCell() -> UITableViewCell? {
        return tableView.dequeueReusableCell(withIdentifier: "TeamsNotReadyCell")
    }
    
    func createStartButtonCell() -> UITableViewCell? {
        return tableView.dequeueReusableCell(withIdentifier: "StartButtonCell")
    }
    
    func createWinnerCell(withRoundResult roundResult: Transformer.RoundResult) -> WinnerCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WinnerCell.cellReuseIdentifier), let winnerCell = cell as? WinnerCell else {
            assertionFailure("Could not dequeue WinnerCell")
            return nil
        }
        winnerCell.teamIcon.image = nil
        if case .autobotWin = roundResult.outcome {
            winnerCell.teamIcon.setTransformerIcon(withURLString: autobotsIcon)
            winnerCell.autobotWinLabel.isHidden = false
            winnerCell.decepticonWinLabel.isHidden = true
            winnerCell.autobotDefeatsLabel.isHidden = false
            winnerCell.autobotDefeatedByLabel.isHidden = true
        } else {
            winnerCell.teamIcon.setTransformerIcon(withURLString: decepticonsIcon)
            winnerCell.autobotWinLabel.isHidden = true
            winnerCell.decepticonWinLabel.isHidden = false
            winnerCell.autobotDefeatsLabel.isHidden = true
            winnerCell.autobotDefeatedByLabel.isHidden = false
        }
        winnerCell.autobotName.text = roundResult.autobot.name
        winnerCell.decepticonName.text = roundResult.decepticon.name
        return winnerCell
    }
    
    func createTieCell(withRoundResult roundResult: Transformer.RoundResult) -> TieCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TieCell.cellReuseIdentifier), let tieCell = cell as? TieCell else {
            assertionFailure("Could not dequeue TieCell")
            return nil
        }
        tieCell.autobotsIcon.setTransformerIcon(withURLString: autobotsIcon)
        tieCell.decepticonsIcon.setTransformerIcon(withURLString: decepticonsIcon)
        tieCell.autobotName.text = roundResult.autobot.name
        tieCell.decepticonName.text = roundResult.decepticon.name
        return tieCell
    }
    
    func createAnnihilationCell(withRoundResult roundResult: Transformer.RoundResult) -> AnnihilationCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AnnihilationCell.cellReuseIdentifier), let annihilationCell = cell as? AnnihilationCell else {
            assertionFailure("Could not dequeue AnnihilationCell")
            return nil
        }
        annihilationCell.autobotName.text = roundResult.autobot.name
        annihilationCell.decepticonName.text = roundResult.decepticon.name
        return annihilationCell
    }
    
    func createAutobotsWinCell() -> AutobotsWinCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutobotsWinCell.cellReuseIdentifier), let autobotsWinCell = cell as? AutobotsWinCell else {
            assertionFailure("Could not dequeue AutobotsWinCell")
            return nil
        }
        autobotsWinCell.autobotsIcon.setTransformerIcon(withURLString: autobotsIcon)
        fillStackView(autobotsWinCell.autobotNameStack, withNames: battleResult.autobotSurvivors.map(\.name))
        fillStackView(autobotsWinCell.decepticonNameStack, withNames: battleResult.decepticonSurvivors.map(\.name))
        return autobotsWinCell
    }
    
    func createDecepticonsWinCell() -> DecepticonsWinCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DecepticonsWinCell.cellReuseIdentifier), let decepticonsWinCell = cell as? DecepticonsWinCell else {
            assertionFailure("Could not dequeue DecepticonsWinCell")
            return nil
        }
        decepticonsWinCell.decepticonsIcon.setTransformerIcon(withURLString: decepticonsIcon)
        fillStackView(decepticonsWinCell.autobotNameStack, withNames: battleResult.autobotSurvivors.map(\.name))
        fillStackView(decepticonsWinCell.decepticonNameStack, withNames: battleResult.decepticonSurvivors.map(\.name))
        return decepticonsWinCell
    }
    
    func createTeamsTieCell() -> TeamsTieCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TeamsTieCell.cellReuseIdentifier), let teamsTieCell = cell as? TeamsTieCell else {
            assertionFailure("Could not dequeue TeamsTieCell")
            return nil
        }
        teamsTieCell.autobotsIcon.setTransformerIcon(withURLString: autobotsIcon)
        teamsTieCell.decepticonsIcon.setTransformerIcon(withURLString: decepticonsIcon)
        fillStackView(teamsTieCell.autobotNameStack, withNames: battleResult.autobotSurvivors.map(\.name))
        fillStackView(teamsTieCell.decepticonNameStack, withNames: battleResult.startingDecepticons.map(\.name))
        return teamsTieCell
    }
    
    func createTeamsDestroyedCell() -> TeamsDestroyedCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TeamsDestroyedCell.cellReuseIdentifier), let teamsDestroyedCell = cell as? TeamsDestroyedCell else {
            assertionFailure("Could not dequeue TeamsDestroyedCell")
            return nil
        }
        return teamsDestroyedCell
    }
    
    // MARK: -
    
    func fillStackView(_ stackView: UIStackView, withNames names: [String]) {
        let titles = names.isEmpty ? ["-"] : names
        
        // remove excess label views
        while stackView.arrangedSubviews.count > titles.count { // never removes last view b/c count >= 1
            stackView.removeArrangedSubview(stackView.arrangedSubviews.last!)
        }
        
        // add missing label views
        if stackView.arrangedSubviews.count < titles.count, let prototypeLabel = stackView.arrangedSubviews[0] as? UILabel {
            while stackView.arrangedSubviews.count < titles.count {
                let newLabel = UILabel()
                newLabel.font = prototypeLabel.font
                newLabel.textAlignment = prototypeLabel.textAlignment
                stackView.addArrangedSubview(newLabel)
            }
        }
        
        for (label, str) in zip(stackView.arrangedSubviews.compactMap { $0 as? UILabel }, titles) {
            label.text = str
        }
    }
    
}

// MARK: - cells

class FightTableViewCell: UITableViewCell {
    static var cellReuseIdentifier: String { String(describing: self) }
}

class FightLineUpCell: FightTableViewCell {
    @IBOutlet var autobotsIcon: UIImageView!
    @IBOutlet var decepticonsIcon: UIImageView!
    @IBOutlet var autobotNameStack: UIStackView!
    @IBOutlet var decepticonNameStack: UIStackView!
}

class WinnerCell: FightTableViewCell {
    @IBOutlet var teamIcon: UIImageView!
    @IBOutlet var autobotWinLabel: UILabel!
    @IBOutlet var decepticonWinLabel: UILabel!
    @IBOutlet var autobotDefeatsLabel: UILabel!
    @IBOutlet var autobotDefeatedByLabel: UILabel!
    @IBOutlet var autobotName: UILabel!
    @IBOutlet var decepticonName: UILabel!
}

class TieCell: FightTableViewCell {
    @IBOutlet var autobotsIcon: UIImageView!
    @IBOutlet var decepticonsIcon: UIImageView!
    @IBOutlet var autobotName: UILabel!
    @IBOutlet var decepticonName: UILabel!
}

class AnnihilationCell: FightTableViewCell {
    @IBOutlet var autobotName: UILabel!
    @IBOutlet var decepticonName: UILabel!
}

class AutobotsWinCell: FightTableViewCell {
    @IBOutlet var autobotsIcon: UIImageView!
    @IBOutlet var autobotNameStack: UIStackView!
    @IBOutlet var decepticonNameStack: UIStackView!
}

class DecepticonsWinCell: FightTableViewCell {
    @IBOutlet var decepticonsIcon: UIImageView!
    @IBOutlet var autobotNameStack: UIStackView!
    @IBOutlet var decepticonNameStack: UIStackView!
}

class TeamsTieCell: FightTableViewCell {
    @IBOutlet var autobotsIcon: UIImageView!
    @IBOutlet var decepticonsIcon: UIImageView!
    @IBOutlet var autobotNameStack: UIStackView!
    @IBOutlet var decepticonNameStack: UIStackView!
}

class TeamsDestroyedCell: FightTableViewCell {
}
