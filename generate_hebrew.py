import json

def generate_perfect_hebrew_time_json():
    # Hours (Feminine)
    hours = [
        "שתים עשרה", "אחת", "שתיים", "שלוש", "ארבע", "חמש", 
        "שש", "שבע", "שמונה", "תשע", "עשר", "אחת עשרה"
    ]
    
    # Numbers for minutes (Feminine)
    tens = ["", "", "עשרים", "שלושים", "ארבעים", "חמישים"]
    ones = ["", "אחת", "שתיים", "שלוש", "ארבע", "חמש", "שש", "שבע", "שמונה", "תשע"]
    teens = [
        "עשר", "אחת עשרה", "שתים עשרה", "שלוש עשרה", "ארבע עשרה", 
        "חמש עשרה", "שש עשרה", "שבע עשרה", "שמונה עשרה", "תשע עשרה"
    ]

    word_clock = {}

    for h in range(24):
        display_h = h % 12
        hour_word = hours[display_h]
        
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            # 1. Handle Top of the Hour (00)
            if m == 0:
                minute_phrase = "בדיוק"
            
            # 2. Handle Minutes 1-9 (With Vav)
            elif 1 <= m <= 9:
                if m == 1:
                    minute_phrase = "ודקה אחת"
                elif m == 2:
                    minute_phrase = "ושתי דקות"
                else:
                    minute_phrase = f"ו{ones[m]} דקות"
                
            # 3. Handle Minutes 10-19 (Direct)
            elif 10 <= m <= 19:
                minute_phrase = f"{teens[m-10]} דקות"
                
            # 4. Handle Minutes 20-59 (Digital/Modern)
            else:
                ten_part = tens[m // 10]
                unit_val = m % 10
                
                if unit_val == 0:
                    minute_phrase = f"{ten_part} דקות"
                else:
                    minute_phrase = f"{ten_part} ו{ones[unit_val]} דקות"
            
            # COMBINE: Ensure no trailing/leading spaces
            word_clock[time_key] = f"{hour_word} {minute_phrase}".strip()

    with open('word_clock_he.json', 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    generate_perfect_hebrew_time_json()
    print("Success! Every hour entry now includes 'בדיוק'. Check 07:00 now.")