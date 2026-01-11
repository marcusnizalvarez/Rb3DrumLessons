# This script loads a MIDI file, renames the drum track to "PART DRUMS",
# remaps standard drum notes to Clone Hero–compatible note numbers,
# and prints a clear usage message when arguments are missing.

import sys
import mido


# Mapping from General MIDI drum notes to target MIDI notes
DrumNoteMap={
    35:96,   # Bass Drum -> C7
    36:96,   # Bass Drum -> C7
    38:97,   # Snare -> C#7
    40:97,   # Snare -> C#7
    42:98,   # Hi-Hat Closed -> D7
    46:98,   # Hi-Hat Open -> D7
    41:112,  # Low Tom -> E8
    43:112,  # Low Tom -> E8
    45:111,  # Mid Tom -> D#8
    47:111,  # Mid Tom -> D#8
    48:110,  # High Tom -> D8
    50:110,  # High Tom -> D8
    49:99,   # Crash Cymbal -> D#7
    57:99,   # Crash Cymbal -> D#7
    51:100,  # Ride Cymbal -> E7
    52:100,  # Ride Cymbal -> E7
    53:100   # Ride Bell -> E7
}

# Target notes that are toms (need octave pair)
TomNotes={110,111,112}


def PrintUsage():
    # CLI usage
    print("Usage: python this.py <input.mid> <output.mid>")
    sys.exit(1)


def RemapDrumNotes(InputPath,OutputPath):
    # Load MIDI and rebuild tracks
    MidiFileObj=mido.MidiFile(InputPath)
    NewTracks=[]

    for Track in MidiFileObj.tracks:
        NewTrack=mido.MidiTrack()
        IsDrumTrack=False

        for Msg in Track:
            if Msg.type in ["note_on","note_off"] and Msg.channel==9:
                IsDrumTrack=True

                if Msg.note in DrumNoteMap:
                    BaseNote=DrumNoteMap[Msg.note]

                    # Emit main note
                    NewTrack.append(Msg.copy(note=BaseNote))

                    # If tom, emit paired octave-lower note at same time
                    if BaseNote in TomNotes:
                        NewTrack.append(Msg.copy(note=BaseNote-12,time=0))
                    continue

            # Non-drum or untouched message
            NewTrack.append(Msg)

        if IsDrumTrack:
            NewTrack.insert(0,mido.MetaMessage("track_name",name="PART DRUMS",time=0))

        NewTracks.append(NewTrack)

    MidiFileObj.tracks=NewTracks
    MidiFileObj.save(OutputPath)


if __name__=="__main__":
    if len(sys.argv)!=3:
        PrintUsage()

    RemapDrumNotes(sys.argv[1],sys.argv[2])
