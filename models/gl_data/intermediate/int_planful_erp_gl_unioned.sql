{{ config(materialized='table') }}

with planful as (
    select * from {{ ref('int_planful__scenarios_unioned') }}
),

acquisition as (
    select * from {{ ref('stg_planful_acq_pre_erp_actuals') }}
),



unioned as (

    select * from planful
    union all by name
    select * from acquisition

    -- union all
    -- select * from erp_us01

)

select * from unioned