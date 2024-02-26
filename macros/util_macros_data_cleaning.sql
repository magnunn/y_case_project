{% macro replace_and_safe_cast(column_name, current_substring, new_substring, new_data_type) %}
    SAFE_CAST(REPLACE({{ column_name }}, '{{ current_substring }}', '{{ new_substring }}') AS {{ new_data_type }})
{% endmacro %}
