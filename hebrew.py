import json
import os

def generate_nikud_hebrew_json():
    # Hours with Niqqud
    hours = ["שְׁתֵּים עֶשְׂרֵה", "אַחַת", "שְׁתַּיִם", "שָׁלוֹשׁ", "אַרְבַּע", "חָמֵשׁ", "שֵׁשׁ", "שֶׁבַע", "שְׁמוֹנֶה", "תֵּשַׁע", "עֶשֶׂר", "אַחַת עֶשְׂרֵה"]
    tens = ["", "", "עֶשְׂרִים", "שְׁלוֹשִׁים", "אַרְבָּעִים", "חֲמִישִׁים"]
    ones = ["", "אַחַת", "שְׁתַּיִם", "שָׁלוֹשׁ", "אַרְבַּע", "חָמֵשׁ", "שֵׁשׁ", "שֶׁבַע", "שְׁמוֹנֶה", "תֵּשַׁע"]
    teens = ["עֶשֶׂר", "אַחַת עֶשְׂרֵה", "שְׁתֵּים עֶשְׂרֵה", "שְׁלוֹשׁ עֶשְׂרֵה", "אַרְבַּע עֶשְׂרֵה", "חֲמֵשׁ עֶשְׂרֵה", "שֵׁשׁ עֶשְׂרֵה", "שֶׁבַע עֶשְׂרֵה", "שְׁמוֹנֶה עֶשְׂרֵה", "תֵּשַׁע עֶשְׂרֵה"]

    word_clock = {}

    for h in range(24):
        hour_word = hours[h % 12]
        for m in range(60):
            time_key = f"{h:02d}:{m:02d}"
            
            if m == 0:
                minute_phrase = "בְּדִיּוּק"
            elif m == 1:
                minute_phrase = "וְדַקָּה אַחַת"
            elif m == 2:
                minute_phrase = "וּשְׁתֵּי דַּקּוֹת"
            elif 3 <= m <= 9:
                minute_phrase = f"וְ{ones[m]} דַּקּוֹת"
            elif 10 <= m <= 19:
                minute_phrase = f"וְ{teens[m-10]} דַּקּוֹת"
            elif m in [20, 30, 40, 50]:
                minute_phrase = f"וְ{tens[m // 10]} דַּקּוֹת"
            else:
                minute_phrase = f"{tens[m // 10]} וְ{ones[m % 10]} דַּקּוֹת"

            word_clock[time_key] = f"{hour_word} {minute_phrase}".strip()

    # FORCE PATH TO CURRENT DIRECTORY
    current_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_dir, 'word_clock_nikud_final.json')

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(word_clock, f, indent=2, ensure_ascii=False)

    print(f"\n✅ SUCCESS!")
    print(f"📍 File saved to: {file_path}")
    print(f"⏰ Example (08:30): {word_clock['08:30']}")

if __name__ == "__main__":
    generate_nikud_hebrew_json()