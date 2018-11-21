import Foundation
import CoreMIDI
import WebMIDIKit
import Darwin

struct Note: Hashable, Codable {
    var key: UInt8 = 0
    var velocity: UInt8 = 0

    var hashValue: Int {
        let hashString = String(key) + ";" + String(velocity)
        return hashString.hashValue
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.key == rhs.key && lhs.velocity == rhs.velocity
    }
}

/// represents the MIDI session
let midi: MIDIAccess = MIDIAccess()

/// prints all MIDI inputs available to the console and asks the user which port they want to select
let inputPort: MIDIInput? = midi.inputs.prompt()

let outputPort: MIDIOutput? = midi.outputs.prompt()

let Low = 8
let High = 100

let SLow = 1
let SHigh = 127

var dict: [Note: Int] = [:]

func readFile() {
     do {
        let file = "history.json" //this is the file. we will write to and read from it

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(file)

            let jsonData = try Data(contentsOf: fileURL)

            dict = try JSONDecoder().decode([Note: Int].self, from: jsonData)
            print("Note history loaded.")
        }
    } catch {
        print(error.localizedDescription)
    }
}

readFile()



func writeFile() {
    do {
        let jsonData = try JSONEncoder().encode(dict)
        let file = "history.json" //this is the file. we will write to and read from it

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(file)

            //writing
            try jsonData.write(to: fileURL)

        }
    } catch {
        print(error.localizedDescription)
    }

}

signal(SIGINT) {signal in
    writeFile()
    print("Note history saved.")
}
if outputPort != nil && inputPort != nil {
    /// Receiving MIDI events
    /// set the input port's onMIDIMessage callback which gets called when the port receives MIDI packets
    inputPort?.onMIDIMessage = { (packet: MIDIPacket) in
        let d0 = packet.data.0
        let d1 = packet.data.1
        let d2 = packet.data.2

        var d2v = d2

        if d0 == 144 && d2 > 0 {
            let note = Note(key: d1, velocity: d2)
            let count = dict[note, default: 0]
            dict[note] = count + 1

            var v = Int(d2)
            v = max(v, Low)
            v = min(v, High)
            v = SLow + (v - Low) * (SHigh - SLow) / (High - Low)
            d2v = UInt8(v)
        }
        outputPort?.send([d0, d1, d2v])
    }
    sigsuspend(nil)
}
