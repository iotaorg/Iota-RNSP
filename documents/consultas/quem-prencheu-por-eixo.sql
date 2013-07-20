/*select

name,
id as user_id

from "user"

where institute_id = 1
and city_id is not null
join
*/

    SELECT

       i.id,
i.axis_id,

       CASE WHEN i.indicator_type = 'varied' THEN
            COALESCE((SELECT MAX(c) FROM (
             SELECT a.valid_from, COUNT(DISTINCT a.variation_name) AS c
             FROM indicator_value a
             WHERE  a.indicator_id = i.id AND a.user_id = 115 AND region_id IS NULL
             GROUP BY 1
            ) x),0)
       ELSE
          COUNT(DISTINCT iv_any.variation_name)
       END AS _count_any,

       greatest(1, (SELECT COUNT(1) FROM indicator_variations x WHERE x.indicator_id = i.id AND user_id IN (115, i.user_id))) AS var_count,
       jm.COUNT AS justification_count

    FROM indicator i



    LEFT JOIN indicator_value iv_any ON iv_any.user_id = 115 AND iv_any.indicator_id = i.id AND iv_any.active_value AND iv_any.region_id IS NULL
    LEFT JOIN (SELECT indicator_id, COUNT(1) FROM user_indicator x WHERE x.user_id = 115 AND justification_of_missing_field != '' GROUP BY 1) jm ON i.id = jm.indicator_id
    GROUP BY i.id, i.axis_id, i.user_id,i.indicator_type,jm.COUNT



