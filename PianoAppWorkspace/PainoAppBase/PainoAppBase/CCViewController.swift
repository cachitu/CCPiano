//
//  ViewController.swift
//  PainoAppBase
//
//  Created by Calin Chitu on 27/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import UIKit
import CCMidiModule
import CCVirtualPianoModule
import CCMusicScoreModule
import CCPianoUtilsModule

class ViewController: UIViewController {

    let maxNotes: Int = 128
    
    let noteDic: [Int : (std: String, sharp: String, flat: String, rom: String)] = [
        24 : ("C", "  ", "  ", ""),
        25 : ("C", "#", "b", "D"),
        26 : ("D", "  ", "  ", ""),
        27 : ("D", "#", "b", "E"),
        28 : ("E", "  ", "  ", ""),
        29 : ("F", "  ", "  ", ""),
        30 : ("F", "#", "b", "G"),
        31 : ("G", "  ", "  ", ""),
        32 : ("G", "#", "b", "A"),
        33 : ("A", "  ", "  ", ""),
        34 : ("A", "#", "b", "B"),
        35 : ("B", "  ", "  ", "")
    ]
    
    @IBOutlet weak var trebleCollection: UICollectionView!
    @IBOutlet weak var bassCollection: UICollectionView!
    @IBOutlet weak var keyboardCollection: UICollectionView!
    
    @IBOutlet weak var recSwitch: UISwitch!
    @IBOutlet weak var midiSwitch: UISwitch!
    @IBOutlet weak var octavesSw: UISwitch!
    @IBOutlet weak var accentsSw: UISwitch!
    @IBOutlet weak var notesSw: UISwitch!
    @IBOutlet weak var resteSwitch: UISwitch!
    @IBOutlet weak var restartSwitch: UISwitch!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var scrollLockSwitch: UISwitch!
    @IBOutlet weak var dificultySegment: UISegmentedControl!

    
    var localMIDIManagerInstance: CCMIDIManager? = nil
    
    var trebleDataSource: [CCNoteModel] = []
    var bassDataSource: [CCNoteModel] = []
    
    var curentBassIndex: Int = 0
    var curentTrebIndex: Int = 0
    
    var bassMistakes: Int = 0
    var trebleMistakes: Int = 0
    
    var bassCompleted = false {
        didSet { if trebleCompleted && bassCompleted { resetTimer() } }
    }
    var trebleCompleted = false {
        didSet { if bassCompleted && trebleCompleted { resetTimer() } }
    }
    
    var hideLabels = false
    var hideAccidentals = true
    var hideOctaves = true
    var recording = false
    
    var seconds = 0
    var timer = Timer()
    
    var isTimerRunning = false
    var resumeTapped = false
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timerLabel.layer.cornerRadius = 3
        self.localMIDIManagerInstance = CCMIDIManager()
        self.localMIDIManagerInstance?.delegate = self
        self.localMIDIManagerInstance?.initMIDI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardCollection.scrollToItem(at: IndexPath(row: 3, section: 0), at: .centeredHorizontally, animated: true)
        randomDataSource()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func dificutySegmentAction(_ sender: UISegmentedControl) {
        var acc = false
        var oct = false
        switch sender.selectedSegmentIndex {
        case 0:
            acc = false
            oct = false
        case 1:
            acc = true
            oct = false
        case 2:
            acc = false
            oct = true
        case 3:
            acc = true
            oct = true
        default:
            break
        }
        accentsSw.setOn(acc, animated: true)
        octavesSw.setOn(oct, animated: true)
        hideAccidentals = !acc
        hideOctaves = !oct
        reloadNotest()
    }
    
    @IBAction func notesSwitch(_ sender: UISwitch) {
        hideLabels = !sender.isOn
        reloadNotest()
        keyboardCollection.reloadData()
    }
    
    @IBAction func accentsSwitch(_ sender: UISwitch) {
        hideAccidentals = !sender.isOn
        reloadNotest()
    }
    
