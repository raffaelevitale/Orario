#!/usr/bin/env python3
"""
Estrattore completo di orari da PDF - Vallauri da Vincenzo
Estrae l'orario di TUTTE le classi e genera un JSON strutturato

Requisiti:
    pip install PyPDF2 pdfplumber tabula-py pandas

Uso:
    python pdf_timetable_extractor.py <percorso_pdf>
"""

import sys
import json
import re
from typing import List, Dict, Tuple, Optional
from pathlib import Path

try:
    import pdfplumber
except ImportError:
    print("❌ Errore: pdfplumber non installato")
    print("Installa con: pip install pdfplumber")
    sys.exit(1)

# ============================================================================
# CONFIGURAZIONE SCANSIONI ORARIE
# ============================================================================

SCHEDULES = {
    'lssa': {
        'all': {
            1: ("07:50", "08:50"),
            2: ("08:50", "09:45"),
            3: ("09:45", "10:40"),
            'intervallo': ("10:40", "11:00"),
            4: ("11:00", "11:55"),
            5: ("11:55", "12:50"),
            6: ("12:50", "13:40")
        }
    },
    'standard': {
        'lun_mer_ven': {
            1: ("07:50", "08:50"),
            2: ("08:50", "09:45"),
            3: ("09:45", "10:40"),
            'intervallo': ("10:40", "11:00"),
            4: ("11:00", "11:55"),
            5: ("11:55", "12:50"),
            6: ("12:50", "13:40")
        },
        'mar_gio': {
            1: ("07:50", "08:45"),
            2: ("08:45", "09:35"),
            3: ("09:35", "10:25"),
            'intervallo': ("10:25", "10:30"),
            4: ("10:30", "11:20"),
            5: ("11:20", "12:10"),
            'intervallo2': ("12:10", "12:20"),
            6: ("12:20", "13:10"),
            7: ("13:10", "14:00")
        }
    },
    'first_year': {
        'mer_ven': {
            1: ("07:50", "08:50"),
            2: ("08:50", "09:45"),
            3: ("09:45", "10:40"),
            'intervallo': ("10:40", "11:00"),
            4: ("11:00", "11:55"),
            5: ("11:55", "12:50"),
            6: ("12:50", "13:40")
        },
        'lun_mar_gio': {
            1: ("07:50", "08:45"),
            2: ("08:45", "09:35"),
            3: ("09:35", "10:25"),
            'intervallo': ("10:25", "10:30"),
            4: ("10:30", "11:20"),
            5: ("11:20", "12:10"),
            'intervallo2': ("12:10", "12:20"),
            6: ("12:20", "13:10"),
            7: ("13:10", "14:00")
        }
    }
}

SUBJECT_COLORS = {
    "Inglese": "#42a5f5",
    "Lingua inglese": "#42a5f5",
    "Sistemi e reti": "#66bb6a",
    "Sistemi automatici": "#66bb6a",
    "Informatica": "#7e57c2",
    "Tecnologie informatiche": "#7e57c2",
    "T.P.S.I.T.": "#ffa726",
    "T.P.S.E.E.": "#ffa726",
    "Gestione progetto": "#26a69a",
    "Matematica": "#ef5350",
    "Italiano": "#8d6e63",
    "Storia": "#6d4c41",
    "Religione": "#fbc02d",
    "Ginnastica": "#ff7043",
    "Scienze motorie": "#ff7043",
    "Telecomunicazioni": "#9c27b0",
    "Elettrotecnica": "#f44336",
    "Meccanica": "#795548",
    "Francese": "#4fc3f7",
    "Spagnolo": "#ffa726",
    "Economia aziendale": "#4caf50",
    "Diritto": "#2196f3",
    "Fisica": "#ff5722",
    "Chimica": "#00bcd4",
    "Geografia": "#8bc34a",
    "Filosofia": "#673ab7",
    "Scienze naturali": "#4caf50",
    "Arte": "#ff9800",
    "INTERVALLO": "#ffd54f"
}

DAYS_MAP = {
    'Lunedì': 1, 'Lun': 1, 'LUN': 1,
    'Martedì': 2, 'Mar': 2, 'MAR': 2,
    'Mercoledì': 3, 'Mer': 3, 'MER': 3,
    'Giovedì': 4, 'Gio': 4, 'GIO': 4,
    'Venerdì': 5, 'Ven': 5, 'VEN': 5,
    'Sabato': 6, 'Sab': 6, 'SAB': 6
}

