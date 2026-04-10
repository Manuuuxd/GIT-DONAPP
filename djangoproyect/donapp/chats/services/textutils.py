# services/textutils.py
import re
import unicodedata

def normalize_simple(s: str) -> str:
    """
    Normaliza texto:
    - elimina mayúsculas/tildes
    - elimina espacios duplicados
    - deja solo letras y números básicos
    """
    if not s:
        return ""

    # minúsculas
    s = s.strip().lower()

    # quita tildes y signos raros
    s = ''.join(
        c for c in unicodedata.normalize("NFKD", s)
        if not unicodedata.combining(c)
    )

    # reemplaza múltiples espacios por uno
    s = re.sub(r"\s+", " ", s)

    # quita espacios iniciales/finales otra vez
    s = s.strip()

    return s


def is_valid_question(s: str) -> bool:
    """
    (opcional) usado en ChatAskView
    Revisa que la entrada no esté vacía
    ni contenga contenido peligroso o spam
    """
    if not s:
        return False

    s = s.lower()
    banned = ["<script", "drop table", "delete from", "select *", "http://", "https://"]
    return not any(bad in s for bad in banned)
