//
//  AllClassesSchedule.swift
//  Vallauri_da_Vincenzo
//

import Foundation

// Struttura per il JSON completo di tutte le classi
struct AllClassesSchedule: Codable {
    let school: String
    let extractionDate: String
    let totalClasses: Int
    let classes: [String: ClassSchedule]
}

// Struttura per ogni singola classe
struct ClassSchedule: Codable {
    let className: String
    let scheduleType: String
    let totalLessons: Int
    let lessons: [LessonJSON]
}

// Struttura per le lezioni nel JSON (diversa da Lesson per compatibilità)
struct LessonJSON: Codable {
    let className: String?  // Opzionale perché gli intervalli non hanno questo campo
    let subject: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int
    let startTime: String
    let endTime: String
    let color: String
    
    enum CodingKeys: String, CodingKey {
        case className = "class"
        case subject
        case teacher
        case classroom
        case dayOfWeek
        case startTime
        case endTime
        case color
    }
}

// Extension per convertire LessonJSON in Lesson
extension LessonJSON {
    func toLesson() -> Lesson {
        return Lesson(
            subject: subject,
            teacher: teacher,
            classroom: classroom,
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            endTime: endTime,
            color: color
        )
    }
}

// Manager per caricare e gestire gli orari
class ScheduleLoader {
    static let shared = ScheduleLoader()
    
    private var allSchedules: AllClassesSchedule?
    private var availableClasses: [String] = []
    private var isLoaded = false
    
    private init() {
        // Non caricare qui per evitare problemi con il Bundle
    }
    
    // Carica gli orari se non ancora caricati
    private func ensureLoaded() {
        guard !isLoaded else { return }
        isLoaded = true
        loadSchedules()
    }
    
    // Carica tutti gli orari dal JSON
    private func loadSchedules() {
        print("🔍 Cerco il file orari_tutte_classi.json nel bundle...")
        
        // Verifica tutti i file nel bundle
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Resource path: \(resourcePath)")
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let jsonFiles = files.filter { $0.hasSuffix(".json") }
                print("📄 File JSON trovati nel bundle: \(jsonFiles)")
            } catch {
                print("❌ Errore lettura resource path: \(error)")
            }
        }
        
        guard let url = Bundle.main.url(forResource: "orari_tutte_classi", withExtension: "json") else {
            print("❌ File orari_tutte_classi.json non trovato nel bundle")
            print("⚠️ Assicurati di aver aggiunto il file al target nel Build Phases")
            return
        }
        
        print("✅ File trovato: \(url.path)")
        
        do {
            let data = try Data(contentsOf: url)
            print("📦 Dimensione file: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            
            // Carica con autorelease pool per gestire meglio la memoria
            try autoreleasepool {
                allSchedules = try decoder.decode(AllClassesSchedule.self, from: data)
            }
            
            // Estrai lista classi disponibili
            if let classes = allSchedules?.classes {
                availableClasses = Array(classes.keys).sorted()
            } else {
                availableClasses = []
            }
            
            print("✅ Caricati orari per \(availableClasses.count) classi")
            if availableClasses.count > 0 {
                print("📋 Prime 5 classi: \(availableClasses.prefix(5).joined(separator: ", "))")
            }
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Chiave mancante: \(key)")
            print("   Percorso: \(context.codingPath)")
            print("   Descrizione: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Tipo non corrispondente: \(type)")
            print("   Percorso: \(context.codingPath)")
            print("   Descrizione: \(context.debugDescription)")
        } catch {
            print("❌ Errore caricamento orari: \(error)")
        }
    }
    
    // Ottieni tutte le classi disponibili
    func getAvailableClasses() -> [String] {
        ensureLoaded()
        return availableClasses
    }
    
    // Ottieni le lezioni per una classe specifica
    func getLessonsForClass(_ className: String) -> [Lesson] {
        ensureLoaded()
        guard let classSchedule = allSchedules?.classes[className] else {
            print("❌ Classe \(className) non trovata")
            return Lesson.sampleData
        }
        
        return classSchedule.lessons.map { $0.toLesson() }
    }
    
    // Ottieni informazioni sulla classe
    func getClassInfo(_ className: String) -> ClassSchedule? {
        ensureLoaded()
        return allSchedules?.classes[className]
    }
    
    // Cerca classi per anno o specializzazione
    func searchClasses(query: String) -> [String] {
        ensureLoaded()
        let lowercased = query.lowercased()
        return availableClasses.filter { $0.lowercased().contains(lowercased) }
    }
    
    // Filtra classi per anno
    func getClassesByYear(_ year: Int) -> [String] {
        ensureLoaded()
        return availableClasses.filter { $0.hasPrefix("\(year)") }
    }
    
    // Filtra classi per specializzazione
    func getClassesBySpecialization(_ spec: String) -> [String] {
        ensureLoaded()
        return availableClasses.filter { $0.hasSuffix(spec) }
    }
    
    // MARK: - Future: Ricerca Docenti
    // Ottieni tutti i docenti unici (per futura implementazione)
    func getAllTeachers() -> [String] {
        ensureLoaded()
        guard let schedules = allSchedules else { return [] }
        
        var teachers = Set<String>()
        for classSchedule in schedules.classes.values {
            for lesson in classSchedule.lessons {
                if !lesson.teacher.isEmpty && lesson.teacher != "INTERVALLO" {
                    teachers.insert(lesson.teacher)
                }
            }
        }
        
        return Array(teachers).sorted()
    }
    
    // Cerca lezioni per docente (per futura implementazione)
    func searchByTeacher(_ teacherName: String) -> [(className: String, lessons: [LessonJSON])] {
        ensureLoaded()
        guard let schedules = allSchedules else { return [] }
        
        var results: [(String, [LessonJSON])] = []
        let query = teacherName.lowercased()
        
        for (className, classSchedule) in schedules.classes {
            let matchingLessons = classSchedule.lessons.filter {
                $0.teacher.lowercased().contains(query)
            }
            
            if !matchingLessons.isEmpty {
                results.append((className, matchingLessons))
            }
        }
        
        return results.sorted { $0.0 < $1.0 }
    }
}
