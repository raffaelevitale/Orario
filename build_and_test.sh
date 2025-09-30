#!/bin/bash

# Script di build per verificare che tutto funzioni correttamente
# Uso: ./build_and_test.sh

#!/bin/bash

echo "🔧 Inizio build del progetto Orario Vallauri..."

# Naviga nella directory del progetto
cd "$(dirname "$0")"

# Controlla che Xcode sia installato
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcodebuild non trovato. Assicurati che Xcode sia installato."
    exit 1
fi

echo "📱 Building iOS app..."
xcodebuild -project Vallauri_da_Vincenzo.xcodeproj \
           -scheme Vallauri_da_Vincenzo \
           -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
           build

if [ $? -eq 0 ]; then
    echo "✅ iOS app build completato con successo"
else
    echo "❌ Errore nel build iOS app"
    exit 1
fi

echo "🔷 Building iOS widget extension..."
xcodebuild -project Vallauri_da_Vincenzo.xcodeproj \
           -scheme ScheduleWidgetExtension \
           -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
           build

if [ $? -eq 0 ]; then
    echo "✅ iOS widget extension build completato con successo"
else
    echo "❌ Errore nel build iOS widget extension"
    exit 1
fi

echo "🎉 Tutti i build completati con successo!"
echo ""
echo "📋 Sommario configurazione:"
echo "   • App Group: group.vallauri.schedule"
echo "   • iOS Widget: ScheduleWidgetExtension.appex"
echo ""
echo "🚀 Passi successivi:"
echo "   1. Configurare App Groups nell'Apple Developer Account"
echo "   2. Verificare entitlements in tutti i target"
echo "   3. Testare widget iOS in simulatore"
echo "   4. Modifica dati nell'app e verifica aggiornamenti widget"

echo "🎉 Tutti i build completati con successo!"
echo ""
echo "📋 Sommario configurazione:"
echo "   • App Group: group.vallauri.schedule"
echo "   • iOS Widget: ScheduleWidgetExtension.appex"
echo "   • watchOS App: watch_orario_app.app"
echo "   • watchOS Widget: watch_orarioExtension.appex"
echo "   • Dati condivisi: UserDefaults con chiave 'SavedLessons'"
echo ""
echo "🔍 Per testare:"
echo "   1. Apri l'app iOS nel simulatore"
echo "   2. Aggiungi widget alla schermata home"
echo "   3. Apri Watch app e cerca 'Orario' nelle complicazioni"
echo "   4. Modifica dati nell'app e verifica aggiornamenti widget"