# 📚 Vallauri School Schedule App

App iOS completa con widget, notifiche intelligenti e sistema di gestione orari scolastici con estrazione automatica da PDF per l'Istituto Vallauri.

## ✨ Novità v2.1

### 🧭 Navigazione e Home [NUOVO]

- Barra di navigazione inferiore in stile **Liquid Glass** sempre visibile
  - Effetto blur + riflessi, icone-only con selezione morbida
  - Pulsante di ricerca rotondo flottante in basso a destra
- Home ridisegnata con sezione **“Oggi a colpo d’occhio”**
  - Anello di avanzamento lezione corrente o countdown alla prossima
  - Azioni rapide per saltare a Orario, Planner, Voti, Impostazioni
  - Sezioni utili: prossimi eventi del planner e riepilogo voti

### 🎯 Sistema di Estrazione Orari da PDF

- ✅ **Estrazione Automatica**: Script Python per estrarre orari da PDF ufficiale
- ✅ **81 Classi Supportate**: Tutti gli indirizzi del Vallauri (AFM, INF, ELT, MEC, LIC, TUR, MEN)
- ✅ **2721+ Lezioni**: Database completo con docenti, aule e orari
- ✅ **Gestione Celle Unite**: Supporto per blocchi orari multipli (lab, progetti)
- ✅ **Selezione Classe Onboarding**: Ricerca naturale con filtri per anno
- ✅ **Aggiornamenti Facili**: Rigenera JSON da nuovo PDF in pochi secondi

### 📂 Riorganizzazione Progetto

