# chats/management/commands/ingest_faq.py
import json
from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q
from chats.models import FAQ, FAQRegex  # ajusta si tu app se llama distinto

DUP_POLICIES = ("skip", "reassign")  # para patterns duplicados globales

def _ensure_m2m_by_name(manager, names, *, field_candidates=("name", "value", "label")):
    """
    Crea o busca objetos por nombre y hace set en el M2M
    manager: faq.synonyms o faq.tags
    names: lista de strings
    """
    if not hasattr(manager, "model"):
        return
    Model = manager.model
    objs = []
    for s in names or []:
        s = (s or "").strip()
        if not s:
            continue
        created = None
        obj = None
        # intenta distintos campos comunes
        for fname in field_candidates:
            if hasattr(Model, fname):
                obj, created = Model.objects.get_or_create(**{fname: s})
                break
        if obj is None:
            # ultimo recurso si el modelo tiene unico campo char
            char_fields = [f.name for f in Model._meta.fields if f.get_internal_type() in ("CharField", "TextField")]
            if char_fields:
                obj, created = Model.objects.get_or_create(**{char_fields[0]: s})
        if obj:
            objs.append(obj)
    # reemplaza todo el set por los nuevos
    manager.set(objs, clear=True)

def _apply_action_fields(faq: FAQ, action_obj):
    """
    Soporta dos esquemas:
    - FAQ.action JSONField
    - FAQ.action_type + FAQ.action_target CharField
    """
    if not action_obj:
        return
    # JSONField directo
    if hasattr(faq, "action"):
        setattr(faq, "action", action_obj)
        return
    # par de campos simples
    a_type = action_obj.get("type")
    a_target = action_obj.get("target")
    if a_type and hasattr(faq, "action_type"):
        setattr(faq, "action_type", a_type)
    if a_target and hasattr(faq, "action_target"):
        setattr(faq, "action_target", a_target)

class Command(BaseCommand):
    help = "Ingiere FAQs desde un JSON con soporte M2M y patrones únicos"

    def add_arguments(self, parser):
        parser.add_argument("json_path", type=str)
        parser.add_argument("--duplicate-policy", choices=DUP_POLICIES, default="skip",
                            help="Qué hacer si un pattern ya existe globalmente en FAQRegex")

    @transaction.atomic
    def handle(self, *args, **opts):
        path = opts["json_path"]
        dup_policy = opts["duplicate_policy"]

        data = json.load(open(path, "r", encoding="utf-8"))

        stats = dict(faq_new=0, faq_upd=0, re_new=0, re_upd=0, re_skip=0, re_reassign=0)

        for item in data:
            tenant   = item.get("tenant")
            lang     = item.get("language", "es")
            question = item["question"]
            answer   = item.get("answer", "")
            tags_in  = item.get("tags", [])
            syns_in  = item.get("synonyms", [])
            regex_in = item.get("regex", [])
            action_in = item.get("action")

            # upsert FAQ base sin tocar M2M todavía
            faq, created = FAQ.objects.update_or_create(
                tenant=tenant,
                language=lang,
                question_canonical=question,
                defaults={
                    "answer_html": answer,
                    "is_active": True,
                },
            )
            # action flexible
            _apply_action_fields(faq, action_in)
            faq.save()

            stats["faq_new" if created else "faq_upd"] += 1

            # M2M synonyms
            try:
                rel = getattr(faq, "synonyms")
                if hasattr(rel, "set"):
                    _ensure_m2m_by_name(rel, syns_in)
            except Exception:
                # si synonyms no es M2M, intenta asignar lista si es JSONField o ArrayField
                try:
                    if hasattr(faq, "synonyms") and isinstance(syns_in, list):
                        setattr(faq, "synonyms", syns_in)
                        faq.save(update_fields=["synonyms"])
                except Exception:
                    pass

            # M2M tags
            try:
                rel = getattr(faq, "tags")
                if hasattr(rel, "set"):
                    _ensure_m2m_by_name(rel, tags_in, field_candidates=("name", "slug", "value", "label"))
            except Exception:
                try:
                    if hasattr(faq, "tags") and isinstance(tags_in, list):
                        setattr(faq, "tags", tags_in)
                        faq.save(update_fields=["tags"])
                except Exception:
                    pass

            # Regex con unicidad global en pattern
            for r in regex_in:
                pat = r.get("pattern")
                flg = r.get("flags", "i")
                if not pat:
                    continue

                obj = FAQRegex.objects.filter(pattern=pat).first()
                if obj is None:
                    FAQRegex.objects.create(faq=faq, pattern=pat, flags=flg)
                    stats["re_new"] += 1
                else:
                    if obj.faq_id == faq.id:
                        # mismo FAQ, actualiza flags si cambiaron
                        if getattr(obj, "flags", None) != flg:
                            obj.flags = flg
                            obj.save(update_fields=["flags"])
                            stats["re_upd"] += 1
                        else:
                            stats["re_skip"] += 1
                    else:
                        if dup_policy == "reassign":
                            obj.faq = faq
                            if getattr(obj, "flags", None) != flg:
                                obj.flags = flg
                            obj.save(update_fields=["faq", "flags"])
                            stats["re_reassign"] += 1
                        else:
                            stats["re_skip"] += 1
                            self.stdout.write(self.style.WARNING(
                                f"[skip] pattern ya existe y pertenece a FAQ {obj.faq_id}: {pat}"
                            ))

        self.stdout.write(self.style.SUCCESS(
            f"FAQs new={stats['faq_new']} upd={stats['faq_upd']}  "
            f"Regex new={stats['re_new']} upd={stats['re_upd']} reassign={stats['re_reassign']} skip={stats['re_skip']}"
        ))