# ============================================================================
# FUNZIONI UTILITÀ
# ============================================================================

def get_color_for_subject(subject: str) -> str:
    """Ottiene il colore per una materia"""
    subject_clean = subject.strip()
    
    for key, color in SUBJECT_COLORS.items():
        if key.lower() in subject_clean.lower() or subject_clean.lower() in key.lower():
            return color
    
    return "#78909c"

def detect_schedule_type(class_name: str) -> str:
    """Determina il tipo di scansione oraria per la classe"""
    class_upper = class_name.upper()
    
    if 'LIC' in class_upper or 'LSSA' in class_upper:
        return 'lssa'
    
    if class_upper.startswith('1') and any(x in class_upper for x in ['ELT', 'INF', 'MEC']):
        return 'first_year'
    
    return 'standard'

def get_schedule_for_day(class_name: str, day: int) -> Dict:
    """Ottiene la scansione oraria per una classe in un giorno specifico"""
    schedule_type = detect_schedule_type(class_name)
    
    if schedule_type == 'lssa':
        return SCHEDULES['lssa']['all']
    elif schedule_type == 'first_year':
        if day in [3, 5]:  # Mercoledì, Venerdì
            return SCHEDULES['first_year']['mer_ven']
        else:
            return SCHEDULES['first_year']['lun_mar_gio']
    else:  # standard
        if day in [2, 4]:  # Martedì, Giovedì
            return SCHEDULES['standard']['mar_gio']
        else:
            return SCHEDULES['standard']['lun_mer_ven']

def normalize_class_name(raw_name: str) -> str:
    """Normalizza il nome della classe"""
    # Rimuovi spazi extra e caratteri strani
    clean = re.sub(r'\s+', ' ', raw_name.strip())
    # Pattern: numero + lettera + specializzazione
    match = re.match(r'(\d)([A-Z])\s*(\w+)', clean)
    if match:
        return f"{match.group(1)}{match.group(2)} {match.group(3)}"
    return clean

def normalize_teacher_name(raw_name: str) -> str:
    """Normalizza il nome del docente"""
    clean = raw_name.strip()
    # Rimuovi caratteri strani
    clean = re.sub(r'[^\w\s,.\']', '', clean)
    return clean

def time_to_minutes(time_str: str) -> int:
    """Converte orario in minuti dalla mezzanotte"""
    try:
        h, m = map(int, time_str.split(':'))
        return h * 60 + m
    except:
        return 0

def split_long_lessons(lesson: Dict, schedule: Dict) -> List[Dict]:
    """Spezza lezioni consecutive in slot separati"""
    start_min = time_to_minutes(lesson['startTime'])
    end_min = time_to_minutes(lesson['endTime'])
    
    # Trova slot coperti
    covered_slots = []
    for slot_num, (slot_start, slot_end) in schedule.items():
        if isinstance(slot_num, str):
            continue
        
        slot_start_min = time_to_minutes(slot_start)
        slot_end_min = time_to_minutes(slot_end)
        
        if start_min < slot_end_min and end_min > slot_start_min:
            covered_slots.append((slot_num, slot_start, slot_end))
    
    if len(covered_slots) <= 1:
        return [lesson]
    
    # Spezza in più lezioni
    split_lessons = []
    for slot_num, slot_start, slot_end in covered_slots:
        new_lesson = lesson.copy()
        new_lesson['startTime'] = slot_start
        new_lesson['endTime'] = slot_end
        split_lessons.append(new_lesson)
    
    return split_lessons

def add_intervals(lessons: List[Dict], class_name: str) -> List[Dict]:
    """Aggiunge gli intervalli al programma"""
    result = []
    
    by_day = {}
    for lesson in lessons:
        day = lesson['dayOfWeek']
        if day not in by_day:
            by_day[day] = []
        by_day[day].append(lesson)
    
    for day in sorted(by_day.keys()):
        day_lessons = sorted(by_day[day], key=lambda x: x['startTime'])
        schedule = get_schedule_for_day(class_name, day)
        
        intervals = []
        for key, (start, end) in schedule.items():
            if isinstance(key, str) and 'intervallo' in key.lower():
                intervals.append({
                    'subject': 'INTERVALLO',
                    'teacher': '',
                    'classroom': '',
                    'dayOfWeek': day,
                    'startTime': start,
                    'endTime': end,
                    'color': '#ffd54f'
                })
        
        combined = day_lessons + intervals
        combined.sort(key=lambda x: x['startTime'])
        result.extend(combined)
    
    return result

