//
//  CCPianoKeyCell.swift
//  PainoAppBase
//
//  Created by Calin Chitu on 29/05/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import UIKit
import CCVirtualPianoModule

class CCPianoKeyCell: UICollectionViewCell {
    
    static let cellID = "CCPianoKeyCellID"
    
    @IBOutlet weak var pianoKeyboardView: CCOctavePianoKeyboard!
}
