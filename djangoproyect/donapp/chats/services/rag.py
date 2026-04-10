from .llm import ask_model

RAG_SYSTEM_PROMPT = (
    "Eres un asistente conciso y factual. "
    "Solo puedes usar la información del CONTEXTO. "
    "Si falta información, di que no la tienes y sugiere cómo obtenerla. "
    "Cita las fuentes como [n] según el orden entregado."
)

def answer_with_rag(question: str, hits: list[dict], endpoint_id: str | None = None):
    chunks, sources = [], []
    for i, h in enumerate(hits, start=1):
        chunks.append(f"[{i}] {h['text']}")
        if h.get("url"): sources.append(h["url"])
    contexto = "\n\n".join(chunks)
    prompt = f"{RAG_SYSTEM_PROMPT}\n\nPREGUNTA: {question}\n\nCONTEXTO:\n{contexto}"
    resp = ask_model(prompt=prompt, system=None, endpoint_id=endpoint_id, sync=True)
    return resp.get("text",""), sources