# ============================================================================
# ESTRAZIONE DAL PDF
# ============================================================================

def extract_tables_from_pdf(pdf_path: str) -> List[Dict]:
    """
    Estrae tutte le tabelle dal PDF usando pdfplumber
    
    Returns:
        Lista di dizionari con i dati estratti
    """
    all_data = []
    
    print(f"📄 Apertura PDF: {pdf_path}")
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"📚 Pagine totali: {len(pdf.pages)}")
        
        for page_num, page in enumerate(pdf.pages, 1):
            print(f"📖 Processando pagina {page_num}/{len(pdf.pages)}...")
            
            # Estrai testo completo della pagina
            text = page.extract_text()
            if not text:
                continue
            
            # Il formato del Vallauri ha caratteri doppiati: "11AA AAFFMM ((2277))"
            # Dobbiamo rimuovere i caratteri doppi
            
            # Cerca il pattern con caratteri doppiati: 11AA AAFFMM ((27))
            class_match = re.search(r'(\d)\1([A-Z])\2\s+([A-Z]+)\3*\s+\(\((\d+)\)\)', text)
            
            if not class_match:
                # Prova pattern alternativo senza doppiatura
                class_match = re.search(r'(\d[A-Z])\s+([A-Z]+)\s+\((\d+)\)', text)
                if class_match:
                    current_class = f"{class_match.group(1)} {class_match.group(2)}"
                else:
                    continue
            else:
                # Ricostruisci dalla versione doppiata rimuovendo i caratteri duplicati
                numero = class_match.group(1)
                lettera = class_match.group(2)
                specializzazione_doppia = class_match.group(3)
                
                # Rimuovi caratteri doppi dalla specializzazione
                # Es: "AAFFMM" -> "AFM", "IINNFF" -> "INF"
                specializzazione = ""
                for i in range(0, len(specializzazione_doppia), 2):
                    if i < len(specializzazione_doppia):
                        specializzazione += specializzazione_doppia[i]
                
                current_class = f"{numero}{lettera} {specializzazione}"
            
            print(f"  📚 Classe: {current_class}")
            
            # Estrai tabelle
            tables = page.extract_tables()
            
            for table_idx, table in enumerate(tables):
                if not table or len(table) < 2:
                    continue
                
                # La prima cella contiene tutto il contenuto
                if table[0] and table[0][0]:
                    main_content = table[0][0]
                    
                    # Cerca le righe dell'orario (formato: "1 Materia\nDocente\nAula")
                    # Ogni riga inizia con un numero (1-7)
                    lines = main_content.split('\n')
                    
                    current_slot = None
                    slot_data = {}
                    
                    for line in lines:
                        line = line.strip()
                        if not line:
                            continue
                        
                        # Controlla se inizia con un numero di slot (1-7)
                        slot_match = re.match(r'^(\d)\s+(.+)', line)
                        if slot_match:
                            current_slot = int(slot_match.group(1))
                            slot_data[current_slot] = {'content': [slot_match.group(2)]}
                        elif current_slot:
                            slot_data[current_slot]['content'].append(line)
                    
                    # Gestione celle unite: riempi None con valore precedente per ogni colonna
                    filled_table = []
                    for row in table[1:]:  # Salta la prima riga (header completo)
                        filled_table.append(list(row) if row else [None] * 7)
                    
                    # Per ogni colonna (giorno), riempi le celle None con il valore precedente
                    # MA NON riempire le celle dopo una freccia (sono estensioni, non nuove lezioni)
                    for col_idx in range(1, min(7, max(len(r) for r in filled_table if r))):
                        last_value = None
                        last_was_arrow = False
                        
                        for row_idx in range(len(filled_table)):
                            if col_idx < len(filled_table[row_idx]):
                                cell = filled_table[row_idx][col_idx]
                                
                                # Se la cella precedente era una freccia, NON riempire
                                if last_was_arrow and (not cell or not cell.strip() or cell == 'None'):
                                    filled_table[row_idx][col_idx] = '___SKIP___'  # Marca per saltare
                                    continue
                                
                                if cell and cell.strip() and cell not in ['None', '']:
                                    # Controlla se è una freccia
                                    if '\uea1e' in str(cell):
                                        last_was_arrow = True
                                    else:
                                        last_value = cell
                                        last_was_arrow = False
                                elif last_value and not (cell and cell.strip()) and not last_was_arrow:
                                    # Cella vuota o None: usa il valore precedente solo se non c'era freccia prima
                                    filled_table[row_idx][col_idx] = last_value
                    
                    # Prima passata: estrai tutte le lezioni normali
                    lessons_by_day = {}  # {(day, start_slot): lesson_data}
                    
                    for row_idx in range(len(filled_table)):
                        row = filled_table[row_idx]
                        if not row:
                            continue
                        
                        slot_num = row_idx + 1  # Gli slot partono da 1
                        
                        # Processa le celle dei giorni (colonne 1-6 = lun-sab)
                        for col_idx in range(1, min(7, len(row))):
                            cell = row[col_idx]
                            
                            # Salta celle vuote, marcate per skip, o con freccia
                            if not cell or cell == 'None' or cell == '___SKIP___' or not cell.strip():
                                continue
                            
                            # Se contiene freccia, marca per estensione
                            if '\uea1e' in str(cell):
                                # Trova l'ultima lezione valida in questo giorno
                                day_num = col_idx
                                for prev_slot in range(row_idx, -1, -1):
                                    key = (day_num, prev_slot + 1)
                                    if key in lessons_by_day:
                                        # Estendi la lezione precedente
                                        lessons_by_day[key]['extended_slots'] = lessons_by_day[key].get('extended_slots', 0) + 1
                                        break
                                continue
                            
                            day_num = col_idx  # 1=lun, 2=mar, ..., 6=sab
                            
                            # Parse cell: formato "Materia\nDocente\nAula"
                            cell_lines = [l.strip() for l in str(cell).split('\n') if l.strip() and '\uea1e' not in l]
                            
                            if len(cell_lines) >= 1:
                                subject = cell_lines[0]
                                teacher = cell_lines[1] if len(cell_lines) > 1 else ""
                                classroom = cell_lines[2] if len(cell_lines) > 2 else ""
                                
                                # Determina orari in base alla classe e giorno
                                schedule = get_schedule_for_day(current_class, day_num)
                                
                                # Trova l'orario dello slot
                                slot_time = None
                                for s_num, (start, end) in schedule.items():
                                    if s_num == slot_num:
                                        slot_time = (start, end)
                                        break
                                
                                if not slot_time:
                                    continue
                                
                                lesson_data = {
                                    'class': current_class,
                                    'subject': subject,
                                    'teacher': normalize_teacher_name(teacher),
                                    'classroom': classroom,
                                    'dayOfWeek': day_num,
                                    'startTime': slot_time[0],
                                    'endTime': slot_time[1],
                                    'color': get_color_for_subject(subject),
                                    'extended_slots': 0  # Verrà incrementato se ci sono frecce dopo
                                }
                                
                                # Salva nel dizionario temporaneo per gestire estensioni
                                lessons_by_day[(day_num, slot_num)] = lesson_data
                    
                    # Seconda passata: applica estensioni e aggiungi a all_data
                    schedule = get_schedule_for_day(current_class, 1)  # Usa giorno 1 per riferimento
                    
                    for (day_num, slot_num), lesson_data in sorted(lessons_by_day.items()):
                        # Se la lezione ha slot estesi, aggiorna endTime
                        if lesson_data['extended_slots'] > 0:
                            day_schedule = get_schedule_for_day(current_class, day_num)
                            # Trova l'orario finale esteso
                            extended_slot = slot_num + lesson_data['extended_slots']
                            if extended_slot in day_schedule:
                                lesson_data['endTime'] = day_schedule[extended_slot][1]
                                print(f"    ⚡ Estesa lezione {lesson_data['subject'][:20]} su {lesson_data['extended_slots']+1} slot: {lesson_data['startTime']}-{lesson_data['endTime']}")
                        
                        # Rimuovi il campo temporaneo
                        del lesson_data['extended_slots']
                        
                        all_data.append(lesson_data)
    
    print(f"\n✅ Estrazione completata: {len(all_data)} lezioni trovate")
    return all_data

