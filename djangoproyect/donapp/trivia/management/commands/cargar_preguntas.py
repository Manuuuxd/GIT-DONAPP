import json
from django.core.management.base import BaseCommand
from trivia.models import Question, Answer

LABELS = ['A', 'B', 'C', 'D', 'E']

class Command(BaseCommand):
    help = 'Limpia la BD y carga preguntas desde JSON adaptando tipos booleanos'

    def handle(self, *args, **kwargs):
        self.stdout.write("🧹 Borrando preguntas y respuestas existentes...")
        Answer.objects.all().delete()
        Question.objects.all().delete()

        self.stdout.write("📥 Cargando preguntas desde JSON...")

        with open('A&Q_clasifieds.json', 'r', encoding='utf-8') as f:
            data = json.load(f)

        for idx, item in enumerate(data, start=1):
            pregunta = item.get("Pregunta")
            if not pregunta:
                self.stdout.write(self.style.WARNING(f"⚠️ Pregunta n°{idx} vacía o nula, se omite."))
                continue

            question = Question.objects.create(
                text=pregunta.strip(),
                explanation=(item.get("Explicación") or "").strip(),
                level=(item.get("Nivel") or "Inicial").strip(),
                area=(item.get("Area") or "General").strip()
            )

            correcta = (item.get("Correcta") or "").strip().upper()

            # Recorremos todas las alternativas hasta la que sea nula o no exista
            i = 1
            label_index = 0
            while True:
                alt_key = f"Alternativa {i}"
                if alt_key not in item:
                    break
                valor_alt = item.get(alt_key)
                if valor_alt is None:
                    # Si es None, saltar y terminar si no hay más alternativas
                    break

                # Convertir el valor a string (por ejemplo True -> "True")
                texto = str(valor_alt).strip()

                label = LABELS[label_index] if label_index < len(LABELS) else f"Z{label_index}"

                is_correct = (label == correcta)

                Answer.objects.create(
                    question=question,
                    label=label,
                    text=texto,
                    is_correct=is_correct
                )

                i += 1
                label_index += 1

        self.stdout.write(self.style.SUCCESS("✅ Base de datos reseteada y preguntas cargadas exitosamente."))
