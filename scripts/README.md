# 📄 Script di Estrazione Orari

Questa cartella contiene gli script Python per estrarre e aggiornare gli orari scolastici dal PDF ufficiale.

## 📦 File

- **`pdf_timetable_extractor.py`**: Script principale per l'estrazione degli orari da PDF
- **`orario_vallauri.pdf`**: PDF sorgente con gli orari di tutte le classi
- **`requirements.txt`**: Dipendenze Python necessarie

## 🚀 Utilizzo

### Installazione dipendenze

```bash
pip3 install -r requirements.txt
```

### Estrazione orari

```bash
python3 pdf_timetable_extractor.py orario_vallauri.pdf
```

Lo script genererà:
- `orari_tutte_classi.json`: File JSON con tutti gli orari delle 81 classi

### Aggiornamento app

Dopo aver generato il JSON:

1. Copia il file generato nella cartella Resources dell'app:
   ```bash
   cp orari_tutte_classi.json ../Vallauri_da_Vincenzo/Resources/
   ```

2. Se necessario, modifica manualmente il JSON per correzioni specifiche (es. 5A INF)

## ⚠️ Note

- Il PDF del Vallauri usa caratteri doppiati (es. "55AA IINNFF")
- Lo script gestisce automaticamente celle unite verticalmente (frecce `\uea1e`)
- Alcuni orari potrebbero richiedere correzioni manuali post-estrazione

## 📊 Statistiche ultima estrazione

- **Data**: 16 ottobre 2025
- **Classi totali**: 81
- **Lezioni totali**: 2721
- **Dimensione JSON**: ~740 KB
