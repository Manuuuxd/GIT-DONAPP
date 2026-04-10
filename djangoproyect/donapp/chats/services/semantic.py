import os
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue
from sentence_transformers import SentenceTransformer

QDRANT_HOST = os.getenv("QDRANT_HOST","localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT","6333"))
EMBED_MODEL = os.getenv("EMBED_MODEL","sentence-transformers/all-MiniLM-L6-v2")

_client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
_embedder = SentenceTransformer(EMBED_MODEL)

def _embed(text: str):
    v = _embedder.encode([text], normalize_embeddings=True)[0]
    return v.tolist()

def _to_filter(filters: dict | None):
    if not filters: return None
    must = [FieldCondition(key=k, match=MatchValue(value=v)) for k, v in filters.items()]
    return Filter(must=must)

def semantic_search_topk(query: str, top_k=5, collection="kb", filters=None):
    qv = _embed(query)
    qfilter = _to_filter(filters)
    res = _client.search(collection_name=collection, query_vector=qv, limit=top_k, query_filter=qfilter)
    out = []
    for r in res:
        pl = (r.payload or {})  # 👈 payload completo
        out.append({
            "score": float(r.score),
            "title": pl.get("title"),
            "text": pl.get("text") or pl.get("snippet") or "",
            "url": pl.get("url"),
            "payload": pl,  # 👈 lo pasamos hacia arriba
        })
    return out
