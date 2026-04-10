# ⚙️ Condiciones de la Trivia – DonApp 

Este documento define las **reglas del juego**, enfocadas en **gamificación educativa** y principios de **microlearning**. Las condiciones aplican para el banco completo de 150 preguntas.

---

## 🎮 Reglas Generales

- 📊 Total de preguntas: **150**
- 📚 Cada pregunta incluye: enunciado, 3 alternativas, 1 correcta y 1 explicación técnica o motivacional.
- 🔄 Orden: aleatorio cada vez que se inicia una partida. (ver esta condicion en relación al nivel y donde se quedó la última vez que se abrió el juego)
- ⏳ Tiempo por pregunta: configurable según testing (ej. 30 segundos por pregunta).
- 🚫 Sin retroceso: no se puede volver a una pregunta anterior.

---

## 🧠 Microlearning

Cada pregunta actúa como una **microlección**. Por eso, independientemente de si se acierta o no, se entrega una **retroalimentación breve**:

- ✅ **Respuesta correcta:** se muestra una frase de refuerzo positivo + explicación clara de la respuesta.
- ❌ **Respuesta incorrecta:** se muestra una frase motivacional y educativa + explicación correcta.

> Ejemplo:
> - ❌ "¡Casi! No es lo que esperábamos, pero ahora sabes que la edad mínima para donar en Chile es 18 años. ¡Sigue aprendiendo!"

---

## 🏆 Gamificación

Se incorporan mecánicas motivacionales en base al rendimiento del jugador:

### 1. Recompensas por buenas respuestas consecutivas se encontrará en un JSON

| Racha | Efecto Motivacional |
|-------|---------------------|
| 3 aciertos | 🎉 "¡Tres en línea! ¡Eres un donante experto en formación!" |
| 5 aciertos | 🏅 Desbloqueo de mini-logro visual |
| 10 aciertos | 🦸 "¡Wow! Estás salvando vidas con tu conocimiento" |

> 💡 *Personalizar los refuerzos o convertirlos en medallas digitales, insignias o estrellas.*

---

### 2. Respuestas incorrectas consecutivas

| Racha negativa | Mensaje de apoyo |
|----------------|------------------|
| 1 fallo        | "No te preocupes, ¡así se aprende! Vamos con la siguiente." |
| 2 fallos       | "A veces cuesta al principio. Respira, y sigue intentándolo 💪" |
| 3 fallos       | "Recuerda que cada error es una oportunidad de aprender. ¡Tú puedes!" |
| 4+ fallos      | "¿Te gustaría una pista? También puedes revisar la sección educativa." |

---

## 📈 Progresión del Usuario

- Se pueden **desbloquear niveles** (inicial, avanzado, experto) si se acierta un % mínimo (ej: 70%) en el nivel anterior.
- El progreso puede visualizarse con una barra o porcentaje, esto aumenta gamificación.
- Se recomienda guardar el puntaje en local o backend para seguimiento de usuario.

---

## 💡 Recomendaciones UX

- Usar emojis, colores e íconos para los mensajes de retroalimentación.
- Las explicaciones deben ser breves (máx. 2 frases),, revisar y corregir las entregadas.
- Permitir compartir logros en redes sociales, ver este tema.
- Posibilidad de “reintentar” solo las preguntas falladas al final, complementar aanalizando duolingo.

