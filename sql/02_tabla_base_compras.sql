-- TABLA BASE DE COMPRAS
-- 1 fila = 1 compra (identificada por event_timestamp, único en todo el dataset)
-- transaction_id lo conservo como dato descriptivo, no es confiable como clave única
-- purchase_revenue se deja con sus nulos (aprox 7.9%, todos con transaction_id='(not set)'):
--  cuentan para Frecuencia, se excluyen del cálculo de Monetario en la fase RFM

WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
)

SELECT
  user_pseudo_id,
  PARSE_DATE('%Y%m%d', event_date) AS purchase_date,
  event_timestamp,
  ecommerce.transaction_id AS transaction_id,
  ecommerce.purchase_revenue AS purchase_revenue
FROM purchases;