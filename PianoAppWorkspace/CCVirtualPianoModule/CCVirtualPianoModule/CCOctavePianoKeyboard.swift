//
//  CCOctavePianoKeyboard.swift
//  CCVirtualPianoModule
//
//  Created by Calin Chitu on 27/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import CCPianoUtilsModule

public protocol CCPianoOctaveProtocol: class {
    func didPressNote(note: CCNoteModel, or: CCNoteModel?)
}

@IBDesignable
public class CCOctavePianoKeyboard: UIView {
    
    public weak var delegate: CCPianoOctaveProtocol?
    private weak var view: UIView!
    
    @IBOutlet weak var noteC: CCVirtualPianoKeyView!
    @IBOutlet weak var noteD: CCVirtualPianoKeyView!
    @IBOutlet weak var noteE: CCVirtualPianoKeyView!
    @IBOutlet weak var noteF: CCVirtualPianoKeyView!
    @IBOutlet weak var noteG: CCVirtualPianoKeyView!
    @IBOutlet weak var noteA: CCVirtualPianoKeyView!
    @IBOutlet weak var noteB: CCVirtualPianoKeyView!
    
    var notes: [CCVirtualPianoKeyView] = []
    
    @IBInspectable public var hideLabels: Bool = true {
        didSet {
            for note in notes {
                note.showLabels = !hideLabels
            }
        }
    }
    
    @IBInspectable public var octaveValue: Int = 0 {
        didSet {
            for note in notes {
                note.octaveValue = octaveValue
            }
        }
    }
    
    @IBInspectable public var isBass: Bool = false {
        didSet {
            for note in notes {
                note.isBassKey = isBass
            }
        }
    }
    
    @IBInspectable public var isTreble: Bool = false {
        didSet {
            for note in notes {
                note.isTrebleKey = isTreble
            }
        }
    }
    
    @IBInspectable public var isMiddleType: Bool = false {
        didSet {
            var isBass = true
            for note in notes {
                if note.keyString == "G" { isBass = false }
                if isBass { note.isBassKey   = true }
                     else { note.isTrebleKey = true }
                
            }
        }
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
        notes = [noteC, noteD, noteE, noteF, noteG, noteA, noteB]
        configure()
    }
    
    private func configure() {
        for note in notes {
            note.delegate = self
        }
    }
    
    private func loadFromNib(withOwner: UIView) -> UIView {
        
        let bundle = Bundle(for: CCOctavePianoKeyboard.self)
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
}

extension CCOctavePianoKeyboard : CCPianoKeyProtocol {
    func didPressNote(note: CCNoteModel, or: CCNoteModel?) {
        delegate?.didPressNote(note: note, or: or)
    }
}
