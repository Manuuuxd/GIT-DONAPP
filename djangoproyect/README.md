# 🩸 DonApp - Sistema de Trivia para Donación de Sangre

Este es un proyecto Django que implementa una trivia educativa sobre la donación de sangre, incluyendo niveles, áreas temáticas y sesiones de usuario.

---

## 📦 Requisitos

Asegúrate de tener instalado:

- Python 3.10+ ✅
- `pip` (gestor de paquetes de Python)
- PostgreSQL (o SQLite si se configura así)
- Git

Además, se recomienda usar un entorno virtual:

```bash
python -m venv venv
source venv/bin/activate   # En Windows: .\venv\Scripts\Activate.ps1


# 📦 Instalar las dependecias:
pip install -r requirements.txt

En donapp/settings.py configurar postgresql

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'donapp_db',
        'USER': 'postgres',
        'PASSWORD': '123',
        'HOST': 'localhost',  # o la IP si es externa
        'PORT': '5432',
    }
}

Migrar los datos modelos a la BD:

python manage.py makemigrations
python manage.py migrate


Cargar las preguntas desde el archivo JSON:
python manage.py cargar_preguntas

# Qdrant
python manage.py ingest_faq chats/data/faqs_donacion_A.json
python manage.py ingest_faq chats/data/faqs_asistente_B.json

en la carpeta de Qdrant

docker compose up -d  / para bajar el contenedor - docker compose down

python manage.py ingest_qdrant_from_db --tenant all  

Para Celery:
pip install celery[redis]
docker run -d -p 6379:6379 redis
python -m celery -A donapp worker -l debug -P solo
python -m celery -A donapp beat -l info

LUEGO SE PUEDE ELIMINAR.

La estrucutura se deberia ver:
donapp/
│
├── trivia/
│   ├── models.py                      # Modelos principales
│   ├── views.py
│   └── management/
│       └── commands/
│           └── cargar_preguntas.py   # Script de carga de datos
│
├── A&Q_clasifieds.json               # Archivo con preguntas/respuestas
├── manage.py
├── requirements.txt
└── README.md
