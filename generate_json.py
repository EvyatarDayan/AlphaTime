import json

def generate_modern_hebrew_time_json():
    # Hours (Feminine)
    hours = [
        "שתים עשרה", "אחת", "שתים", "שלוש", "ארבע", "חמש", 
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
            
            if m == 0:
                minute_phrase = "" 
            elif m == 1:
                minute_phrase = "דקה אחת" 
            elif m == 2:
                minute_phrase = "שתי דקות"
            elif 3 <= m <= 10:
                minute_phrase = f"{ones[m]} דקות"
            elif 11 <= m <= 19:
                minute_phrase = f"{teens[m-10]} דקות"
            else:
                # Handle 20-59 (e.g., "ארבעים ואחת דקות")
                ten_part = tens[m // 10]
                unit_val = m % 10
                
                if unit_val == 0:
                    minute_phrase = f"{ten_part} דקות"
                else:
                    minute_phrase = f"{ten_part} ו{ones[unit_val]} דקות"
            
            # Combined: "ארבע" + "ארבעים ואחת דקות" (No 'vav' between them)
            word_clock[time_key] = f"{hour_word} {minute_phrase}".strip()

    with open('word_clock_he.json', 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    generate_modern_hebrew_time_json()
    print("Success! JSON created with modern Hebrew phrasing.")