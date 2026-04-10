import os, uuid, hashlib
from django.core.management.base import BaseCommand
from django.db.models import Q, QuerySet
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, Distance, VectorParams
from sentence_transformers import SentenceTransformer
from django.utils.html import strip_tags
from uuid import uuid4

from ...models import FAQ  # tu modelo

QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", "6333"))
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY") or None

EMBED_MODEL = os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
EMBED_DIM = int(os.getenv("EMBED_DIM", "384"))  # all-MiniLM-L6-v2 = 384

# colecciones (por tenant)
COLL_A = os.getenv("COLL_A", "kb_a")
COLL_B = os.getenv("COLL_B", "kb_b")
COLL_GLOBAL = os.getenv("COLL_GLOBAL", "kb_global")  # opcional

BATCH = 128


def ensure_collection(client: QdrantClient, name: str, dim: int, distance=Distance.COSINE):
    """
    Crea la colección si no existe (sin borrar datos).
    """
    if not name:
        return
    try:
        colls = client.get_collections().collections
        exists = any(c.name == name for c in colls)
        if not exists:
            client.create_collection(
                collection_name=name,
                vectors_config=VectorParams(size=dim, distance=distance),
            )
    except Exception as e:
        # si ya existe o no tenemos permisos, seguimos
        print(f"[warn] ensure_collection({name}): {e}")


def text_for_embedding(faq: FAQ) -> str:
    """
    Une pregunta + respuesta (limpia HTML básico).
    Este texto es el que buscamos semánticamente.
    """
    q = (faq.question_canonical or "").strip()
    a = strip_tags(faq.answer_html or "").strip()
    return f"{q}\n\n{a}".strip()


class Command(BaseCommand):
    help = "Ingiere FAQs desde la BD a Qdrant por tenant (A/B/global/all)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--tenant",
            choices=["A", "B", "global", "all"],
            default="all",
            help="Filtra por tenant a ingerir (A, B, global, all)",
        )
        parser.add_argument(
            "--only-active",
            action="store_true",
            default=True,
            help="Solo FAQs activas (is_active=True)",
        )

    def handle(self, *args, **opts):
        tenant_opt: str = opts["tenant"]
        only_active: bool = opts["only_active"]

        client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT, api_key=QDRANT_API_KEY)
        embedder = SentenceTransformer(EMBED_MODEL)

        # asegurar colecciones
        for coll in filter(None, [COLL_A, COLL_B, COLL_GLOBAL]):
            ensure_collection(client, coll, EMBED_DIM)

        # queryset
        qs: QuerySet[FAQ] = FAQ.objects.all()
        if only_active:
            qs = qs.filter(is_active=True)

        if tenant_opt != "all":
            if tenant_opt == "global":
                qs = qs.filter(Q(tenant__isnull=True) | Q(tenant=""))
            else:
                qs = qs.filter(tenant=tenant_opt)

        total = qs.count()
        self.stdout.write(self.style.NOTICE(f"FAQs a ingerir: {total} (tenant={tenant_opt})"))

        batch_points_a, batch_points_b, batch_points_g = [], [], []
        processed = 0

        def flush(coll_name: str, points: list[PointStruct]):
            if not points or not coll_name:
                return
            client.upsert(collection_name=coll_name, points=points)
            points.clear()

        for faq in qs.iterator(chunk_size=500):
            txt = text_for_embedding(faq)
            if not txt:
                continue

            vec = embedder.encode([txt], normalize_embeddings=True)[0].tolist()

            # 👇 payload por CADA faq (dentro del loop, no arriba)
            payload = {
                "title": faq.question_canonical,
                "text": txt,  # lo que devolveremos en semantic_direct
                "url": f"/faq/{faq.id}",
                "lang": faq.language,
                "tenant": faq.tenant or None,
                "tags": faq.tags or [],
                "type": "faq",
                "action": faq.action or None,  # 👈 importante para redirigir desde Qdrant
            }

            # usa UUID como id válido para Qdrant
            pid = str(uuid4())  # <-- ya como string
            p = PointStruct(id=pid, vector=vec, payload=payload)

            # decide colección destino
            t = (faq.tenant or "").upper()
            if t == "A":
                batch_points_a.append(p)
            elif t == "B":
                batch_points_b.append(p)
            else:
                if COLL_GLOBAL:
                    batch_points_g.append(p)
                else:
                    batch_points_a.append(p)
                    batch_points_b.append(p)

            # flush por lotes
            if len(batch_points_a) >= BATCH:
                flush(COLL_A, batch_points_a)
            if len(batch_points_b) >= BATCH:
                flush(COLL_B, batch_points_b)
            if COLL_GLOBAL and len(batch_points_g) >= BATCH:
                flush(COLL_GLOBAL, batch_points_g)

            processed += 1
            if processed % 200 == 0:
                self.stdout.write(f"Progreso: {processed}/{total}")

        # flush final
        flush(COLL_A, batch_points_a)
        flush(COLL_B, batch_points_b)
        if COLL_GLOBAL:
            flush(COLL_GLOBAL, batch_points_g)

        self.stdout.write(self.style.SUCCESS(f"Ingesta completada. Total procesadas: {processed}"))
