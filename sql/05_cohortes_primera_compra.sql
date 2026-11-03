WITH tabla_base AS (
  SELECT user_pseudo_id,
  PARSE_DATE('%Y%m%d', event_date) AS purchase_date,
  event_timestamp,
  ecommerce.transaction_id AS transaction_id,
  ecommerce.purchase_revenue AS purchase_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'),

cohorte_usuario AS (
SELECT user_pseudo_id,
DATE_TRUNC(MIN(purchase_date), MONTH) AS mes_cohorte 
FROM tabla_base
GROUP BY user_pseudo_id),

compras_mes_relativo AS (
  SELECT tabla_base.user_pseudo_id,
  tabla_base.purchase_date,
  cohorte_usuario.mes_cohorte,
  DATE_DIFF(DATE_TRUNC(tabla_base.purchase_date,MONTH),cohorte_usuario.mes_cohorte,MONTH) AS meses_transcurridos
  FROM tabla_base
  INNER JOIN cohorte_usuario
  USING (user_pseudo_id)
),

/*
SELECT *
FROM compras_mes_relativo
WHERE user_pseudo_id = '5817047.8350669320';
*/

--ARMANDO RETENCION
retencion_absoluta AS (SELECT 
mes_cohorte,
meses_transcurridos,
COUNT(DISTINCT user_pseudo_id) AS cantidad
FROM compras_mes_relativo
GROUP BY meses_transcurridos, mes_cohorte
ORDER BY mes_cohorte,meses_transcurridos),

tamano_cohorte AS (
  SELECT mes_cohorte,
  COUNT(DISTINCT user_pseudo_id) AS total_usuarios
  FROM cohorte_usuario
  GROUP BY mes_cohorte
)

SELECT retencion_absoluta.mes_cohorte,
retencion_absoluta.meses_transcurridos,
retencion_absoluta.cantidad,
tamano_cohorte.total_usuarios,
ROUND(retencion_absoluta.cantidad/tamano_cohorte.total_usuarios*100.0,1) AS pct_retencion
FROM retencion_absoluta
INNER JOIN tamano_cohorte
USING (mes_cohorte)
ORDER BY mes_cohorte,meses_transcurridos;
