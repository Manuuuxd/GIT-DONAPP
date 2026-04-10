# usuarios/utils.py

def otorgar_xp(perfil, dificultad, correcta, tiempo=None, extras=None):
    xp_ganado = 0

    reglas = {
        "Inicial": (10, 2),
        "Avanzado": (20, 5),
        "Experto": (30, 8),
    }

    correcta = bool(correcta)
    if dificultad not in reglas:
        raise ValueError("Dificultad no reconocida")

    xp_ganado += reglas[dificultad][0 if correcta else 1]

    if tiempo is not None and correcta:
        if tiempo < 5:
            xp_ganado += 5
        elif tiempo < 10:
            xp_ganado += 2

    if extras:
        if "racha" in extras:
            xp_ganado += 10
        if "primera_dificil" in extras:
            xp_ganado += 15
        if "categoria_completa" in extras:
            xp_ganado += 50

    perfil.xp += xp_ganado
    perfil.actualizar_nivel()

    return xp_ganado