Para ejecutar main.py
necesita Prolog

se debe ejecutar en la terminal:
pip install fastapi uvicorn
pip install pyswip

Luego ejecutar en el directorio donde main.py está:
uvicorn main:app --reload --port 8001

puedes probar desde Swagger la API desde:
http://127.0.0.1:8001/docs




puedes probar su funcionamiento colocando:

{
    "record": [
      {"area": "Requisitos para donar", "correcta": true},
      {"area": "Tipos de sangre y compatibilidad", "correcta": false},
      {"area": "Proceso de donación", "correcta": true},
      {"area": "Frecuencia y cuidados", "correcta": true},
      {"area": "Mitos y realidades", "correcta": true}
    ],
    "statistics": {
      "Requisitos para donar": 5,
      "Tipos de sangre y compatibilidad": 5,
      "Proceso de donación": 5,
      "Frecuencia y cuidados": 5,
      "Mitos y realidades": 5
    },
    "n": 5
  }

en el request body con el content-type application/json

y debería retornar en el response body:

{
  "new_statistics": {
    "Requisitos para donar": 2,
    "Compatibilidad sanguínea": 2,
    "Proceso de donación": 4,
    "Frecuencia permitida": 2,
    "Mitos y verdades": 4
  },
  "questions_per_area": {
    "Requisitos para donar": 2,
    "Compatibilidad sanguínea": 2,
    "Proceso de donación": 0,
    "Frecuencia permitida": 1,
    "Mitos y verdades": 0
  }
}
