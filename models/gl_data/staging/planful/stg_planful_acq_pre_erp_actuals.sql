{{ config(materialized='view') }}

with source_data as (

    select
        'Actual'          as source_type,
        Scenario          as scenario,
        FiscalYear        as fiscal_year,
        FiscalMonth       as fiscal_month,
        MonthName         as month_name,
        Reporting         as reporting_type,
        Segment1          as account_code,
        Segment2          as gl_code,
        Segment3          as intercompany,
        Segment4          as ips_dept,
        Segment5          as future_1,
        MtdAmount         as mtd_amount,
        _flight_loaded_at as loaded_at

    from {{ source('planful', 'planful_actual_scenario') }}

),

enriched as (

    select
        *,
        last_day(try_strptime(month_name, '%b-%y')::date) as gl_date,

        case
            when reporting_type in ('G/L Data (LC)','Reclass (LC)', 'Adjustments (LC)')
                 and gl_code in ('9997', '0401', '9996', '9995')
                then 'GBP'
            when reporting_type in ('G/L Data (LC)','Reclass (LC)', 'Adjustments (LC)')
                then 'CAD'
            else 'USD'
        end as currency

    from source_data

),

cutover as (

    select
        segment2_code,
        erp_cutover_date::date as erp_cutover_date
    from {{ ref('planful_acq_erp_cutover') }}

)

select
    e.source_type,
    e.scenario,
    e.fiscal_year,
    e.fiscal_month,
    e.month_name,
    e.reporting_type,
    e.account_code,
    e.gl_code,
    e.intercompany,
    e.ips_dept,
    e.future_1,
    e.gl_date,
    e.gl_date as trans_date,
    e.currency,
    e.loaded_at,
    e.mtd_amount as trans_amt,
    cast(null as double) as aop_amt,
    cast(null as double) as fcst_amt
from enriched e
inner join cutover c
    on e.gl_code = c.segment2_code
where e.gl_date <= c.erp_cutover_date