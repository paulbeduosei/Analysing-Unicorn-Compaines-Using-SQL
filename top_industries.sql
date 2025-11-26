WITH top_industries AS (
  SELECT
    i.industry,
    COUNT(*) AS total_unicorns
  FROM dates d
  JOIN industries i ON d.company_id = i.company_id
  WHERE EXTRACT(YEAR FROM d.date_joined) BETWEEN 2019 AND 2021
  GROUP BY i.industry
  ORDER BY total_unicorns DESC
  LIMIT 3
),
industry_year_stats AS (
  SELECT
    i.industry,
    EXTRACT(YEAR FROM d.date_joined) AS year,
    COUNT(*) AS num_unicorns,
    ROUND(AVG(f.valuation::numeric) / 1000000000.0, 2) AS average_valuation_billions
  FROM dates d
  JOIN industries i ON d.company_id = i.company_id
  JOIN funding f ON d.company_id = f.company_id
  WHERE EXTRACT(YEAR FROM d.date_joined) BETWEEN 2019 AND 2021
    AND i.industry IN (SELECT industry FROM top_industries)
    AND f.valuation IS NOT NULL
  GROUP BY i.industry, EXTRACT(YEAR FROM d.date_joined)
),
expanded_years AS (
  -- produce rows for each top industry for each year 2019-2021
  SELECT industry, year
  FROM top_industries
  CROSS JOIN (VALUES (2019), (2020), (2021)) AS y(year)
),
final_stats AS (
  SELECT
    e.industry,
    e.year,
    COALESCE(iys.num_unicorns, 0) AS num_unicorns,
    COALESCE(iys.average_valuation_billions, 0.00) AS average_valuation_billions
  FROM expanded_years e
  LEFT JOIN industry_year_stats iys
    ON e.industry = iys.industry AND e.year = iys.year
)
SELECT
  industry,
  year,
  num_unicorns,
  average_valuation_billions
FROM final_stats
ORDER BY industry, year DESC;