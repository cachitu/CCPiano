//
//  CCVirtualPianoKeyView.swift
//  CCVirtualPianoModule
//
//  Created by Calin Chitu on 27/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import CCPianoUtilsModule

protocol CCPianoKeyProtocol: class {
    func didPressNote(note: CCNoteModel, or: CCNoteModel?)
}

@IBDesignable
class CCVirtualPianoKeyView: UIView {
    
    private weak var view: UIView!
    
    public weak var delegate: CCPianoKeyProtocol?
    
    @IBOutlet weak var butMain: UIButton!
    @IBOutlet weak var butFlat: UIButton!
    @IBOutlet weak var butSharp: UIButton!
    
    @IBInspectable var isTrebleKey: Bool = false {
        didSet {
            guard isTrebleKey else { return }
            isBassKey = false
            let trebleKeyColor = UIColor(red: 244.0 / 255.0, green: 255.0 / 255.0, blue: 244.0 / 255.0, alpha: 1)
            butMain.backgroundColor = trebleKeyColor
        }
    }
    
    @IBInspectable var isBassKey: Bool = false {
        didSet {
            guard isBassKey else { return }
            isTrebleKey = false
            let bassKeyColor = UIColor(red: 255.0 / 255.0, green: 244.0 / 255.0, blue: 244.0 / 255.0, alpha: 1)
            butMain.backgroundColor = bassKeyColor
        }
    }
    
    @IBInspectable var octaveValue: Int = 0 {
        didSet {
            butMain.setTitle(keyString + "\(octaveValue)", for: .normal)
        }
    }
    
    /*
     
     21  = A left edge
     108 = C right edge
     
     24 = c1, 36 = c2, 48 = c3, 60 = c4, 57 = c5, 84 = c6, 96 = c7
     
     */
    
    @IBInspectable var midiValue: Int = 21 {
        didSet {
            guard  21...108 ~= midiValue else {
                midiValue = 21
                return
            }
            
            var octave = 1
            var noteInt = Int(midiValue)
            
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
            
            //let data = notesMapping[noteInt]
            
            octaveValue = octave
        }
    }
    
    @IBInspectable var showLabels: Bool = true {
        didSet {
            let color: UIColor = showLabels ? .black : .clear
            butMain.setTitleColor(color, for: .normal)
        }
    }
    
    @IBInspectable var keyString: String = "C" {
        didSet {
            butMain.setTitle(keyString, for: .normal)
            switch keyString {
            case "C", "F":
                butSharp.isHidden = false
                butFlat.isHidden = true
                break
            case "B", "E":
                butSharp.isHidden = true
                butFlat.isHidden = false
            default:
                butSharp.isHidden = false
                butFlat.isHidden = false
            }
        }
    }

    @IBAction func butMain(_ sender: UIButton) {
        //print(keyString + " - \(octaveValue) - bass: \(isBassKey)")
        var note = CCNoteModel()
        note.note = keyString
        note.octave = octaveValue
        note.bass = isBassKey
        delegate?.didPressNote(note: note, or: nil)
    }
    
    @IBAction func butFlat(_ sender: UIButton) {
        //print(keyString + "b" + " - \(octaveValue) - bass: \(isBassKey)")
        //print(neighbourNotes(keyString).left + "#")
        
        var note = CCNoteModel()
        note.note = keyString
        note.octave = octaveValue
        note.bass = isBassKey
        note.accidental = "b"
        
        var note2 = CCNoteModel()
        note2.note = neighbourNotes(keyString).left
        note2.octave = octaveValue
        note2.bass = isBassKey
        note2.accidental = "#"
        
        delegate?.didPressNote(note: note, or: note2)
    }
    
    @IBAction func butSharp(_ sender: UIButton) {
        //print(keyString + "#" + " - \(octaveValue) - bass: \(isBassKey)")
        //print(neighbourNotes(keyString).right + "b")
        
        var note = CCNoteModel()
        note.note = keyString
        note.octave = octaveValue
        note.bass = isBassKey
        note.accidental = "#"
        
        var note2 = CCNoteModel()
        note2.note = neighbourNotes(keyString).right
        note2.octave = octaveValue
        note2.bass = isBassKey
        note2.accidental = "b"
        
        delegate?.didPressNote(note: note, or: note2)
    }

    
    
    public override required init(frame: CGRect) {
        super.init(frame: frame)
        view = loadFromNib(withOwner: self)
        self.addSubview(view)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        view = loadFromNib(withOwner: self)
        self.addSubview(view)
        configure()
    }
    
    private func configure() {
        keyString = "C"
        butSharp.setTitleColor(.clear, for: .normal)
        butFlat.setTitleColor(.clear, for: .normal)
        butMain.layer.cornerRadius = 4
        butMain.layer.borderWidth = 0.5
        butMain.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        butSharp.layer.cornerRadius = 4
        butFlat.layer.cornerRadius = 4
    }
    
    private func loadFromNib(withOwner: UIView) -> UIView {
        
        let bundle = Bundle(for: CCVirtualPianoKeyView.self)
        let view = viewFromNib(withOwner: withOwner, bundle: bundle)
        
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }
    
    private func viewFromNib(withOwner: UIView, bundle: Bundle) -> UIView {
        
        let nib = UINib(nibName: "\(type(of: withOwner))", bundle: bundle)
        let view = nib.instantiate(withOwner: withOwner, options: nil).first as! UIView
        return view
    }
    
    private func neighbourNotes(_ note: String) -> (left: String, right: String) {
        
        switch note {
        case "A":
            return (left: "G", right: "B")
        case "B":
            return (left: "A", right: "C")
        case "C":
            return (left: "B", right: "D")
        case "D":
            return (left: "C", right: "E")
        case "E":
            return (left: "D", right: "F")
        case "F":
            return (left: "E", right: "G")
        case "G":
            return (left: "F", right: "A")
        default:
            return (left: "", right: "")
        }
    }
    
    let notesMapping: [Int : (std: String, sharp: String, flat: String, rom: String)] = [
        24 : ("C", "  ", "  ", "Do"),
        25 : ("C#", "C#", "Db", "  "),
        26 : ("D", "  ", "  ", "Re"),
        27 : ("D#", "D#", "Eb", "  "),
        28 : ("E", "  ", "  ", "Mi"),
        29 : ("F", "  ", "  ", "Fa"),
        30 : ("F#", "F#", "Gb", "  "),
        31 : ("G", "  ", "  ", "So"),
        32 : ("G#", "G#", "Ab", "  "),
        33 : ("A", "  ", "  ", "La"),
        34 : ("A#", "A#", "Bb", "  "),
        35 : ("B", "  ", "  ", "Si")
    ]


}
