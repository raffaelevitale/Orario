# School Schedule App

App iOS con widget per iPhone che mostra l'orario scolastico, notifiche e voti.

## 🏗️ Architettura

### Componenti principali:

- **iOS App**: App principale con orario, voti e notifiche
- **iOS Widget**: Widget per schermata home che mostra la prossima lezione

### Condivisione dati:

- **App Group**: `group.schedule.app`
- **Shared UserDefaults**: Chiave `SavedLessons` per sincronizzazione
- **WidgetKit**: Timeline automatiche per aggiornamenti

## 📱 Funzionalità

### App principale:

- ✅ Visualizzazione orario settimanale
- ✅ Gestione voti con medie per materia
- ✅ Notifiche 5 minuti prima delle lezioni
- ✅ Live Activities per lezioni in corso

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

### Configurazione:

1. **App Groups**: Configurare `group.schedule.app` per tutti i target
2. **Entitlements**: Verificare che tutti i target abbiano l'App Group
3. **Certificates**: Assicurarsi che i profili di provisioning supportino App Groups

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

## 🎯 Prossimi sviluppi

- [ ] Sincronizzazione cloud con CloudKit
- [ ] Import/export orario da file
- [ ] Temi personalizzabili
- [ ] Notifiche promemoria compiti
- [ ] Statistiche frequenza lezioni

## 📝 Log modifiche

### v1.0 (Corrente):

- ✅ Corretti errori compilazione NotificationManager
- ✅ Aggiornata logica timeline widget iOS
- ✅ Configurato App Group per condivisione dati
- ✅ Migliorata sincronizzazione tra app e widget
- ✅ Rimosso supporto Apple Watch per semplificare il progetto
