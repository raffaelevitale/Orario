//
//  Lesson.swift
//  OrarioScuolaApp
//

import Foundation

struct Lesson: Identifiable, Codable {
    let id: UUID
    let subject: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int // 1 = Lunedì, 2 = Martedì, etc.
    let startTime: String // "07:50"
    let endTime: String // "08:50"
    let color: String // Hex color per la materia
    
    init(subject: String, teacher: String, classroom: String, dayOfWeek: Int, startTime: String, endTime: String, color: String) {
        self.id = UUID()
        self.subject = subject
        self.teacher = teacher
        self.classroom = classroom
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.color = color
    }

    var dayName: String {
        switch dayOfWeek {
        case 1: return "Lunedì"
        case 2: return "Martedì"
        case 3: return "Mercoledì"
        case 4: return "Giovedì"
        case 5: return "Venerdì"
        case 6: return "Sabato"
        case 7: return "Domenica"
        default: return "Sconosciuto"
        }
    }

    var duration: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else {
            return 0
        }

        return Int(end.timeIntervalSince(start) / 60) // in minuti
    }

    static let sampleData: [Lesson] = [
        //LUNEDI
        Lesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "LAB.134 TELECOMUNICAZIONI (50)", dayOfWeek: 1, startTime: "07:50", endTime: "08:50", color: "#42a5f5"),
        Lesson(subject: "Sistemi e reti", teacher: "CANONICO T.", classroom: "LAB.134 TELECOMUNICAZIONI (50)", dayOfWeek: 1, startTime: "08:50", endTime: "09:45", color: "#66bb6a"),
        Lesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119A PASCAL (27)", dayOfWeek: 1, startTime: "09:45", endTime: "10:40", color: "#7e57c2"),
        Lesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119A PASCAL (27)", dayOfWeek: 1, startTime: "11:00", endTime: "11:55", color: "#7e57c2"),
        Lesson(subject: "T.P.S.I.T.", teacher: "FEA D., RACCA M.", classroom: "LAB.119B EULERO (25)", dayOfWeek: 1, startTime: "11:55", endTime: "12:50", color: "#ffa726"),
        Lesson(subject: "T.P.S.I.T.", teacher: "FEA D., RACCA M.", classroom: "LAB.119B EULERO (25)", dayOfWeek: 1, startTime: "12:50", endTime: "13:40", color: "#ffa726"),

        //MARTEDI
        Lesson(subject: "Religione", teacher: "CAVALLERO L.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "07:50", endTime: "08:45", color: "#fbc02d"),
        Lesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "08:45", endTime: "09:35", color: "#42a5f5"),
        Lesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T31 (24)", dayOfWeek: 2, startTime: "09:35", endTime: "10:25", color: "#ef5350"),
        Lesson(subject: "T.P.S.I.T.", teacher: "FEA D., RACCA M.", classroom: "LAB.143 TURING (22)", dayOfWeek: 2, startTime: "10:30", endTime: "11:20", color: "#ffa726"),
        Lesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "301 (28)", dayOfWeek: 2, startTime: "11:20", endTime: "12:10", color: "#8d6e63"),
        Lesson(subject: "Ginnastica", teacher: "BALLATORE A.", classroom: "PALESTRA", dayOfWeek: 2, startTime: "12:20", endTime: "13:10", color: "#ff7043"),
        Lesson(subject: "Ginnastica", teacher: "BALLATORE A.", classroom: "PALESTRA", dayOfWeek: 2, startTime: "13:10", endTime: "14:00", color: "#ff7043"),

        //MERCOLEDI
        Lesson(subject: "Informatica", teacher: "BONAVIA M., MAGGIORE G.", classroom: "LAB.S22 ARCHIMEDE (26)", dayOfWeek: 3, startTime: "07:50", endTime: "08:50", color: "#7e57c2"),
        Lesson(subject: "Informatica", teacher: "BONAVIA M., MAGGIORE G.", classroom: "LAB.S22 ARCHIMEDE (26)", dayOfWeek: 3, startTime: "08:50", endTime: "09:45", color: "#7e57c2"),
        Lesson(subject: "Storia", teacher: "CARANTA P.", classroom: "148 (28)", dayOfWeek: 3, startTime: "09:45", endTime: "10:40", color: "#6d4c41"),
        Lesson(subject: "Storia", teacher: "CARANTA P.", classroom: "148 (28)", dayOfWeek: 3, startTime: "11:00", endTime: "11:55", color: "#6d4c41"),
        Lesson(subject: "Sistemi e reti", teacher: "CANONICO T.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 3, startTime: "11:55", endTime: "12:50", color: "#66bb6a"),
        Lesson(subject: "T.P.S.I.T.", teacher: "FEA D.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 3, startTime: "12:50", endTime: "13:40", color: "#ffa726"),

        //GIOVEDI
        Lesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "212 TEST (24)", dayOfWeek: 4, startTime: "07:50", endTime: "08:45", color: "#8d6e63"),
        Lesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "212 TEST (24)", dayOfWeek: 4, startTime: "08:45", endTime: "09:35", color: "#8d6e63"),
        Lesson(subject: "Matematica", teacher: "GARRO V.", classroom: "212 TEST (24)", dayOfWeek: 4, startTime: "09:35", endTime: "10:25", color: "#ef5350"),
        Lesson(subject: "T.P.S.I.T.", teacher: "FEA D.", classroom: "LAB.116 LAPLACE (25)", dayOfWeek: 4, startTime: "10:30", endTime: "11:20", color: "#ffa726"),
        Lesson(subject: "Sistemi e reti", teacher: "CANONICO T., MAGGIORE G., CISCO", classroom: "LAB.S18 MARCONI (24)", dayOfWeek: 4, startTime: "11:20", endTime: "12:10", color: "#66bb6a"),
        Lesson(subject: "Sistemi e reti", teacher: "CANONICO T., MAGGIORE G., CISCO", classroom: "LAB.S18 MARCONI (24)", dayOfWeek: 4, startTime: "12:20", endTime: "13:10", color: "#66bb6a"),
        Lesson(subject: "Inglese", teacher: "FOGLIA P.", classroom: "T65 TEST (27)", dayOfWeek: 4, startTime: "13:10", endTime: "14:00", color: "#42a5f5"),

        //VENERDI
        Lesson(subject: "Informatica", teacher: "BONAVIA M.", classroom: "LAB.119B EULERO (25)", dayOfWeek: 5, startTime: "07:50", endTime: "08:50", color: "#7e57c2"),
        Lesson(subject: "Italiano", teacher: "CARANTA P.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "08:50", endTime: "09:45", color: "#8d6e63"),
        Lesson(subject: "Matematica", teacher: "GARRO V.", classroom: "T64 (28)", dayOfWeek: 5, startTime: "09:45", endTime: "10:40", color: "#ef5350"),
        Lesson(subject: "Gestione progetto", teacher: "FEA D., MAGGIORE G.", classroom: "LAB.T59 PLC (24)", dayOfWeek: 5, startTime: "11:00", endTime: "11:55", color: "#26a69a"),
        Lesson(subject: "Gestione progetto", teacher: "FEA D., MAGGIORE G.", classroom: "LAB.T59 PLC (24)", dayOfWeek: 5, startTime: "11:55", endTime: "12:50", color: "#26a69a"),
        Lesson(subject: "Gestione progetto", teacher: "FEA D., MAGGIORE G.", classroom: "LAB.T59 PLC (24)", dayOfWeek: 5, startTime: "12:50", endTime: "13:40", color: "#26a69a"),
    ];
    
    static let breaks: [Lesson] = [
        // Intervallo Lunedì, Mercoledì, Venerdì (dopo 3a ora)
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 1, startTime: "10:40", endTime: "11:00", color: "#bdbdbd"),
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 3, startTime: "10:40", endTime: "11:00", color: "#bdbdbd"),
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 5, startTime: "10:40", endTime: "11:00", color: "#bdbdbd"),

        // Intervallo Martedì, Giovedì (dopo 3a ora)
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 2, startTime: "10:25", endTime: "10:30", color: "#bdbdbd"),
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 4, startTime: "10:25", endTime: "10:30", color: "#bdbdbd"),

        // Intervallo Martedì, Giovedì (dopo 5a ora)
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 2, startTime: "12:10", endTime: "12:20", color: "#bdbdbd"),
        Lesson(subject: "Intervallo", teacher: "", classroom: "Corridoio / Bar", dayOfWeek: 4, startTime: "12:10", endTime: "12:20", color: "#bdbdbd")
    ];
    
    
}
