WITH tabla_base AS (
  SELECT user_pseudo_id,
  PARSE_DATE('%Y%m%d', event_date) AS purchase_date,
  event_timestamp,
  ecommerce.transaction_id AS transaction_id,
  ecommerce.purchase_revenue AS purchase_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'),

rfm AS (
SELECT user_pseudo_id,
COUNT(*) AS frecuencia,
COUNT(purchase_revenue) AS frecuencia_limpia,
DATE_DIFF(DATE '2021-02-01', MAX(purchase_date), DAY) AS recencia,
SUM(purchase_revenue) AS monetario,
COUNTIF(purchase_revenue IS NULL) AS mnulo,
SUM(purchase_revenue)/NULLIF(COUNT(purchase_revenue),0) AS ticket_promedio
FROM tabla_base
GROUP BY user_pseudo_id),

rfm_scores AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recencia DESC) AS r_score,
    CASE WHEN frecuencia = 1 THEN 1 
    WHEN frecuencia = 2 THEN 3
    WHEN frecuencia >= 3 THEN 5
    END AS f_score,
    CASE
      WHEN monetario IS NULL THEN 1
      ELSE NTILE(5) OVER (PARTITION BY monetario IS NOT NULL ORDER BY monetario ASC)
    END AS m_score
  FROM rfm),

rfm_segmentado AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND m_score >= 4 THEN 'Campeones'
      WHEN f_score >= 4 THEN 'Clientes leales'
      WHEN r_score = 3 AND m_score >= 4 THEN 'Potencial alto valor'
      WHEN r_score = 3 THEN 'Clientes ocasionales'
      WHEN r_score <= 2 AND m_score >= 4 THEN 'Alto valor en riesgo'
      WHEN r_score >= 4 AND m_score <= 3 AND f_score = 1 THEN 'Nuevos / Prometedores'
      WHEN r_score <= 2 AND m_score <= 3 THEN 'En riesgo / Bajo valor'
      WHEN r_score = 1 AND m_score = 1 THEN 'Perdidos'
      ELSE 'Otros / A revisar'
    END AS segmento
  FROM rfm_scores
)


SELECT segmento, COUNT(*) AS n_usuarios
FROM rfm_segmentado
GROUP BY segmento
ORDER BY n_usuarios DESC;
