# donapp/chats/services/router.py
from .faq import faq_exact_match
from .semantic import semantic_search_topk
from .rag import answer_with_rag
from .llm import ask_model
from .config import ChatConfig

import logging, os, re, requests

log = logging.getLogger(__name__)

# ============================
# Admin NLU
# ============================
ADMIN_NLU_URL = os.getenv("ADMIN_NLU_URL", "http://localhost:8081/admin/nlu")
ADMIN_NLU_TIMEOUT = float(os.getenv("ADMIN_NLU_TIMEOUT", "4.0"))

# “Huele” a instrucción admin: crear campañas, filtrar usuarios, etc.
_ADMIN_INTENT_RE = re.compile(
    r"(campa[nñ]a|usuarios|donantes|voluntarios|filtra(r|n)?|buscar|muestr(a|en)|"
    r"crear|agendar|programar|lanzar|hacer)\b",
    re.I
)

# targets válidos a nivel de UI
_ALLOWED_TARGETS = {
    "nueva_campania",
    "usuarios_lista",
    "campanias_activas",
    "panel_metricas",
    "encuestas_activas",
    "mensaje_directo",
}

def _looks_admin_intent(text: str) -> bool:
    return bool(_ADMIN_INTENT_RE.search(text or ""))


def _call_admin_nlu(texto: str) -> dict | None:
    """
    Llama al microservicio NLU. Devuelve dict con:
    {
      "action": {"type": "...", "target": "..."},
      "payload": {"form": {...}} | {"query": {...}},
      "confidence": 0.xx
    }
    o None si no hay acción util.
    """
    try:
        r = requests.post(ADMIN_NLU_URL, json={"texto": texto}, timeout=ADMIN_NLU_TIMEOUT)
        if r.status_code != 200:
            log.warning("Admin NLU %s -> %s %s", ADMIN_NLU_URL, r.status_code, r.text[:300])
            return None
        data = r.json()
        action = data.get("action") or {}
        target = (action.get("target") or "").strip()
        atype = (action.get("type") or "").strip()
        if target in _ALLOWED_TARGETS and atype:
            # normaliza estructura hacia el front
            return {
                "action": {"type": atype, "target": target},
                "payload": data.get("payload") or {},
                "confidence": data.get("confidence", 0.0)
            }
        return None
    except Exception as e:
        log.exception("Error llamando Admin NLU: %s", e)
        return None


def route_question(question: str, user_id: str, cfg: ChatConfig):
    """
    Orquestador:
      0) Intent admin (NLU) si aplica
      1) FAQ exacta
      2) Semántico (directo con acción si payload la trae)
      3) RAG (si config lo amerita)
      4) LLM fallback
    """

    q = (question or "").strip()

    # 0) Si huele a instrucción admin, primero probamos el NLU
    if _looks_admin_intent(q):
        nlu = _call_admin_nlu(q)
        if nlu:
            # respuesta corta + acción navegable con payload
            return {
                "route": "admin_nlu",
                "answer": "Listo, abriendo lo que me pediste",
                "sources": [],
                "scores": None,
                "action": {
                    "type": nlu["action"]["type"],
                    "target": nlu["action"]["target"],
                    "payload": nlu.get("payload", {})
                }
            }

    # 1) FAQ exact
    hit = faq_exact_match(q, language=cfg.language, tenant=cfg.faq_tenant)
    if hit:
        return {
            "route": "faq_exact",
            "answer": hit.get("answer", ""),
            "sources": hit.get("sources", []),
            "scores": None,
            "action": hit.get("action")  # si tu FAQ incluye {"type","target","payload"}
        }

    # 2) Semántico (usa Qdrant)
    hits = semantic_search_topk(
        query=q, top_k=4,
        collection=cfg.qdrant_collection, filters=cfg.qdrant_filters
    )
    if hits:
        top = hits[0]
        payload = top.get("payload") or {}
        doc_answer = payload.get("answer") or top.get("text") or ""
        action_from_payload = payload.get("action")  # puede traer {"type","target","payload"}

        if top.get("score", 0) >= cfg.tau_direct:
            return {
                "route": "semantic_direct",
                "answer": doc_answer,
                "sources": [h.get("url") for h in hits if h.get("url")],
                "scores": [round(h.get("score", 0), 4) for h in hits],
                "action": action_from_payload,
            }

    # 3) RAG (opcional según cfg)
    # Si quieres activar RAG con umbral propio:
    if getattr(cfg, "tau_rag", None) is not None:
        rag = answer_with_rag(q, collection=cfg.qdrant_collection, filters=cfg.qdrant_filters)
        if rag and rag.get("answer") and rag.get("score", 0) >= cfg.tau_rag:
            return {
                "route": "rag",
                "answer": rag["answer"],
                "sources": rag.get("sources", []),
                "scores": [rag.get("score")],
                "action": rag.get("action"),  # por si tu RAG devuelve acciones
            }

    # 4) LLM fallback
    system = "Eres un asistente útil..."
    resp = ask_model(prompt=q, system=system, endpoint_id=cfg.endpoint_id, sync=True)
    if resp.get("error"):
        return {
            "route": "llm",
            "answer": f"No pude consultar el LLM ({resp.get('error')})",
            "sources": [],
            "scores": None,
            "action": None
        }
    return {
        "route": "llm",
        "answer": resp.get("text", ""),
        "sources": [],
        "scores": None,
        "action": None
    }
