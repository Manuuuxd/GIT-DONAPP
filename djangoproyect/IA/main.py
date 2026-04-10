from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict
from pyswip import Prolog

# Inicializa Prolog
prolog = Prolog()
prolog.consult("reglas.pl")

app = FastAPI()

class Respuesta(BaseModel):
    area: str
    correcta: bool

class Entrada(BaseModel):
    record: List[Respuesta]
    statistics: Dict[str, int]
    n: int

class Salida(BaseModel):
    nuevas_estadisticas: Dict[str, int]
    preguntas_por_area: Dict[str, int]

@app.post("/ia", response_model=Salida)
def razonamiento(data: Entrada):
    prolog.retractall("estadistica(_,_)")

    # Cargar estadísticas iniciales en Prolog
    for area, valor in data.statistics.items():
        area_prolog = area.replace(" ", "_")
        prolog.assertz(f"estadistica('{area_prolog}', {valor})")

    nuevas = {}
    for r in data.record:
        area_prolog = r.area.replace(" ", "_")
        query = f"actualizar_estadistica('{area_prolog}', {str(r.correcta).lower()}, Nueva)"
        for sol in prolog.query(query):
            nuevas[r.area] = sol["Nueva"]

    prioridades = {}
    for area in data.statistics.keys():
        area_prolog = area.replace(" ", "_")
        for sol in prolog.query(f"prioridad('{area_prolog}', P)"):
            prioridades[area] = sol["P"]

    total_peso = sum(prioridades.values())
    preguntas_por_area = {}

    # Distribución inicial
    for area, peso in prioridades.items():
        preguntas_por_area[area] = int((peso / total_peso) * data.n)

    # Ajuste fino
    diferencia = data.n - sum(preguntas_por_area.values())
    sorted_areas = sorted(prioridades.items(), key=lambda x: -x[1])
    i = 0
    while diferencia != 0:
        area = sorted_areas[i % len(sorted_areas)][0]
        if diferencia > 0:
            preguntas_por_area[area] += 1
            diferencia -= 1
        elif diferencia < 0 and preguntas_por_area[area] > 0:
            preguntas_por_area[area] -= 1
            diferencia += 1
        i += 1

    return {
        "nuevas_estadisticas": nuevas,
        "preguntas_por_area": preguntas_por_area
    }