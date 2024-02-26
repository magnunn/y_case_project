{% test data_freshness_test(model, column_name, days) %}

    {{ config(severity = 'warn', store_failures = true) }}

    with max_cte as (
        select max({{ column_name }}) as latest_update
        from {{ model }}
    ),
    check_cte as (
    select latest_update
    from max_cte
    where DATE_DIFF(CURRENT_DATE(),latest_update, DAY) > {{ days }}
    )
    select latest_update from check_cte
    where latest_update is not null

{% endtest %}