def extract_all_classes(pdf_path: str) -> Dict:
    """
    Estrae gli orari di TUTTE le classi dal PDF
    
    Returns:
        Dizionario con chiave = nome classe, valore = dati orario
    """
    print("\n" + "="*70)
    print("🎓 ESTRATTORE ORARI VALLAURI - TUTTE LE CLASSI")
    print("="*70 + "\n")
    
    # Estrai dati grezzi
    raw_data = extract_tables_from_pdf(pdf_path)
    
    if not raw_data:
        print("❌ Nessun dato estratto dal PDF")
        return {}
    
    # Raggruppa per classe
    classes = {}
    for lesson in raw_data:
        class_name = lesson['class']
        if class_name not in classes:
            classes[class_name] = []
        classes[class_name].append(lesson)
    
    print(f"\n📚 Classi trovate: {len(classes)}")
    for class_name in sorted(classes.keys()):
        print(f"  - {class_name}: {len(classes[class_name])} lezioni")
    
    # Processa ogni classe
    result = {}
    print("\n🔄 Processing classi...")
    
    for class_name, lessons in classes.items():
        print(f"\n  📖 Elaborazione {class_name}...")
        
        # NON spezzare lezioni lunghe - ora gestiamo correttamente i blocchi uniti dal PDF
        # Le lezioni con durata > 1 slot sono blocchi uniti indicati dalle frecce nel PDF
        processed = lessons
        
        # Aggiungi intervalli
        with_intervals = add_intervals(processed, class_name)
        
        # Ordina
        with_intervals.sort(key=lambda x: (x['dayOfWeek'], x['startTime']))
        
        result[class_name] = {
            'className': class_name,
            'scheduleType': detect_schedule_type(class_name),
            'totalLessons': len(with_intervals),
            'lessons': with_intervals
        }
        
        print(f"    ✓ {len(with_intervals)} slot totali (con intervalli)")
    
    return result

