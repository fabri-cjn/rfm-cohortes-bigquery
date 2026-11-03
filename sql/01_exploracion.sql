-- EXPLORACIÓN Y VALIDACIÓN
-- dataset: ga4_obfuscated_sample_ecommerce

-- event_date = "purchase", evento que marca como compra completada
SELECT DISTINCT event_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
LIMIT 20;

-- contando cuantas compras hay en esta muestra = 87 (fecha: 2020-12-05 YMD)
SELECT COUNT(event_name)
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
WHERE event_name = 'purchase';

-- Verificando que valor tiene transaction_id cuando el valor no es numerico ni nulo = '(not set)''
SELECT ecommerce.transaction_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
WHERE event_name = 'purchase'
  AND NOT REGEXP_CONTAINS(ecommerce.transaction_id, r'^[1-9][0-9]*$')
LIMIT 20;

WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

-- transaction_id NO es unico. Caso real: mismo user_pseudo_id, 2 compras
-- distintas (distinto event_timestamp y purchase_revenue) con el mismo transaction_id
SELECT ecommerce.transaction_id, COUNT(*) AS n_filas
FROM purchases
GROUP BY ecommerce.transaction_id
HAVING COUNT(*) > 1;

-- event_timestamp es único en todo el dataset (sirve como grano)
WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

SELECT event_timestamp, COUNT(*) AS conteo
FROM purchases
GROUP BY event_timestamp
HAVING COUNT(*) > 1;

-- Rango de revenue (min 1, max 1530) sin 0
WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

SELECT MAX(ecommerce.purchase_revenue) AS maximo,
       MIN(ecommerce.purchase_revenue) AS minimo
FROM purchases;

-- % de nulos y negativos en purchase_revenue (7.9% nulos, 0% negativos)
WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

SELECT
  ((SELECT COUNT(*) FROM purchases WHERE ecommerce.purchase_revenue IS NULL) / COUNT(*)) * 100 AS pct_nulos,
  ((SELECT COUNT(*) FROM purchases WHERE ecommerce.purchase_revenue < 0) / COUNT(*)) * 100 AS pct_no_validos
FROM purchases;

-- Los nulos de purchase_revenue coinciden con transaction_id = '(not set)'', 1 a 1 (450 = 450)
WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

SELECT COUNT(*)
FROM purchases
WHERE ecommerce.transaction_id = '(not set)' AND ecommerce.purchase_revenue IS NULL;

-- 82.5% de clientes que compran lo hacen solo 1 vez, el 17.5% vuelve a comprar
WITH purchases AS (
  SELECT *
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase')

SELECT COUNT(*) AS n_usuarios, conteo
FROM
  (SELECT user_pseudo_id, COUNT(event_timestamp) AS conteo
  FROM purchases
  GROUP BY user_pseudo_id)
GROUP BY conteo
ORDER BY conteo ASC;