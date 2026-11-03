WITH tabla_base_visitas AS (
  SELECT user_pseudo_id,
  PARSE_DATE('%Y%m%d', event_date) AS session_date,
  event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'session_start'),


--Se confirma que event_timestamp es unico
/*
SELECT event_timestamp, COUNT(*) AS conteo
FROM tabla_base_visitas
GROUP BY event_timestamp
HAVING COUNT(*) > 1
*/

cohorte_usuario_visitas AS (
  SELECT user_pseudo_id,
  DATE_TRUNC(MIN(session_date), MONTH) AS mes_cohorte
  FROM tabla_base_visitas
  GROUP BY user_pseudo_id),

visitas_mes_relativo AS (
  SELECT tabla_base_visitas.user_pseudo_id,
  tabla_base_visitas.session_date,
  cohorte_usuario_visitas.mes_cohorte,
  DATE_DIFF(DATE_TRUNC(tabla_base_visitas.session_date, MONTH), cohorte_usuario_visitas.mes_cohorte, MONTH) AS meses_transcurridos
  FROM tabla_base_visitas
  INNER JOIN cohorte_usuario_visitas
  USING (user_pseudo_id)),

retencion_absoluta_visitas AS (
  SELECT mes_cohorte,
  meses_transcurridos,
  COUNT(DISTINCT user_pseudo_id) AS cantidad
  FROM visitas_mes_relativo
  GROUP BY meses_transcurridos, mes_cohorte),

tamano_cohorte_visitas AS (
  SELECT mes_cohorte,
  COUNT(DISTINCT user_pseudo_id) AS total_usuarios
  FROM cohorte_usuario_visitas
  GROUP BY mes_cohorte)

SELECT retencion_absoluta_visitas.mes_cohorte,
retencion_absoluta_visitas.meses_transcurridos,
retencion_absoluta_visitas.cantidad,
tamano_cohorte_visitas.total_usuarios,
ROUND(retencion_absoluta_visitas.cantidad / tamano_cohorte_visitas.total_usuarios * 100.0, 1) AS pct_retencion
FROM retencion_absoluta_visitas
INNER JOIN tamano_cohorte_visitas
USING (mes_cohorte)
ORDER BY mes_cohorte, meses_transcurridos;