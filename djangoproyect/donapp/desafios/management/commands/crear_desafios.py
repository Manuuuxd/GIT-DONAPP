import random
from datetime import date, timedelta
from django.core.management.base import BaseCommand
from desafios.models import DesafioSemanal

# Lista de desafíos predefinidos que podemos crear
# Utiliza los nuevos tipos que agregaste al modelo.
LISTA_DESAFIOS = [
    {
        "nombre": "Sabiduría de Sangre",
        "descripcion": "¿Sabes cuál es el tipo de sangre más raro? ¡Demuéstralo en nuestra trivia semanal!",
        "tipo": "trivia",
    },
    {
        "nombre": "Héroe Anónimo",
        "descripcion": "Comparte una historia sobre la importancia de donar sangre en tus redes sociales usando el hashtag #DonappSalvaVidas.",
        "tipo": "compartir",
    },
    {
        "nombre": "Explorador de Campañas",
        "descripcion": "Revisa los detalles de al menos una campaña de donación activa en el mapa para estar al tanto.",
        "tipo": "ver_campana",
    },
    {
        "nombre": "Maestro de la Compatibilidad",
        "descripcion": "Supera tu récord en el minijuego de compatibilidad sanguínea. ¿Podrás lograr una puntuación perfecta?",
        "tipo": "jugar",
    },
    {
        "nombre": "Mito o Realidad",
        "descripcion": "Investiga y descubre si es cierto que no puedes donar sangre si tienes tatuajes. ¡La respuesta te sorprenderá!",
        "tipo": "trivia",
    },
    {
        "nombre": "Compromiso de Héroe",
        "descripcion": "Agenda una nueva cita para donar sangre en la próxima campaña disponible. ¡Tu ayuda es crucial!",
        "tipo": "asistencia",
    },
    {
        "nombre": "Visita Diaria",
        "descripcion": "¡Gracias por tu constancia! Simplemente abrir la app es el primer paso para salvar vidas.",
        "tipo": "abrir_app",
    },
]

class Command(BaseCommand):
    help = 'Crea una serie de desafíos semanales aleatorios para pruebas.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('--- Iniciando la creación de desafíos de prueba ---'))

        # Opcional: Eliminar desafíos antiguos para no crear duplicados cada vez que se ejecuta
        DesafioSemanal.objects.all().delete()
        self.stdout.write(self.style.WARNING('Se eliminaron los desafíos semanales existentes.'))

        # Crear 5 desafíos para las próximas 5 semanas
        today = date.today()
        for i in range(5):
            # Seleccionar un desafío aleatorio de nuestra lista
            desafio_data = random.choice(LISTA_DESAFIOS)

            # Calcular las fechas de inicio y fin para cada semana
            fecha_inicio = today + timedelta(weeks=i)
            fecha_fin = fecha_inicio + timedelta(days=6)

            # Crear el objeto en la base de datos
            desafio, created = DesafioSemanal.objects.get_or_create(
                nombre=desafio_data["nombre"],
                defaults={
                    "descripcion": desafio_data["descripcion"],
                    "tipo": desafio_data["tipo"],
                    "fecha_inicio": fecha_inicio,
                    "fecha_fin": fecha_fin,
                }
            )

            if created:
                self.stdout.write(self.style.SUCCESS(f'Creado desafío: "{desafio.nombre}" para la semana del {fecha_inicio}'))
            else:
                self.stdout.write(self.style.NOTICE(f'El desafío "{desafio.nombre}" ya existía, no se creó.'))
        
        self.stdout.write(self.style.SUCCESS('--- Proceso finalizado exitosamente ---'))

