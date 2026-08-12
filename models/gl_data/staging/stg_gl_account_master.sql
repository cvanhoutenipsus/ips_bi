{{ config(materialized='view') }}

select
    "Account Code"     as account_code,
    "Account Name"     as account_name,
    "Account Type"     as account_type,
    "Report Group"     as report_group,
    "Report Subgroup"  as report_subgroup,
    "EBITDA Flag"      as ebitda_flag,
    "Cost Category"    as cost_category,
    "Cash Flow"        as cash_flow,
    "Report Group Sort" as report_group_sort,
    "Subgroup Sort"    as subgroup_sort,
    "BS Group"         as bs_group,
    "Account Group"    as account_group,



from {{ source('planful', 'ips_gl_account_master') }}