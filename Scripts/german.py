import json
import os
import subprocess

def generate_german_json_absolute():
    hours = ["zwölf", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf"]
    tens = ["", "", "zwanzig", "dreißig", "vierzig", "fünfzig"]
    ones = ["", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun"]
    
    word_clock = {}

    for h in range(24):
        current_h = hours[h % 12]
        next_h = hours[(h + 1) % 12]
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            if m == 0:
                h_text = "ein" if current_h == "eins" else current_h
                phrase = f"{h_text} Uhr genau"
            elif m == 15:
                phrase = f"viertel nach {current_h}"
            elif m == 30:
                phrase = f"halb {next_h}"
            elif m == 45:
                phrase = f"viertel vor {next_h}"
            else:
                h_text = "ein" if current_h == "eins" else current_h
                if m < 10:
                    minute_part = f"null {ones[m]}"
                elif 10 <= m <= 19:
                    teens = ["zehn", "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn"]
                    minute_part = teens[m-10]
                else:
                    t, u = divmod(m, 10)
                    if u == 0:
                        minute_part = tens[t]
                    else:
                        u_text = "ein" if u == 1 else ones[u]
                        minute_part = f"{u_text}und{tens[t]}"
                phrase = f"{h_text} {minute_part}"

            word_clock[time_key] = phrase.strip()

    # Get the exact folder where THIS script is saved
    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, 'word_clock_de.json')

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)
    
    print(f"\n🚀 FILE CREATED AT: {file_path}")
    
    # Attempt to open the file automatically in your default editor
    try:
        if os.name == 'posix': # Mac/Linux
            subprocess.call(['open', file_path])
        else: # Windows
            os.startfile(file_path)
    except:
        print("Could not open file automatically, please check the sidebar.")

if __name__ == "__main__":
    generate_german_json_absolute()