# ============================================================================
# SALVATAGGIO OUTPUT
# ============================================================================

def save_all_classes_json(all_classes: Dict, output_path: str):
    """Salva tutte le classi in un unico JSON"""
    output_data = {
        'school': 'Istituto Vallauri',
        'extractionDate': Path(output_path).stem,
        'totalClasses': len(all_classes),
        'classes': all_classes
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 JSON salvato: {output_path}")
    print(f"   Dimensione: {Path(output_path).stat().st_size / 1024:.2f} KB")

def save_individual_class_jsons(all_classes: Dict, output_dir: str):
    """Salva ogni classe in un JSON separato"""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    for class_name, class_data in all_classes.items():
        safe_name = class_name.replace(' ', '_').replace('/', '-')
        file_path = output_path / f"{safe_name}.json"
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(class_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n📁 {len(all_classes)} file JSON individuali salvati in: {output_dir}")

# ============================================================================
# MAIN
# ============================================================================

def main():
    if len(sys.argv) < 2:
        print("❌ Uso: python pdf_timetable_extractor.py <percorso_pdf>")
        print("\nEsempio:")
        print("  python pdf_timetable_extractor.py orario_vallauri.pdf")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    
    if not Path(pdf_path).exists():
        print(f"❌ File non trovato: {pdf_path}")
        sys.exit(1)
    
    # Estrai tutte le classi
    all_classes = extract_all_classes(pdf_path)
    
    if not all_classes:
        print("\n❌ Nessuna classe estratta")
        sys.exit(1)
    
    # Salva output
    output_file = "orari_tutte_classi.json"
    save_all_classes_json(all_classes, output_file)
    
    # Salva anche file individuali
    save_individual_class_jsons(all_classes, "orari_classi")
    
    # Statistiche finali
    print("\n" + "="*70)
    print("📊 STATISTICHE")
    print("="*70)
    print(f"Classi totali: {len(all_classes)}")
    
    total_lessons = sum(c['totalLessons'] for c in all_classes.values())
    print(f"Lezioni totali: {total_lessons}")
    
    print("\n✅ Estrazione completata con successo!")
    print("="*70 + "\n")

if __name__ == "__main__":
    main()
