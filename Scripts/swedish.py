import json
import os

def generate_hybrid_swedish_json():
    hours = ["tolv", "ett", "två", "tre", "fyra", "fem", "sex", "sju", "åtta", "nio", "tio", "elva"]
    tens = ["", "", "tjugo", "trettio", "fyrtio", "femtio"]
    ones = ["", "ett", "två", "tre", "fyra", "fem", "sex", "sju", "åtta", "nio"]
    teens = ["tio", "elva", "tolv", "tretton", "fjorton", "femton", "sexton", "sjutton", "arton", "nitton"]

    word_clock = {}

    for h in range(24):
        # Current and Next hour words
        current_h = hours[h % 12]
        next_h = hours[(h + 1) % 12]
        
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            # --- HYBRID LOGIC ---
            
            # 1. Quarters and Half (Traditional Style)
            if m == 15:
                phrase = f"kvart över {current_h}"
            elif m == 25:
                phrase = f"fem i halv {next_h}"
            elif m == 30:
                phrase = f"halv {next_h}"
            elif m == 35:
                phrase = f"fem över halv {next_h}"
            elif m == 45:
                phrase = f"kvart i {next_h}"
            
            # 2. Top of the Hour
            elif m == 0:
                phrase = f"{current_h} precis"
                
            # 3. All other minutes (Digital Style)
            else:
                if m < 10:
                    minute_part = f"noll {ones[m]}"
                elif 10 <= m <= 19:
                    minute_part = teens[m-10]
                else:
                    t = m // 10
                    u = m % 10
                    minute_part = f"{tens[t]}{ones[u]}" if u else tens[t]
                
                phrase = f"{current_h} {minute_part}"

            word_clock[time_key] = phrase.strip()

    file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'word_clock_sv.json')
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Hybrid Swedish JSON created!")
    print(f"Digital check (01:41): {word_clock['01:41']}") # ett fyrtioett
    print(f"Traditional check (01:45): {word_clock['01:45']}") # kvart i två
    print(f"Crazy check (01:25): {word_clock['01:25']}") # fem i halv två

if __name__ == "__main__":
    generate_hybrid_swedish_json()
