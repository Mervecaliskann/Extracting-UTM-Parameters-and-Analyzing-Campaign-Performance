
   WITH combined_data AS (
    SELECT
        ad_date,
        COALESCE(fa.spend, 0) AS spend,
        COALESCE(fa.impressions, 0) AS impressions,
        COALESCE(fa.reach, 0) AS reach,
        COALESCE(fa.clicks, 0) AS clicks,
        COALESCE(fa.leads, 0) AS leads,
        COALESCE(fa.value, 0) AS value,
        fa.url_parameters,
        fc.campaign_name AS campaign_name,
        fas.adset_name AS adset_name
    FROM
        facebook_ads_basic_daily fa
    LEFT JOIN
        facebook_adset fas ON fa.adset_id = fas.adset_id
    LEFT JOIN
        facebook_campaign fc ON fa.campaign_id = fc.campaign_id
    UNION ALL
    SELECT
        ad_date,
        COALESCE(ga.spend, 0) AS spend,
        COALESCE(ga.impressions, 0) AS impressions,
        COALESCE(ga.reach, 0) AS reach,
        COALESCE(ga.clicks, 0) AS clicks,
        COALESCE(ga.leads, 0) AS leads,
        COALESCE(ga.value, 0) AS value,
        ga.url_parameters,
        ga.campaign_name AS campaign_name,
        ga.adset_name AS adset_name
    FROM
        google_ads_basic_daily ga
),
utm_data AS (
    SELECT
        ad_date,
        spend,
        impressions,
        clicks,
        value,
        campaign_name,
        adset_name,
        LOWER(
            COALESCE(
                substring(url_parameters FROM 'utm_campaign=([^&]+)'),
                'nan'
            )
        ) AS utm_campaign
    FROM
        combined_data
)

SELECT
    ad_date,
    CASE 
        WHEN utm_campaign = 'nan' THEN NULL
        ELSE utm_campaign
    END AS utm_campaign,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(value) AS total_value,
    CASE 
        WHEN SUM(impressions) = 0 THEN 0 
        ELSE SUM(clicks)::numeric / SUM(impressions) * 100
    END AS ctr,
    CASE 
        WHEN SUM(clicks) = 0 THEN 0 
        ELSE SUM(spend)::numeric / SUM(clicks)
    END AS cpc,
    CASE 
        WHEN SUM(impressions) = 0 THEN 0 
        ELSE SUM(spend)::numeric / SUM(impressions) * 1000
    END AS cpm,
    CASE 
        WHEN SUM(spend) = 0 THEN 0 
        ELSE SUM(value)::numeric / SUM(spend)
    END AS romi
FROM
    utm_data
GROUP BY
    ad_date, utm_campaign;
    
  
   