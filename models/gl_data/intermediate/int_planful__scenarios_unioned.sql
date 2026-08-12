{{ config(materialized='table') }}

with actuals as (

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
        'Planful JE'      as planful_je_flag,  
        _flight_loaded_at as loaded_at

    from {{ source('planful', 'journal_entries_actual') }}

),

plan as (

    select
        'Plan'            as source_type,
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
        'No'              as planful_je_flag,  
        _flight_loaded_at as loaded_at

    from {{ source('planful', 'aop_fcst_scenarios') }}

),

proforma as (

    select
        'Proforma'        as source_type,
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
        'No'              as planful_je_flag,
        _flight_loaded_at as loaded_at

    from {{ source('planful', 'planful_proforma_data') }}

),

combined as (

    select * from actuals
    union all
    select * from plan
    union all
    select * from proforma

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

    from combined

)

select
    source_type,
    scenario,
    reporting_type,
    account_code,
    gl_code,
    intercompany,
    ips_dept,
    future_1,
    gl_date,
    gl_date as trans_date,
    currency,
    loaded_at,
    planful_je_flag,
    case when source_type in ('Actual','Proforma')       then mtd_amount end as trans_amt,
    case when scenario ilike '%AOP%'                     then mtd_amount end as aop_amt,
    case when scenario ilike '%fcst%'
         or scenario ilike '%forecast%'                  then mtd_amount end as fcst_amt
from enriched