# 🎮 Progresión de Niveles – Trivia DonApp

Este documento describe la lógica de avance entre niveles en el sistema de trivia educativa de DonApp.  
Los niveles están pensados como una curva de aprendizaje gradual para motivar, evaluar y reforzar el conocimiento sobre donación de sangre.

---

## 🧠 Estructura de niveles

El juego de trivia se divide en 3 niveles de dificultad:

1. **Inicial** – Fundamentos básicos sobre la donación de sangre.
2. **Avanzado** – Requisitos, normativas y conceptos más específicos.
3. **Experto** – Conocimientos más técnicos, reales y orientados a usuarios comprometidos o donantes frecuentes.

---

## 📈 Lógica de progresión

Cada vez que un jugador termina un bloque de preguntas en un nivel, su rendimiento define si **sube**, **se mantiene** o **baja** de nivel. Esta lógica se evalúa al finalizar el bloque del nivel actual.

| % de aciertos        | Resultado                         |
|----------------------|-----------------------------------|
| ≥ 80%                | 🔼 Sube al siguiente nivel        |
| ≥ 60% y < 80%        | ⏸ Se mantiene en el nivel actual |
| < 60%                | 🔽 Baja al nivel anterior         |

> ⚠️ Si el usuario ya está en el nivel Inicial y no supera el 60%, simplemente repite ese nivel.

---

## 🚦 Ejemplos prácticos

- 👤 Usuario termina el nivel **Inicial** con 85% → Avanza a **Avanzado**.
- 👤 Usuario termina el nivel **Avanzado** con 75% → Se mantiene en **Avanzado**.
- 👤 Usuario termina el nivel **Experto** con 58% → Retrocede a **Avanzado**.
- 👤 Usuario termina el nivel **Inicial** con 40% → Se mantiene en **Inicial**.

---

## 🔁 Reintento

- Los usuarios pueden **reintentar el mismo nivel** si no suben.
- Se recomienda que cada intento nuevo **muestre preguntas diferentes o en diferente orden** para mantener el interés.
- Se habilitan mensajes personalizados según el resultado (subida, mantención, retroceso).

---

## 📊 Implementación técnica
Hay que pasarle devuelta:  el area de la pregunta y si es true/false Aparte, nueva estadística.
Cada bloque de nivel debe tener entre 5 preguntas.  
El cálculo del rendimiento debe considerar:

```js
porcentaje_aciertos = respuestas_correctas / total_preguntas * 100
