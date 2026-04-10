# chats/management/commands/clear_faq.py
from django.core.management.base import BaseCommand
from django.db import transaction
from chats.models import FAQ, FAQRegex

class Command(BaseCommand):
    help = "Elimina todos los registros de FAQ y FAQRegex (con confirmación)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--force",
            action="store_true",
            help="Borra sin pedir confirmación (modo no interactivo)."
        )

    @transaction.atomic
    def handle(self, *args, **options):
        force = options["force"]

        if not force:
            self.stdout.write(self.style.WARNING(
                "⚠️  Esto eliminará *todos* los registros de FAQ y FAQRegex."
            ))
            confirm = input("¿Deseas continuar? (escribe 'SI' para confirmar): ")
            if confirm.strip().upper() != "SI":
                self.stdout.write(self.style.NOTICE("Operación cancelada."))
                return

        faq_count = FAQ.objects.count()
        regex_count = FAQRegex.objects.count()

        # Si hay relaciones M2M, Django las maneja automáticamente al borrar
        FAQRegex.objects.all().delete()
        FAQ.objects.all().delete()

        self.stdout.write(self.style.SUCCESS(
            f"✅ Eliminados {faq_count} FAQs y {regex_count} Regex."
        ))