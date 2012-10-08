CREATE OR REPLACE FUNCTION f_extract_period_edge(p_period period_enum, p_date timestamp)
  RETURNS tp_period_edges AS
$BODY$DECLARE
    v_edges tp_period_edges;
BEGIN
    v_edges.period_name := p_period;
    -- atencao, os retornos sao para ser comparados com < e nao <= !!
    -- veja bem o primeiro exemplo eh mantido em todos!

    CASE p_period
    WHEN 'daily' THEN

        v_edges.period_begin := p_date::date;
        v_edges.period_end   := p_date::date + '1 day'::interval;
    WHEN 'weekly' THEN

        v_edges.period_begin := (extract('year' FROM p_date)::text || '-01-01' )::date +
                    (extract('week' FROM p_date)::text || ' weeks')::interval - '1 week'::interval;

        v_edges.period_end   := v_edges.period_begin + '7 days'::interval;
    WHEN 'monthly' THEN

        v_edges.period_begin := (extract('year' FROM p_date)::text || '-'|| extract('month' FROM p_date)::text ||'-01' )::date;

        v_edges.period_end   := v_edges.period_begin + '1 month'::interval;
    WHEN 'bimonthly' THEN
        -- aqui segue a mesma logica, meses bimestrais são: [01 02], [03 04], [05 06], ...
        v_edges.period_begin := (extract('year' FROM p_date)::text || '-' ||
                (CASE WHEN extract('month' FROM p_date)::int % 2 = 0 THEN
                    (extract('month' FROM p_date) - 1)::text
                ELSE
                    extract('month' FROM p_date)::text
                END)
            ||'-01' )::date;

        v_edges.period_end   := v_edges.period_begin + '2 month'::interval;
    WHEN 'quarterly' THEN
        -- meses trimestrais são: [01 02 03] [04 05 06] [07 08 09] [10 11 12]
        v_edges.period_begin := (extract('year' FROM p_date)::text || '-' ||
                (
                CASE extract('month' FROM p_date)::int % 3
                    WHEN 0 THEN extract('month' FROM p_date)::int - 2
                    WHEN 1 THEN extract('month' FROM p_date)::int
                    WHEN 2 THEN extract('month' FROM p_date)::int - 1
                ELSE NULL
                END )::text

            ||'-01' )::date;

        v_edges.period_end   := v_edges.period_begin + '3 month'::interval;

    WHEN 'semi-annual' THEN

        v_edges.period_begin := (extract('year' FROM p_date)::text || '-' ||
                CASE WHEN extract('month' FROM p_date)::int <= 6 THEN '1' ELSE '7' END
            ||'-01' )::date;
        v_edges.period_end   := v_edges.period_begin + '6 month'::interval;

    WHEN 'yearly' THEN
        v_edges.period_begin := (extract('year' FROM p_date)::text || '-01-01' )::date;
        v_edges.period_end   := v_edges.period_begin + '1 year'::interval;

    WHEN 'decade' THEN
        v_edges.period_begin := ((

                extract('DECADE' FROM p_date) * 10::int

            )::text || '-01-01' )::date;

        v_edges.period_end   := v_edges.period_begin + '10 years'::interval;
    ELSE
        RAISE EXCEPTION 'not supported period [%s]', p_period;
    END CASE;


    RETURN v_edges;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;


