% Hechos dinámicos
:- dynamic estadistica/2.
:- dynamic respuesta/2.

actualizar_estadistica(Area, true, Nueva) :-
    estadistica(Area, Actual), !,
    Temp is min(5, Actual + 1),
    retract(estadistica(Area, Actual)),
    asserta(estadistica(Area, Temp)),
    Nueva = Temp.

actualizar_estadistica(Area, false, Nueva) :-
    estadistica(Area, Actual), !,
    Temp is max(1, Actual - 1),
    retract(estadistica(Area, Actual)),
    asserta(estadistica(Area, Temp)),
    Nueva = Temp.

prioridad(Area, Preguntas) :-
    estadistica(Area, V),
    P is 6 - V,
    Preguntas is P.