    @IBAction func octavesSwitch(_ sender: UISwitch) {
        hideOctaves = !sender.isOn
        reloadNotest()
    }
    
    @IBAction func recSwitchAction(_ sender: UISwitch) {
        seconds = 0
        recording = sender.isOn
        resetTimer()
        resteSwitch.isEnabled = !sender.isOn
        restartSwitch.isEnabled = !sender.isOn
        if sender.isOn {
            bassCompleted = false
            trebleCompleted = false
            
            trebleDataSource = []
            bassDataSource = []
            
            bassMistakes = 0
            trebleMistakes = 0
            
            curentBassIndex = 0
            curentTrebIndex = 0
            reloadNotest()
            
        } else {
            if trebleDataSource.count == 0 && bassDataSource.count == 0 {
                seconds = 0
                resetTimer()
                reset()
            } else {
                restartPlaying()
                reloadNotest()
                scrollToIndex(index: 0)
            }
        }
    }
    
    @IBAction func restartSwitchAction(_ sender: UISwitch) {
        seconds = 0
        resetTimer()
        restartPlaying()
    }
    
    @IBAction func resetSwitchAction(_ sender: UISwitch) {
        seconds = 0
        resetTimer()
        reset()
    }
    
    func startTimer() {
        if isTimerRunning == false {
            seconds = 0
            runTimer()
        }
    }
    
    func pauseTimer() {
        if self.resumeTapped == false {
            timer.invalidate()
            isTimerRunning = false
            self.resumeTapped = true
        } else {
            runTimer()
            self.resumeTapped = false
            isTimerRunning = true
        }
    }
    
    func resetTimer() {
        
        timer.invalidate()
        updateTimerLabel()
        isTimerRunning = false
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
        isTimerRunning = true
    }
    
    @objc func updateTimer() {
        if seconds < 0 {
            timer.invalidate()
        } else {
            seconds += 1
            updateTimerLabel()
        }
    }
    
