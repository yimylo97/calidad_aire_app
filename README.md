# Calculadora de Calidad del Aire

Aplicación móvil desarrollada en Flutter para consultar la calidad del aire usando la API pública de Open-Meteo Air Quality.

## Funcionalidades

- Selección de ciudad de Colombia.
- Selección de fecha de consulta.
- Ingreso de horas de exposición diaria.
- Consulta asíncrona a la API de Open-Meteo.
- Obtención del promedio diario de PM2.5.
- Cálculo del índice de exposición.
- Clasificación del nivel de riesgo: Bajo, Moderado o Alto.

## Fórmula utilizada

```text
índice_exposición = promedio_PM2_5 × horas_exposición

| Valor del índice | Nivel de riesgo |
| ---------------- | --------------- |
| < 100            | Bajo            |
| 100 - 200        | Moderado        |
| > 200            | Alto            |


Tecnologías utilizadas
Flutter
Dart
API REST
Open-Meteo Air Quality API
Paquete http
Autor

Yimy
