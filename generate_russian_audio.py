import asyncio
import edge_tts
import os
import shutil

async def main():
    ios_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\Sources\Audio"
    android_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\android_app\app\src\main\assets\audio"
    
    ios_out_ru = os.path.join(ios_audio_dir, "narek_russian_prayers.mp3")
    android_out_ru = os.path.join(android_audio_dir, "narek_russian_prayers.mp3")
    
    # Read sample russian prayer text
    sample_text = """
    Святой Григор Нарекаци. Книга скорбных песнопений. Слово к Богу из глубин сердца.
    Сконфужен взором, вздохом сокрушен,
    Вопль сердца своего, стон исступленный
    Тебе возношу я, Господи мой и Спаситель!
    Прими сие молитвенное пение сокрушенного духа
    И не отвергни слез моих горьких,
    Но призри на меня по великой милости Твоей
    И даруй мне исцеление и покой души.
    """
    
    communicate = edge_tts.Communicate(sample_text, "ru-RU-DmitryNeural", rate="-10%", pitch="-5Hz")
    await communicate.save(ios_out_ru)
    shutil.copyfile(ios_out_ru, android_out_ru)
    print(f"Generated Russian audio: {os.path.getsize(ios_out_ru)} bytes")

asyncio.run(main())
