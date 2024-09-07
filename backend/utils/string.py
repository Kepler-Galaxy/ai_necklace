import re

def words_count(text: str) -> int:
    # A word is separated by one or more whitespace, or a Chinese character
    whitespace_words = len(re.split(r'\s+', text))
    chinese_characters = len(re.findall(r'[\u4e00-\u9fa5]', text))
    return whitespace_words + chinese_characters