    func updateTimerLabel() {
        timerLabel.text = timeString(time: TimeInterval(seconds)) + " (Penalty: \((trebleMistakes + bassMistakes) * 1))"
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    private func randomDataSource() {
        
        bassCompleted = false
        trebleCompleted = false
        
        trebleDataSource = []
        bassDataSource = []
        
        curentBassIndex = 0
        curentTrebIndex = 0
        
        bassMistakes = 0
        trebleMistakes = 0
        
        reloadNotest()
        
        var bstatSet = false
        var tstatSet = false
        
        for _ in 0..<maxNotes*2 {
            
            var aNote = CCNoteModel(randomize: true)
            aNote.status = 0
            if aNote.bass {
                if aNote.emptyNote && !bstatSet {
                    curentBassIndex += 1
                } else if !bstatSet {
                    aNote.status = 1
                    bstatSet = true
                }
                bassDataSource.append(aNote)
            } else {
                if aNote.emptyNote && !tstatSet {
                    curentTrebIndex += 1
                } else if !tstatSet {
                    aNote.status = 1
                    tstatSet = true
                }
                trebleDataSource.append(aNote)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.handleUnbalancedData()
            self.resteSwitch.setOn(false, animated: true)
            self.updateTimerLabel()
        }
    }
    
    func scrollToIndex(index: Int) {
        
        guard index < bassCollection.numberOfItems(inSection: 0) else {
            return
        }
        guard index < trebleCollection.numberOfItems(inSection: 0) else {
            return
        }
        
        bassCollection.scrollToItem(at: IndexPath(row: index, section: 0) , at: .left, animated: true)
        trebleCollection.scrollToItem(at: IndexPath(row: index, section: 0) , at: .left, animated: true)
    }
    
    func restartPlaying() {
        
        var bstatSet = false
        var tstatSet = false
        
        bassCompleted = false
        trebleCompleted = false
        curentBassIndex = 0
        curentTrebIndex = 0
        bassMistakes = 0
        trebleMistakes = 0
        
        for i in 0..<trebleDataSource.count {
            trebleDataSource[i].status = 0
            if trebleDataSource[i].emptyNote && !tstatSet {
                curentTrebIndex += 1
            } else if !tstatSet {
                trebleDataSource[i].status = 1
                tstatSet = true
            }
        }
        for i in 0..<bassDataSource.count {
            bassDataSource[i].status = 0
            if bassDataSource[i].emptyNote && !bstatSet {
                curentBassIndex += 1
            } else if !bstatSet {
                bassDataSource[i].status = 1
                bstatSet = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.reloadNotest()
            self.scrollToIndex(index: 0)
            self.restartSwitch.setOn(false, animated: true)
            self.updateTimerLabel()
        }
    }
    
    func reset() {
        randomDataSource()
    }
    
    func reloadNotest() {
        let indexSet = IndexSet([0])
        trebleCollection.reloadSections(indexSet)
        bassCollection.reloadSections(indexSet)
    }
    
    func handleRecording(note: CCNoteModel) {
        
        var emptyNote = CCNoteModel()
        emptyNote.emptyNote = true

        if note.bass {
            bassDataSource.append(note)
            emptyNote.bass = false
            trebleDataSource.append(emptyNote)
        } else {
            trebleDataSource.append(note)
            emptyNote.bass = true
            bassDataSource.append(emptyNote)
        }
        
        reloadNotest()
        scrollToIndex(index: max(bassDataSource.count - 1, trebleDataSource.count - 1))
    }
    
    func handleUnbalancedData() {
        
        let bItems = bassDataSource.count
        let tItems = trebleDataSource.count
        
        guard bItems != tItems else {
            reloadNotest()
            return
        }
        if bItems > tItems {
            for _ in 0..<bItems-tItems {
                var emptyNote = CCNoteModel()
                emptyNote.emptyNote = true
                emptyNote.bass = false
                trebleDataSource.append(emptyNote)
            }
        } else {
            for _ in 0..<tItems-bItems {
                var emptyNote = CCNoteModel()
                emptyNote.emptyNote = true
                emptyNote.bass = true
                bassDataSource.append(emptyNote)
            }
        }
        reloadNotest()
    }
    
    func handleMatch(note: CCNoteModel, or: CCNoteModel?) {
        
        guard !recording else {
            handleRecording(note: note)
            return
        }
        
        if curentBassIndex == bassDataSource.count {
            curentBassIndex -= 1
            bassCompleted = true
        }
        if curentTrebIndex == trebleDataSource.count {
            curentTrebIndex -= 1
            trebleCompleted = true
        }
        
        if bassCompleted && trebleCompleted {
            resetTimer()
        } else {
            startTimer()
        }
        
        
        var noteBassToMatch: CCNoteModel = bassDataSource[curentBassIndex]
        var noteTrebToMatch: CCNoteModel = trebleDataSource[curentTrebIndex]
        
        var lastVisbleBassIndex: Int = 0
        for cell in bassCollection.visibleCells {
            if let indexPath = bassCollection.indexPath(for: cell) {
                lastVisbleBassIndex = max(indexPath.item, lastVisbleBassIndex)
            }
        }
        
        var lastVisbleTrebleIndex: Int = 0
        for cell in trebleCollection.visibleCells {
            if let indexPath = trebleCollection.indexPath(for: cell) {
                lastVisbleTrebleIndex = max(indexPath.item, lastVisbleTrebleIndex)
            }
        }
        
        var vnote = note
        var vsecond = or
        
        if hideAccidentals {
            noteBassToMatch.accidental = ""
            noteTrebToMatch.accidental = ""
        }
        
        if hideOctaves {
            noteBassToMatch.ignoreOctave = true
            noteTrebToMatch.ignoreOctave = true
        }
        
        if note.octave == 4 && note.note == "F" && note.accidental == "#" {
            vnote.bass = true
        }
        
        if note.octave == 4 && note.note == "G" && note.accidental == "b" {
            vnote.bass = false
        }

        if vsecond?.octave == 4 && vsecond?.note == "F" && vsecond?.accidental == "#" {
            vsecond?.bass = true
        }
        
        if or?.octave == 4 && or?.note == "G" && or?.accidental == "b" {
            vsecond?.bass = false
        }
        
        var bassMatched = false
        var trebleMatched = false
        var bassTested = false
        
        if vnote.bass {
            bassTested = true
            if noteBassToMatch == vnote {
                bassMatched = true
            } else if let second = vsecond, noteBassToMatch == second  {
                bassMatched = true
            } else {
                bassMistakes += 1
            }
            if let second = vsecond, second.bass == false, noteTrebToMatch == second {
                trebleMatched = true
            }
        } else {
            if noteTrebToMatch == note {
                trebleMatched = true
            }
            else if let second = vsecond, noteTrebToMatch == second  {
                trebleMatched = true
            } else {
                trebleMistakes += 1
            }
            if let second = vsecond, second.bass == true, noteBassToMatch == second {
                bassMatched = true
            }
        }
        updateTimerLabel()
        
        if bassMatched {
            guard !bassCompleted else { return }
            bassDataSource[curentBassIndex].status = 3
            bassDataSource[curentBassIndex].velocity = note.velocity
            bassCollection.reloadItems(at: [IndexPath(row: curentBassIndex, section: 0)])
            guard curentBassIndex < bassDataSource.count - 1 else {
                bassCompleted = true
                return
            }
            while bassDataSource[curentBassIndex + 1].emptyNote {
                curentBassIndex += 1
                if (curentBassIndex == bassDataSource.count - 1) {
                    bassCompleted = true
                    return
                }
            }
            bassDataSource[curentBassIndex + 1].status = 1
            bassCollection.reloadItems(at: [IndexPath(row: curentBassIndex + 1, section: 0)])
            curentBassIndex += 1
        }
        if trebleMatched {
            guard !trebleCompleted else { return }
            trebleDataSource[curentTrebIndex].status = 3
            trebleDataSource[curentTrebIndex].velocity = note.velocity
            trebleCollection?.reloadItems(at: [IndexPath(row: curentTrebIndex, section: 0)])
            guard curentTrebIndex < trebleDataSource.count - 1 else {
                trebleCompleted = true
                return
            }
            while trebleDataSource[curentTrebIndex + 1].emptyNote {
                curentTrebIndex += 1
                if (curentTrebIndex == trebleDataSource.count - 1) {
                    trebleCompleted = true
                    return
                }
            }
            trebleDataSource[curentTrebIndex + 1].status = 1
            trebleCollection?.reloadItems(at: [IndexPath(row: curentTrebIndex + 1, section: 0)])
            curentTrebIndex += 1
        } else if bassTested {
            guard !bassCompleted else { return }
            bassDataSource[curentBassIndex].status = 2
            bassCollection.reloadItems(at: [IndexPath(row: curentBassIndex, section: 0)])
        } else {
            guard !trebleCompleted else { return }
            trebleDataSource[curentTrebIndex].status = 2
            trebleCollection.reloadItems(at: [IndexPath(row: curentTrebIndex, section: 0)])
        }
        
        if curentBassIndex >= lastVisbleBassIndex || curentBassIndex < lastVisbleBassIndex - bassCollection.visibleCells.count {
            if vnote.bass { scrollToIndex(index: scrollLockSwitch.isOn ? min(curentBassIndex, curentTrebIndex) : curentBassIndex) }
        }
        
        if curentTrebIndex >= lastVisbleTrebleIndex || curentTrebIndex < lastVisbleTrebleIndex - trebleCollection.visibleCells.count {
            if !vnote.bass { scrollToIndex(index: scrollLockSwitch.isOn ? min(curentBassIndex, curentTrebIndex) : curentTrebIndex) }
        }
    }
}

extension ViewController : UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let isKeyboard = (collectionView == keyboardCollection)
        let isBass = (collectionView == bassCollection)
        return isKeyboard ? 7 : isBass ? bassDataSource.count : trebleDataSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let isKeyboard = (collectionView == keyboardCollection)
        
        if isKeyboard {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CCPianoKeyCell.cellID, for: indexPath) as? CCPianoKeyCell else { return UICollectionViewCell() }
            cell.pianoKeyboardView.delegate = self
            cell.pianoKeyboardView.octaveValue = indexPath.item + 1
            switch indexPath.item {
            case 0...2:
                cell.pianoKeyboardView.isBass = true
            case 3:
                cell.pianoKeyboardView.isMiddleType = true
            default:
                cell.pianoKeyboardView.isTreble = true
            }
            cell.pianoKeyboardView.hideLabels = hideLabels
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CCNoteCell.cellID, for: indexPath) as? CCNoteCell else { return UICollectionViewCell() }
        if let cellNoteView = cell.noteView {
            let isTreble = (collectionView == trebleCollection)
            let noteModel = (isTreble) ? trebleDataSource[indexPath.item] : bassDataSource[indexPath.item]
            cellNoteView.hideLabels = hideLabels
            cellNoteView.hideAccidentals = hideAccidentals
            cellNoteView.hideOctaves = hideOctaves
            cellNoteView.noteModel = noteModel
        }
        
        return cell
    }
    
}

