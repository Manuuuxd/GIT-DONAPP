# chats/services/faq.py
from django.core.cache import cache
from ..models import FAQ
from .textutils import normalize_simple
import re

CACHE_TTL = 600

def _compile_flags(flag_str: str | None) -> int:
    # soporta combos tipo "im" si algún día los usas
    f = (flag_str or "").lower()
    flags = 0
    if "i" in f: flags |= re.I
    if "m" in f: flags |= re.M
    if "s" in f: flags |= re.S
    if "x" in f: flags |= re.X
    return flags

def _load_faqs(language="es", tenant=None):
    key = f"faq:full:{language}:{tenant or 'global'}"
    data = cache.get(key)
    if data:
        return data

    qs = FAQ.objects.filter(is_active=True, language=language)
    if tenant:
        qs = qs.filter(tenant=tenant)

    # 👈 aquí estaba el problema: 'patterns' no existe; es 'regexes'
    qs = qs.prefetch_related("synonyms", "regexes")

    exact, regexes = {}, []
    for f in qs:
        exact[normalize_simple(f.question_canonical)] = f

        for s in f.synonyms.all():
            exact[normalize_simple(s.text)] = f

        # 👈 y acá igual, usar f.regexes
        for p in f.regexes.all():
            try:
                flags = _compile_flags(getattr(p, "flags", "i"))
                regexes.append((re.compile(p.pattern, flags), f))
            except re.error:
                # si el patrón viene malo, lo ignoramos
                continue

    data = {"exact": exact, "regexes": regexes}
    cache.set(key, data, CACHE_TTL)
    return data

def faq_exact_match(q: str, language="es", tenant=None):
    qn = normalize_simple(q)
    data = _load_faqs(language, tenant)

    if qn in data["exact"]:
        f = data["exact"][qn]
        resp = {"answer": f.answer_html, "sources": [f"/faq/{f.id}"]}
        if f.action:
            resp["action"] = f.action
        return resp

    for rx, f in data["regexes"]:
        if rx.search(q):
            resp = {"answer": f.answer_html, "sources": [f"/faq/{f.id}"]}
            if f.action:
                resp["action"] = f.action
            return resp

    return None
