//
//  CCNotePlayer.swift
//  CCPianoUtilsModule
//
//  Created by Calin Chitu on 02/06/2017.
//  Copyright © 2017 Calin Chitu. All rights reserved.
//

import AudioToolbox

public class CCNotePlayer {
    
    public class func playNote(noteModel: CCNoteModel) {
        
        guard !noteModel.emptyNote else {
            return
        }
        
        let index = indexFromModel(noteModel: noteModel)
        print(index)
        
        var sequence:MusicSequence? = nil
        NewMusicSequence(&sequence)
        
        var track:MusicTrack? = nil
        MusicSequenceNewTrack(sequence!, &track)
        
        var time = MusicTimeStamp(1.0)
        var note = MIDINoteMessage(channel: 0,
                                   note: UInt8(index),
                                   velocity: UInt8(noteModel.velocity),
                                   releaseVelocity: 0,
                                   duration: 1.0 )
        MusicTrackNewMIDINoteEvent(track!, time, &note)
        time += 1
        
        var musicPlayer:MusicPlayer? = nil
        NewMusicPlayer(&musicPlayer)
        
        MusicPlayerSetSequence(musicPlayer!, sequence)
        MusicPlayerStart(musicPlayer!)
    }
    
    public class func indexFromModel(noteModel: CCNoteModel) -> Int {
        guard !noteModel.emptyNote else {
            return 0
        }
        if let noteVal = noteValue[noteModel.note + noteModel.accidental] {
            let baseVal = 12 * (noteModel.octave + 1)
            return baseVal + noteVal
        }
        return 0
    }
    
    /*
     
     21  = A left edge
     108 = C right edge
     
     24 = c1, 36 = c2, 48 = c3, 60 = c4, 72 = c5, 84 = c6, 96 = c7, 108 =  C8
     
     */
    static let noteValue = ["C" : 0, "C#" : 1, "Db" : 1, "D" : 2, "D#" : 3, "Eb" : 3, "E" : 4, "F" : 5, "F#" : 6, "Gb" : 6, "G" : 7, "G#" : 8, "Ab" : 8, "A" : 9, "A#" : 10, "Bb" : 10, "B" : 11]
    
}
