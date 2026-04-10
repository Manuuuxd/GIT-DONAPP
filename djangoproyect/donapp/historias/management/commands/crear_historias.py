# historias/management/commands/crear_historias.py

import random
from django.core.management.base import BaseCommand
from historias.models import Historia

class Command(BaseCommand):
    help = 'Crea un conjunto de historias inspiradoras de donantes para poblar la base de datos.'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS('--- Iniciando la creación de historias inspiradoras ---'))

        # Limpiamos las historias existentes para no crear duplicados
        Historia.objects.all().delete()
        self.stdout.write(self.style.WARNING('Historias anteriores eliminadas.'))

        historias = [
            {
                "titulo": "Una Gota de Esperanza para un Desconocido",
                "contenido": "Nunca pensé que algo tan simple como donar sangre pudiera tener un impacto tan grande. Un día recibí una carta de agradecimiento anónima de un hospital, diciendo que mi donación O+ había ayudado a salvar a un recién nacido en una cirugía de emergencia. Esa carta cambió mi perspectiva para siempre. Ahora, cada vez que dono, no solo doy sangre, doy una oportunidad de vida.",
                "tag_formulario": "O+"
            },
            {
                "titulo": "De Receptor a Donante: Mi Círculo de Vida",
                "contenido": "Hace cinco años, un accidente casi me cuesta la vida. Necesité múltiples transfusiones de sangre A- para sobrevivir. Esas bolsas de sangre, donadas por extraños generosos, fueron mi salvación. En cuanto me recuperé por completo, mi primera meta fue convertirme en donante. Ahora, cada tres meses, voy al centro de donación con la esperanza de devolver el favor y cerrar el círculo de ayuda que me salvó.",
                "tag_formulario": "A-"
            },
            {
                "titulo": "La Donación que Unió a mi Familia",
                "contenido": "Mi abuelo necesitaba una transfusión urgente de sangre B+, un tipo no tan común. Organizamos una campaña familiar y comunitaria. Fue increíble ver a primos, tíos y vecinos acudir a donar. Aunque no todas las donaciones eran para él, ese día se recolectaron unidades que ayudaron a muchas otras personas. La donación no solo salvó a mi abuelo, sino que nos unió a todos en un acto de solidaridad que jamás olvidaremos.",
                "tag_formulario": "B+"
            },
            {
                "titulo": "Mi Miedo a las Agujas vs. Salvar una Vida",
                "contenido": "Siempre quise donar, pero mi miedo a las agujas era paralizante. Un día, vi un llamado urgente en redes sociales para un niño con leucemia que necesitaba plaquetas. Su foto me conmovió tanto que decidí enfrentar mi miedo. La enfermera fue increíblemente paciente y me distrajo durante todo el proceso. Fue un pequeño pinchazo para mí, pero significó el mundo para ese niño y su familia. Mi miedo no ha desaparecido, pero ahora sé que mi valentía es más grande.",
                "tag_formulario": "general"
            },
            {
                "titulo": "El Donante Universal: Un Superpoder Silencioso",
                "contenido": "Cuando descubrí que mi tipo de sangre era O-, el 'donante universal', sentí que tenía una especie de superpoder. Saber que mi sangre puede ser utilizada en cualquier paciente en una situación crítica me da un sentido de responsabilidad y propósito. No necesito una capa para ser un héroe; solo necesito 15 minutos de mi tiempo cada ciertos meses para potencialmente salvar una vida. Es el acto más heroico que hago, y lo hago en silencio.",
                "tag_formulario": "O-"
            },
            {
                "titulo": "La Primera Vez de Muchas",
                "contenido": "Fui a donar por primera vez con mis amigos de la universidad. Estaba nervioso, pero el ambiente era de camaradería. Nos reímos, nos apoyamos y al final, todos salimos con una galleta en la mano y una sensación de orgullo inmensa. Esa primera experiencia me demostró que donar no es un acto solitario, sino un compromiso comunitario. Desde entonces, no he parado.",
                "tag_formulario": "general"
            }
        ]

        for historia_data in historias:
            Historia.objects.create(
                titulo=historia_data['titulo'],
                contenido=historia_data['contenido'],
                tag_formulario=historia_data['tag_formulario']
            )
            self.stdout.write(self.style.SUCCESS(f'Historia creada: "{historia_data["titulo"]}"'))

        self.stdout.write(self.style.SUCCESS('--- Proceso completado. La base de datos ha sido poblada con nuevas historias. ---'))