class Command(BaseCommand):
    help = "Ingiere FAQs desde un JSON con soporte M2M, regex únicos y estrategia de unicidad configurable"

    def add_arguments(self, parser):
        parser.add_argument("json_path", type=str)
        parser.add_argument("--duplicate-policy", choices=DUP_POLICIES, default="skip",
                            help="Qué hacer si un pattern ya existe globalmente en FAQRegex")
        parser.add_argument("--namespace-by-tenant", action="store_true", default=False,
                            help="Prefija question_canonical con '<TENANT>::' para evitar choque de unicidad global")

    @transaction.atomic
    def handle(self, *args, **opts):
        path = opts["json_path"]
        dup_policy = opts["duplicate_policy"]
        ns_by_tenant = opts["namespace_by_tenant"]

        data = json.load(open(path, "r", encoding="utf-8"))

        stats = dict(faq_new=0, faq_upd=0, re_new=0, re_upd=0, re_skip=0, re_reassign=0)

        for item in data:
            tenant   = (item.get("tenant") or "").strip() or None
            lang     = item.get("language", "es")
            question_raw = item["question"].strip()

            # === estrategia de unicidad para question_canonical ===
            if ns_by_tenant and tenant:
                question = f"{tenant}::{question_raw}"
            else:
                question = question_raw

            answer   = item.get("answer", "")
            tags_in  = item.get("tags", [])
            syns_in  = item.get("synonyms", [])
            regex_in = item.get("regex", [])
            action_in = item.get("action")

            # lookup por question_canonical (único global)
            faq = FAQ.objects.filter(question_canonical=question).first()
            created = False
            if faq is None:
                faq = FAQ(
                    tenant=tenant,
                    language=lang,
                    question_canonical=question,
                    answer_html=answer,
                    is_active=True,
                )
                _apply_action_fields(faq, action_in)
                faq.save()
                created = True
            else:
                # actualizar campos base
                faq.tenant = tenant or faq.tenant
                faq.language = lang or faq.language
                faq.answer_html = answer
                _apply_action_fields(faq, action_in)
                faq.is_active = True
                faq.save()

            stats["faq_new" if created else "faq_upd"] += 1

            # ====== M2M synonyms ======
            try:
                rel = getattr(faq, "synonyms")
                if hasattr(rel, "set"):
                    _ensure_m2m_by_name(rel, syns_in)
            except Exception:
                try:
                    if hasattr(faq, "synonyms") and isinstance(syns_in, list):
                        setattr(faq, "synonyms", syns_in)
                        faq.save(update_fields=["synonyms"])
                except Exception:
                    pass

            # ====== M2M tags ======
            try:
                rel = getattr(faq, "tags")
                if hasattr(rel, "set"):
                    _ensure_m2m_by_name(rel, tags_in, field_candidates=("name", "slug", "value", "label"))
            except Exception:
                try:
                    if hasattr(faq, "tags") and isinstance(tags_in, list):
                        setattr(faq, "tags", tags_in)
                        faq.save(update_fields=["tags"])
                except Exception:
                    pass

            # ====== Regex (unicidad global en pattern) ======
            for r in regex_in:
                pat = r.get("pattern")
                flg = r.get("flags", "i")
                if not pat:
                    continue

                obj = FAQRegex.objects.filter(pattern=pat).first()
                if obj is None:
                    FAQRegex.objects.create(faq=faq, pattern=pat, flags=flg)
                    stats["re_new"] += 1
                else:
                    if obj.faq_id == faq.id:
                        if getattr(obj, "flags", None) != flg:
                            obj.flags = flg
                            obj.save(update_fields=["flags"])
                            stats["re_upd"] += 1
                        else:
                            stats["re_skip"] += 1
                    else:
                        if dup_policy == "reassign":
                            obj.faq = faq
                            if getattr(obj, "flags", None) != flg:
                                obj.flags = flg
                            obj.save(update_fields=["faq", "flags"])
                            stats["re_reassign"] += 1
                        else:
                            stats["re_skip"] += 1
                            self.stdout.write(self.style.WARNING(
                                f"[skip] pattern ya existe y pertenece a FAQ {obj.faq_id}: {pat}"
                            ))

        self.stdout.write(self.style.SUCCESS(
            f"FAQs new={stats['faq_new']} upd={stats['faq_upd']}  "
            f"Regex new={stats['re_new']} upd={stats['re_upd']} reassign={stats['re_reassign']} skip={stats['re_skip']}"
        ))