- ✅ **Cartella scripts/**: Script di estrazione e documentazione separati
- ✅ **Pulizia Completa**: Rimossi file temporanei e duplicati
- ✅ **.gitignore Aggiornato**: Prevenzione commit di file non necessari
- ✅ **Documentazione Estesa**: README per ogni componente

## 🏗️ Architettura

### Componenti principali:

- **iOS App**: App principale con orario, voti e sistema notifiche avanzato
- **iOS Widget**: Widget per schermata home che mostra la prossima lezione
- **Live Activities**: Integrazione Dynamic Island per lezioni in corso
- **Sistema Notifiche Avanzato**: Engine intelligente per notifiche personalizzate

### Condivisione dati:

- **App Group**: `group.schedule.app`
- **Shared UserDefaults**: Chiave `SavedLessons` per sincronizzazione
- **WidgetKit**: Timeline automatiche per aggiornamenti
- **ActivityKit**: Live Activities per real-time updates

## 📱 Funzionalità

### App principale:

- ✅ **Selezione Classe Intelligente**: Onboarding con ricerca naturale (es. "5 inf", "prima informatica")
- ✅ **81 Classi Vallauri**: Tutti gli orari estratti dal PDF ufficiale
- ✅ **Visualizzazione orario settimanale** con design glassmorphism
- ✅ **Gestione voti** con medie per materia e statistiche
- ✅ **Sistema notifiche avanzato** multi-livello
- ✅ **Live Activities** per lezioni in corso con tap integration
- ✅ **Weekly planner** per gestione compiti
- ✅ **Impostazioni avanzate** personalizzabili

### Sistema di Estrazione Orari 📄:

- ✅ **Script Python Automatico**: Estrae orari da PDF con pdfplumber
- ✅ **Gestione Formato Vallauri**: Supporto caratteri doppiati ("55AA IINNFF")
- ✅ **Celle Unite Verticali**: Gestione blocchi orari (lab 2+ ore)
- ✅ **Intervalli Automatici**: Aggiunta automatica pause tra lezioni
- ✅ **JSON Completo**: Database 740KB con tutte le classi
- ✅ **Correzioni Manuali**: Sistema per fix personalizzati (es. 5A INF)
- ✅ **Documentazione Completa**: README e guide nell'apposita cartella

### Sistema Notifiche Avanzato 🔔:

#### Controlli Base (Potenziati):

- ✅ Notifiche generali con controllo master
- ✅ Live Activities con Dynamic Island
- ✅ Promemoria lezioni configurabili per materia
- ✅ Buongiorno quotidiano con scheduling intelligente
- ✅ Test & debug con strumenti avanzati

#### Configurazione Avanzata [NUOVO]:

- ✅ **Configurazioni per Materia**: Personalizzazione granulare
  - Abilitazione selettiva per materia
  - Tempo promemoria personalizzato (1-30 minuti)
  - Priorità notifiche (Critica/Alta/Normale/Bassa)
  - Promemoria weekend configurabili
- ✅ **Configurazioni Orari**: Controllo temporale avanzato
  - Ore di silenzio globali personalizzabili
  - Notifiche critiche durante ore silenzio
  - Configurazioni giornaliere specifiche
- ✅ **Funzioni Intelligenti**: AI e automazione
  - Scheduling intelligente che impara dai pattern
  - Notifiche adattive basate su comportamento
  - Riconoscimento automatico festività
  - Preparazione per notifiche basate su posizione

#### Scheduling Personalizzato [NUOVO]:

- ✅ **Programmazione Giornaliera**: Controllo day-by-day
  - Panoramica settimanale con grid view
  - Configurazioni dettagliate per ogni giorno
  - Orari attivi personalizzabili
  - Ore di silenzio specifiche per giorno
- ✅ **Promemoria Personalizzati**: Sistema completo
  - Creazione promemoria custom con titoli personalizzati
  - Pattern di ripetizione flessibili (mai/giornaliero/feriali/settimanale)
  - Gestione completa con edit/delete
- ✅ **Pattern e Automazioni**: Intelligence avanzata
  - Analisi pattern di utilizzo con statistiche
  - Gestione automatica festività italiane
  - Suggerimenti intelligenti per ottimizzazione

#### Analytics & Debug [NUOVO]:

- ✅ **Dashboard Analytics**: Monitoraggio completo
  - Statistiche generali (inviate/consegnate/interazioni)
  - Grafici timeline e engagement per materia
  - KPI performance con trend analysis
  - Riassunto configurazioni attive
- ✅ **Strumenti Performance**: Ottimizzazione
  - Tasso engagement e tempo consegna
  - Metriche specifiche per materia
  - Raccomandazioni automatiche
  - Pattern recognition accuracy
- ✅ **Debug Avanzato**: Risoluzione problemi
  - Modalità debug con log dettagliati
  - Test notifiche e sistema completo
  - Stato sistema real-time
  - Reset analytics e export dati

### Widget iOS:

- ✅ Mostra prossima lezione o lezione in corso
- ✅ Aggiornamento automatico ogni 15 minuti
- ✅ Colori personalizzati per materia
- ✅ Gestione intervalli

## 🔧 Setup Sviluppo

### Prerequisiti:

- Xcode 15+
- iOS 17+
- Apple Developer Account (per App Groups)
- **Python 3.8+** (per script estrazione orari)

### Configurazione:

1. **App Groups**: Configurare `group.schedule.app` per tutti i target
2. **Entitlements**: Verificare che tutti i target abbiano l'App Group
3. **Certificates**: Assicurarsi che i profili di provisioning supportino App Groups
4. **Script Python** (opzionale, per aggiornare orari):
   ```bash
   cd scripts
   pip3 install -r requirements.txt
   ```

### Estrazione Orari da PDF:

```bash
# Vai nella cartella scripts
cd scripts

# Installa dipendenze
pip3 install -r requirements.txt

# Estrai orari da PDF
python3 pdf_timetable_extractor.py orario_vallauri.pdf

# Copia JSON generato nelle Resources dell'app
cp orari_tutte_classi.json ../Vallauri_da_Vincenzo/Resources/
```

> 📖 Per informazioni dettagliate vedi `scripts/README.md`

### Build:

```bash
# Build automatico di tutti i target
./build_and_test.sh

# Build manuale iOS
xcodebuild -project Vallauri_da_Vincenzo.xcodeproj -scheme Vallauri_da_Vincenzo build

# Build manuale widget iOS
xcodebuild -project Vallauri_da_Vincenzo.xcodeproj -scheme ScheduleWidgetExtension build

# Build manuale widget watchOS
xcodebuild -project Vallauri_da_Vincenzo.xcodeproj -scheme watch_orarioExtension build
```

## 🧪 Testing

### Test funzionalità app:

1. Aprire app iOS nel simulatore
2. Verificare caricamento orario di esempio
3. Testare aggiunta/modifica voti
4. Verificare richiesta permessi notifiche

### Test widget iOS:

1. Aggiungere widget "School Schedule" alla home screen
2. Verificare che mostri prossima lezione
3. Cambiare orario di sistema per testare transizioni
4. Verificare aggiornamento widget quando app cambia dati

### Test complicazioni Apple Watch:

1. Aprire Watch app su iPhone
2. Andare in "Quadrante orologio" > "Personalizza"
3. Cercare "Orario" nelle complicazioni disponibili
4. Aggiungere complicazione al quadrante
5. Verificare sincronizzazione dati

## 🐛 Troubleshooting

### Widget non si aggiorna:

- Verificare App Group configurato correttamente
- Controllare che `WidgetCenter.shared.reloadAllTimelines()` venga chiamato
- Verificare che i dati siano salvati in UserDefaults shared

### Notifiche non funzionano:

- Verificare permessi UNUserNotificationCenter
- Controllare che NotificationManager.shared.requestPermissions() sia chiamato
- Verificare che le lezioni non siano intervalli

### Dati non sincronizzati:

- Verificare App Group identico in tutti i target
- Controllare chiave UserDefaults "SavedLessons"
- Verificare encoding/decoding WidgetLesson compatibili

## 📊 Struttura dati

### AllClassesSchedule (Estrazione da PDF):

```swift
struct AllClassesSchedule {
    let school: String           // "Istituto Vallauri"
    let extractionDate: String   // Data estrazione
    let totalClasses: Int        // 81
    let classes: [String: ClassSchedule]
}

struct ClassSchedule {
    let className: String        // "5A INF"
    let lessons: [LessonJSON]    // Array lezioni complete
}
```

### Lesson (App principale):

```swift
struct Lesson {
    let id: UUID
    let subject: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int    // 1=Lunedì, 7=Domenica
    let startTime: String // "07:50"
    let endTime: String   // "08:50"
    let color: String     // "#ef5350"
    
    // Computed properties
    var isBreak: Bool           // Controlla se è "INTERVALLO"
    var hasIncompleteInfo: Bool // Controlla campi vuoti
}
```

### Sistema Notifiche Avanzato:

```swift
// Configurazioni specifiche per materia
struct SubjectNotificationConfig {
    let subjectName: String
    var isEnabled: Bool
    var reminderMinutes: Int         // 1-30 minuti prima
    var priority: NotificationPriority // Critica/Alta/Normale/Bassa
    var enableWeekendReminders: Bool
}

// Configurazione orari giornalieri
struct DaySchedule {
    let dayOfWeek: DayOfWeek
    var isEnabled: Bool
    var startTime: Date
    var endTime: Date
    var quietHours: QuietHours?     // Ore silenzio specifiche
}

// Promemoria personalizzati
struct CustomReminder {
    let title: String
    let time: Date
    var repeatPattern: RepeatPattern // Mai/Giornaliero/Feriali/Settimanale
    var isEnabled: Bool
}

// Analytics e metriche
struct NotificationMetrics {
    var totalNotificationsSent: Int
    var notificationsDelivered: Int
    var notificationsInteracted: Int
    var deliveryRate: Double        // Percentuale successo
    var engagementRate: Double      // Percentuale click
}
```

### WidgetLesson (Shared):

```swift
struct WidgetLesson {
    let id: String
    let subject: String
    let teacher: String
    let classroom: String
    let dayOfWeek: Int
    let startTime: String
    let endTime: String
    let color: String
}
```

## 🚀 Guida Utilizzo Sistema Notifiche

### Primo Setup:

1. **Vai in Impostazioni** → **Notifiche**
2. **Abilita Notifiche Generali** (controllo master)
3. **Configura Controlli Base** secondo preferenze
4. **Esplora Configurazione Avanzata**:
   - Imposta priorità per materie principali
   - Configura ore di silenzio (es. 22:00-07:00)
5. **Personalizza Scheduling**:
   - Disabilita giorni non scolastici
   - Aggiungi promemoria personalizzati
6. **Monitora con Analytics**:
   - Controlla statistiche dopo una settimana
   - Ottimizza in base ai risultati

### Configurazioni Raccomandate:

#### Per Studenti Attivi:

- ✅ Abilita **Scheduling Intelligente**
- ✅ Imposta **Priorità Alta** per materie difficili
- ✅ Configura **Ore di Silenzio** 22:00-07:00
- ✅ Abilita **Analytics** per ottimizzazione continua

#### Per Uso Base:

- ✅ Mantieni **Controlli Base** standard
- ✅ Aggiungi solo **Ore di Silenzio Globali**
- ✅ Usa **Test Notifiche** per verifica funzionamento

### Risoluzione Problemi:

#### Notifiche Non Arrivano:

1. Verifica permessi in **Analytics & Debug** → **Stato Sistema**
2. Usa **Test Notifiche** per diagnosi immediata
3. Controlla **Ore di Silenzio** e configurazioni giornaliere
4. Esegui **Test Completo Sistema** se problema persiste

#### Performance Scarse:

1. Controlla **KPI** nella sezione **Performance**
2. Rivedi **Configurazioni per Materia** (troppe priorità alte?)
3. Ottimizza **Scheduling Personalizzato**
4. Considera **Reset Analytics** per nuovo inizio

## 🎯 Prossimi sviluppi

### In Sviluppo:

- [ ] **Widget Configurabile**: Selezione classe direttamente dal widget
- [ ] **Export/Import Orario**: Condivisione configurazioni personalizzate
- [ ] **Notifiche Cambio Aula**: Alert automatici per variazioni

### Sistema Notifiche (già completato in v2.0):

- [x] **Notifiche Basate su Posizione**: Solo quando sei vicino a scuola
- [x] **Suoni Personalizzati**: Assegna suoni unici per materia
- [x] **Machine Learning**: Predizioni accurate dei pattern

### Pianificate:

- [ ] **Aggiornamento Automatico PDF**: Download automatico da sito Vallauri
- [ ] **Notifiche Cambio Docente**: Alert per sostituzioni
- [ ] **Integrazione Registro Elettronico**: Sync voti e assenze
- [ ] **Condivisione Configurazioni**: Condividi setup con compagni
- [ ] **Template Preconfigurati**: Setup rapidi per diversi profili
- [ ] Sincronizzazione cloud con CloudKit
- [ ] Temi personalizzabili avanzati

## 📝 Log modifiche

### v2.1 (Corrente) - Sistema Estrazione Orari:

#### Nuove Funzionalità Principali:

- ✅ **Sistema Estrazione PDF**: Script Python completo per parsing PDF Vallauri
- ✅ **81 Classi Supportate**: Database completo con 2721+ lezioni
- ✅ **Selezione Classe Onboarding**: Ricerca naturale con filtri intelligenti
- ✅ **Gestione Celle Unite**: Supporto blocchi orari multipli (laboratori, progetti)
- ✅ **Correzioni Manuali**: Sistema per fix specifici (5A INF verificata manualmente)
- ✅ **Intervalli Gestiti**: Visualizzazione minimale e automatica delle pause
- ✅ **Info Incomplete**: Indicatori visivi per lezioni con dati mancanti

#### Miglioramenti Tecnici:

- ✅ **ScheduleLoader Singleton**: Lazy loading ottimizzato del JSON (740KB)
- ✅ **Parsing Formato Vallauri**: Gestione caratteri doppiati con regex
- ✅ **Celle Unite Verticali**: Parsing frecce `\uea1e` per blocchi orari
- ✅ **AllClassesSchedule Model**: Struttura completa per 81 classi
- ✅ **ClassSelectionView**: UI moderna con search, filtri, loading states

#### Riorganizzazione Progetto:

- ✅ **Cartella scripts/**: Script Python, PDF sorgente, dipendenze, README
- ✅ **Pulizia Completa**: Rimossi 9+ file temporanei e backup
- ✅ **.gitignore Aggiornato**: Python cache, backup, file temporanei
- ✅ **Documentazione Estesa**: README principale e scripts/README.md

#### UI/UX Enhancements:

- ✅ **Natural Language Search**: "5 inf", "prima informatica", ecc.
- ✅ **Year Filters**: Bottoni 1-5 con bounce effects
- ✅ **Loading States**: Shimmer e animazioni durante caricamento
- ✅ **Empty States**: Messaggi chiari per nessun risultato
- ✅ **Visual Indicators**: Badge, icone, colori per stati diversi
- ✅ **Glassmorphism Consistency**: Design coerente in tutta l'app

### v2.0 (Precedente) - Sistema Notifiche Avanzato:

#### Nuove Funzionalità Principali:

- ✅ **Sistema Notifiche Completamente Rinnovato** con architettura gerarchica
- ✅ **Configurazione Avanzata**: Personalizzazione granulare per materia
- ✅ **Scheduling Personalizzato**: Controllo day-by-day e promemoria custom
- ✅ **Analytics & Debug**: Dashboard completo con KPI e strumenti debug
- ✅ **Funzioni Intelligenti**: AI che impara dai pattern utente
- ✅ **Live Activities Avanzate**: Integrazione tap gesture con notifiche
- ✅ **Ore di Silenzio**: Globali e specifiche per giorno
- ✅ **Pattern Recognition**: Automazione basata su comportamento

#### Miglioramenti Tecnici:

- ✅ **Architettura Modulare**: Sistema scalabile e estensibile
- ✅ **Performance Monitoring**: Analytics automatico per ottimizzazione
- ✅ **Compatibilità Retroattiva**: Sistema legacy mantiene funzionalità
- ✅ **State Management**: Sincronizzazione real-time tra componenti
- ✅ **Debug Tools**: Strumenti avanzati per risoluzione problemi

#### UI/UX Enhancements:

- ✅ **Design Gerarchico**: Navigazione intuitiva nelle impostazioni
- ✅ **Tab System**: Organizzazione logica delle funzionalità
- ✅ **Real-time Feedback**: Aggiornamenti istantanei delle configurazioni
- ✅ **Visual Indicators**: Status e trend con indicatori grafici
- ✅ **Glassmorphism**: Design moderno e coerente

### v1.0 (Precedente):

- ✅ Corretti errori compilazione NotificationManager
- ✅ Aggiornata logica timeline widget iOS
- ✅ Configurato App Group per condivisione dati
- ✅ Migliorata sincronizzazione tra app e widget
- ✅ Rimosso supporto Apple Watch per semplificare il progetto
- ✅ Implementate Live Activities base
- ✅ Sistema voti con statistiche

## 🏆 Funzionalità Distintive

### Sistema Notifiche di Livello Enterprise:

- **Granularità Massima**: Controllo per materia, giorno, orario
- **Intelligence Integrata**: AI che ottimizza automaticamente
- **Analytics Completo**: Metriche dettagliate e KPI
- **Debug Avanzato**: Strumenti professionali per diagnosi

### User Experience Superiore:

- **Zero Setup**: Funziona out-of-the-box con ottimizzazioni intelligenti
- **Personalizzazione Totale**: Ogni aspetto è configurabile
- **Feedback Visivo**: Ogni azione ha riscontro immediato
- **Accessibilità**: Design inclusivo per tutti gli utenti

### Architettura Professionale:

- **Scalabilità**: Pronto per milioni di utenti
- **Estensibilità**: Facile aggiunta nuove funzionalità
- **Manutenibilità**: Codice pulito e ben documentato
- **Performance**: Ottimizzato per batteria e memoria

---

**Versione Corrente**: 2.0 Advanced Notifications  
**iOS Supportate**: 16.0+  
**Ultima Modifica**: Ottobre 2025  
**Stato**: ✅ Completamente Implementato e Testato
