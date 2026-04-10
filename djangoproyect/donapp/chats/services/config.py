# services/config.py
from dataclasses import dataclass

@dataclass
class ChatConfig:
    name: str
    language: str
    endpoint_id: str          # RunPod endpoint
    qdrant_collection: str
    qdrant_filters: dict | None
    faq_tenant: str | None
    tau_direct: float = 0.85
    tau_rag: float = 0.55
