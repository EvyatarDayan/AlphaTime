import json

def generate_nuanced_hebrew_json():
    hours = ["שתים עשרה", "אחת", "שתיים", "שלוש", "ארבע", "חמש", "שש", "שבע", "שמונה", "תשע", "עשר", "אחת עשרה"]
    tens = ["", "", "עשרים", "שלושים", "ארבעים", "חמישים"]
    ones = ["", "אחת", "שתיים", "שלוש", "ארבע", "חמש", "שש", "שבע", "שמונה", "תשע"]
    teens = ["עשר", "אחת עשרה", "שתים עשרה", "שלוש עשרה", "ארבע עשרה", "חמש עשרה", "שש עשרה", "שבע עשרה", "שמונה עשרה", "תשע עשרה"]

    word_clock = {}

    for h in range(24):
        hour_word = hours[h % 12]
        
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            # 1. Top of the hour
            if m == 0:
                minute_phrase = "בדיוק"
            
            # 2. Minutes 1-9 (Needs Vav)
            elif 1 <= m <= 9:
                if m == 1: minute_phrase = "ודקה אחת"
                elif m == 2: minute_phrase = "ושתי דקות"
                else: minute_phrase = f"ו{ones[m]} דקות"
                
            # 3. Minutes 10-19 (Needs Vav for natural flow)
            elif 10 <= m <= 19:
                minute_phrase = f"ו{teens[m-10]} דקות"
                
            # 4. Minutes 20, 30, 40, 50 (Round numbers - Needs Vav per your request)
            elif m in [20, 30, 40, 50]:
                minute_phrase = f"ו{tens[m // 10]} דקות"
                
            # 5. Complex minutes 21-59 (No Vav after hour - Digital style)
            else:
                t_part = tens[m // 10]
                u_part = ones[m % 10]
                # Note: No 'ו' at the very start of this phrase
                minute_phrase = f"{t_part} ו{u_part} דקות"

            word_clock[time_key] = f"{hour_word} {minute_phrase}".strip()

    filename = 'word_clock_final.json'
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)
    
    print(f"--- VERIFICATION ---")
    print(f"07:00 -> {word_clock['07:00']}") # Should be שבע בדיוק
    print(f"08:30 -> {word_clock['08:30']}") # Should be שמונה ושלושים דקות
    print(f"08:41 -> {word_clock['08:41']}") # Should be שמונה ארבעים ואחת דקות

if __name__ == "__main__":
    generate_nuanced_hebrew_json()
