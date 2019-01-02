//
//  CCNoteModel.swift
//  CCPianoUtilsModule
//
//  Created by Calin Chitu on 30/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

public struct CCNoteModel {
    
    /*
     
     21  = A left edge
     108 = C right edge
     
     24 = c1, 36 = c2, 48 = c3, 60 = c4, 72 = c5, 84 = c6, 96 = c7, 108 =  C8
     
     */
    let accDic = ["", "#", "b"]
    let noteDic = ["C", "D", "E", "F", "G", "A", "B"]
    
    public var velocity: Int = 50
    public var ignoreOctave: Bool = false
    
    public var emptyNote: Bool = false {
        didSet {
            if emptyNote == true {
                note = ""
                accidental = ""
                emptyNote = true
                octave = 0
                bass = (Int(arc4random_uniform(2)) == 0) ? true : false
            }
        }
    }
    
    public var note: String = "C" {
        didSet {
        }
    }
    public var octave: Int = 4 {
        didSet {
            if octave < 2 && note == "B" { octave = 1 }
            if octave < 2 && note != "B" { octave = 2 }
            if octave > 7 && note != "D" { octave = 7 }
            if octave > 7 && note == "D" { octave = 8 }
            
            switch (octave, emptyNote) {
            case (1...3, _):
                bass = true
            case (5...8, _):
                bass = false
            case (4, false):
                bass = noteDic.index(of: note)! < 4
            default:
                break
            }
        }
    }
    public var accidental: String = "" {
        didSet {
            switch (note, accidental, octave) {
            case ("E", "#", _), ("B", "#", _):
                accidental = ""
            case ("C", "b", _), ("F", "b", _):
                accidental = ""
            case ("G", "b", 4):
                bass = false
            default:
                break
            }
        }
    }
    public var status: Int = 0
    public var bass: Bool = true
    
    public init(randomize: Bool = false, noteArg: String = "C") {
        
        note = noteArg
        if randomize {
            let noteIndex = Int(arc4random_uniform(8)) //set 7 for non empty notes
            if noteIndex > 6 {
                
                note = ""
                accidental = ""
                emptyNote = true
                octave = 0
                bass = (Int(arc4random_uniform(2)) == 0) ? true : false
                return
                
            } else {
                note = noteDic[noteIndex]
            }
            let accIndex  = Int(arc4random_uniform(3))
            accidental = accDic[accIndex]
            self.octave  = Int(arc4random_uniform(9))
        }
        
        if octave < 2 && note == "B" { octave = 1 } else
        if octave < 2 && note != "B" { octave = 2 } else
        if octave > 6 && (note == "C" || note == "D") { octave = 7 } else
        if octave > 6 { octave = 6 }
        
        switch (octave, emptyNote) {
        case (0...3, _):
            bass = true
        case (5...8, _):
            bass = false
        case (4, false):
            bass = noteDic.index(of: note)! < 4
        default:
            break
        }
        
        switch (note, accidental, octave) {
        case ("E", "#", _), ("B", "#", _):
            accidental = ""
        case ("C", "b", _), ("F", "b", _):
            accidental = ""
        case ("G", "b", 4):
            bass = false
        default:
            break
        }
        
    }
    
    public var description: String {
        return "N: \(note), O: \(octave), A: \(accidental), S: \(status), B: \(bass)"
    }
}

extension CCNoteModel: Equatable {
    
    static public func ==(lhs: CCNoteModel, rhs: CCNoteModel) -> Bool {
        if lhs.emptyNote || rhs.emptyNote { return true }
        let matcOctaves = (lhs.ignoreOctave || rhs.ignoreOctave) ? true : lhs.octave == rhs.octave
        return (lhs.note == rhs.note && lhs.accidental == rhs.accidental && matcOctaves)
    }
}
