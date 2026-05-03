import json
import os

def generate_french_hybrid_json():
    # French hours (Feminine)
    # Note: 1 is 'une', others are plural 'heures'
    hours = ["douze", "une", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix", "onze"]
    
    tens = ["", "", "vingt", "trente", "quarante", "cinquante"]
    ones = ["", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf"]
    
    word_clock = {}

    for h in range(24):
        display_h = h % 12
        h_word = hours[display_h]
        
        # In French, you must say "heure" (singular) or "heures" (plural)
        h_label = "heure" if h_word == "une" else "heures"
        
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            # --- HYBRID LOGIC ---
            
            # 1. Quarters and Half (Traditional)
            if m == 0:
                phrase = f"{h_word} {h_label} pile" # "pile" means "on the dot"
            elif m == 15:
                phrase = f"{h_word} {h_label} et quart"
            elif m == 30:
                phrase = f"{h_word} {h_label} et demie"
            elif m == 45:
                # 45 is usually "Moins le quart" (Next hour minus the quarter)
                next_h_word = hours[(display_h + 1) % 12]
                next_h_label = "heure" if next_h_word == "une" else "heures"
                phrase = f"{next_h_word} {next_h_label} moins le quart"
            
            # 2. Modern Digital Style
            else:
                if m < 10:
                    minute_part = f"zéro {ones[m]}"
                elif 10 <= m <= 19:
                    teens = ["dix", "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit", "dix-neuf"]
                    minute_part = teens[m-10]
                else:
                    t, u = divmod(m, 10)
                    if u == 0:
                        minute_part = tens[t]
                    elif u == 1:
                        # French uses "et un" for 21, 31, 41, 51
                        minute_part = f"{tens[t]} et un"
                    else:
                        minute_part = f"{tens[t]}-{ones[u]}"
                
                phrase = f"{h_word} {h_label} {minute_part}"

            word_clock[time_key] = phrase.strip()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, 'word_clock_fr.json')

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)
    
    print(f"🇫🇷 French Hybrid JSON created at: {file_path}")

if __name__ == "__main__":
    generate_french_hybrid_json()
