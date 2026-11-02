# Diccionario de Variables y Documentación del Proyecto

## Insumos Crudos (data/)
- **Datos_terremotos.tsv (NOAA)**: Catálogo geofísico con año, coordenadas, profundidad focal (km), magnitud (Richter), indicador de tsunami y reporte de daños monetarios corrientes.
- **Datos_pib.csv (Banco Mundial)**: Producto Interno Bruto nominal anual en USD por país.
- **Datos_ipc.csv (Banco Mundial)**: Índice de Precios al Consumidor histórico para Estados Unidos (serie de inflación).

## Variables Consolidadas (datos_consolidados.rds)
- `anio`: Año en que ocurrió el sismo.
- `pais`: Nombre del país en formato estandarizado.
- `codigo_pais`: Código internacional ISO-3 (ISO 3166-1 alfa-3).
- `latitud` y `longitud`: Coordenadas geográficas del epicentro.
- `profundidad_km`: Profundidad focal del sismo en kilómetros.
- `magnitud`: Magnitud del sismo en escala Richter.
- `si_tsunami`: Indicador binario (1 si provocó tsunami, 0 si no).
- `pib_mill_usd`: PIB anual del país del evento en millones de dólares corrientes.
- `porc_dano_pib`: Daño económico normalizado como porcentaje del PIB ((Daño / PIB) * 100).
- `dano_mill_usd_vp`: Daño económico expresado en millones de dólares a valor presente (deflactado por IPC).