extension ViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CCNoteCell {
            print(cell.noteView.noteModel.description)
            let isTreble = (collectionView == trebleCollection)
            let noteModel = (isTreble) ? trebleDataSource[indexPath.item] : bassDataSource[indexPath.item]
            var index = CCNotePlayer.indexFromModel(noteModel: noteModel)
            switch (hideAccidentals, noteModel.accidental) {
            case (true, "#"):
                index -= 1
            case (true, "b"):
                index += 1
            default:
                break
            }
            self.localMIDIManagerInstance?.playNoteOn(0, noteNum: UInt32(index), velocity: UInt32(noteModel.velocity))
        }
    }
}

extension ViewController : CCPianoOctaveProtocol {
    
    func didPressNote(note: CCNoteModel, or: CCNoteModel?) {
        let index = CCNotePlayer.indexFromModel(noteModel: note)
        self.localMIDIManagerInstance?.playNoteOn(0, noteNum: UInt32(index), velocity: UInt32(note.velocity))
        handleMatch(note: note, or: or)
    }
}

extension ViewController : CCMidiManagerProtocol {
    
    func didPlayNoteOn(_ channel:UInt32, noteNum:UInt32, velocity:UInt32) {
        
        guard midiSwitch.isOn else { return }
        guard velocity > 0 else { return }
        
        var octave = 1
        var noteInt = Int(noteNum)
        
        if  24...35 ~= noteInt {
        } else if noteInt < 24 {
            while noteInt < 24 {
                noteInt += 12
                octave  -= 1
            }
        } else {
            while noteInt > 35 {
                noteInt -= 12
                octave  += 1
            }
        }
        
        if let dicval = self.noteDic[noteInt] {
            switch noteInt {
            case 25, 27, 30, 32, 34:

                var lnote = CCNoteModel(randomize: false, noteArg: dicval.std)
                lnote.note = dicval.std
                lnote.accidental = dicval.sharp
                lnote.octave = octave
                lnote.velocity = Int(velocity)
                
                var rnote = CCNoteModel(randomize: false, noteArg: dicval.rom)
                rnote.note = dicval.rom
                rnote.accidental = dicval.flat
                rnote.octave = octave
                rnote.velocity = Int(velocity)
                
                handleMatch(note: rnote, or: lnote)
                
            default:

                var note = CCNoteModel(randomize: false, noteArg: dicval.std)
                note.note = dicval.std
                note.accidental = ""
                note.octave = octave
                
                handleMatch(note: note, or: nil)
            }
        }
    }
    
    func didPlayNoteOff(_ channel:UInt32, noteNum:UInt32) {
    }
    
}


