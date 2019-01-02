//
//  CCNoteView.swift
//  CCMusicScoreModule
//
//  Created by Calin Chitu on 28/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import CCPianoUtilsModule

@IBDesignable
public class CCNoteView: UIView {
  
    private weak var view: UIView!
    
    @IBOutlet weak var sharpView: UIImageView!
    @IBOutlet weak var flatView: UIImageView!
    @IBOutlet weak var noteUpView: UIImageView!
    @IBOutlet weak var noteDownView: UIImageView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var topDistanceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var upLine1: UIView!
    @IBOutlet weak var upLine2: UIView!
    @IBOutlet weak var downLine1: UIView!
    @IBOutlet weak var downlLine2: UIView!
    
    /*
     
     21  = A left edge
     108 = C right edge
     
     24 = c1, 36 = c2, 48 = c3, 60 = c4, 72 = c5, 84 = c6, 96 = c7, 108 =  C8
     
     */
    
    let trebleDic  = ["D", "C", "B", "A", "G", "F", "E", "D", "C", "B", "A", "G", "F", "E", "D", "C", "B", "A", "G"]
    let tOctaveDic = ["7", "7", "6", "6", "6", "6", "6", "6", "6", "5", "5", "5", "5", "5", "5", "5", "4", "4", "4"]
    
    let bassDic    = ["F", "E", "D", "C", "B", "A", "G", "F", "E", "D" ,"C", "B", "A", "G", "F", "E", "D", "C", "B"]
    let bOctaveDic = ["4", "4", "4", "4", "3", "3", "3", "3", "3", "3", "3", "2", "2", "2", "2", "2", "2", "2", "1"]
    
    let accDic = ["", "#", "b"]
    
    public var hideLabels: Bool = false
    public var hideAccidentals: Bool = false
    public var hideOctaves: Bool = false
    
    public var noteModel: CCNoteModel = CCNoteModel() {
        didSet {
            if noteModel.emptyNote {
                position = -1
                return
            }
            isTreble = !noteModel.bass
            status = noteModel.status
            if let index = octaveDic.index(of: "\(noteModel.octave)") {
                for pos in index..<notesDic.count {
                    if notesDic[pos] == noteModel.note {
                        position = pos
                        if let accIndex = accDic.index(of: noteModel.accidental) {
                            accidental = accIndex
                        }
                        break
                    }
                }
            }
        }
    }
    
    @IBInspectable public var isTreble: Bool = true {
        didSet {
            let pos = position
            position = pos
        }
    }
    
    var notesDic: [String] {
        get {return isTreble ?  trebleDic : bassDic}
    }
    var octaveDic: [String] {
        get {return isTreble ?  tOctaveDic : bOctaveDic}
    }
    
    var lockAnimation: Bool = false
    
    private func animate(color: UIColor) {
        guard !lockAnimation else {
            return
        }
        lockAnimation = true
        UIView.animate(withDuration: 0.5, animations: {
            self.backgroundColor = color.withAlphaComponent(0.1)
        }) { completed in
            UIView.animate(withDuration: 0.5, animations: {
                self.backgroundColor = .clear
            }) { completed in
                self.lockAnimation = false
            }
        }
    }
    
    @IBInspectable public var accidental: Int = 0 {
        didSet {
            guard position > -1, position < 19 else {
                return
            }
            sharpView.isHidden = accidental != 1
            flatView.isHidden  = accidental != 2
            let textSymb = notesDic[position]
            //let octaveSimb = octaveDic[position]
            //if textSymb + octaveSimb == "F4" { sharpView.isHidden = true }
            switch textSymb {
            case "E", "B":
                sharpView.isHidden = true
            case "C", "F":
                flatView.isHidden = true
            default:
                break
            }
        }
    }
    
    @IBInspectable public var status: Int = 0 {
        didSet {
            
            var tint = UIColor.black
            switch status {
            case 1:
                tint = UIColor(red: 0, green: 123 / 255.0, blue: 0, alpha: 1)
                //animate(color: tint)
            case 2:
                tint = UIColor(red: 153 / 255.0, green: 0, blue: 0, alpha: 1)
                animate(color: tint)
            case 3:
                let vAlpha: CGFloat = CGFloat(Double(noteModel.velocity) / 100.0)
                print(vAlpha)
                tint = UIColor.black.withAlphaComponent(vAlpha)
            default:
                break
            }
            
            noteUpView.tintColor = tint
            noteDownView.tintColor = tint
            sharpView.tintColor = hideAccidentals ? .clear : tint
            flatView.tintColor  = hideAccidentals ? .clear : tint
            symbolLabel.textColor = hideLabels ? .clear : tint
        }
    }
    
    public var octave: String { return octaveDic[position] }
    public var accString: String {
        switch accidental {
        case 1:
            return "#"
        case 2:
            return "b"
        default:
            return ""
        }
    }
    public var noteString: String { return notesDic[position] }
    
    @IBInspectable public var position: Int = 0 {
        didSet {
            //let appDelegate = UIApplication.shared.delegate as! AppDelegate
            //let showNotes = appDelegate.showNotes

            let offset: Float = Float(self.frame.size.height) / 20.0
            
            updateLines(position: position)
            symbolLabel.layer.cornerRadius = 5
            var pos: CGFloat = CGFloat(offset * Float(position))
            switch position {
            case 0...8:
                noteUpView.isHidden = true
                noteDownView.isHidden = false
                if hideOctaves {
                    symbolLabel.text = notesDic[position]
                } else {
                    symbolLabel.text = notesDic[position] + octaveDic[position]
                }
            case 9...18:
                noteUpView.isHidden = false
                noteDownView.isHidden = true
                if hideOctaves {
                    symbolLabel.text = notesDic[position]
                } else {
                    symbolLabel.text = notesDic[position] + octaveDic[position]
                }
            default:
                pos = CGFloat(-100)
                updateLines(position: 9)
            }
            topDistanceConstraint.constant = pos
            symbolLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    private func updateLines(position: Int) {
        upLine1.isHidden = position > 1
        upLine2.isHidden = position > 3
        downLine1.isHidden = position < 15
        downlLine2.isHidden = position < 17
        if frame.size.height < 110 {
            upLine1.frame.size.width = sharpView.frame.size.width * 1.3
            upLine1.center.x = frame.size.width / 2
            upLine2.frame.size.width = sharpView.frame.size.width * 1.3
            upLine2.center.x = frame.size.width / 2
            downLine1.frame.size.width = sharpView.frame.size.width * 1.3
            downLine1.center.x = frame.size.width / 2
            downlLine2.frame.size.width = sharpView.frame.size.width * 1.3
            downlLine2.center.x = frame.size.width / 2
        }
    }
    
    private func configure() {
        accidental = 0
        status = 0
        position = 0
        isTreble = true
        symbolLabel.adjustsFontSizeToFitWidth = true
        layer.cornerRadius = 5
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
    
    public func loadFromNib(withOwner: UIView) -> UIView {
        
        let bundle = Bundle(for: CCNoteView.self)
        let view = viewFromNib(withOwner: withOwner, bundle: bundle)
        
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }
    
    public func viewFromNib(withOwner: UIView, bundle: Bundle) -> UIView {
        
        let nib = UINib(nibName: "\(type(of: withOwner))", bundle: bundle)
        let view = nib.instantiate(withOwner: withOwner, options: nil).first as! UIView
        return view
    }
    
}
