{{ config(materialized='table') }}

-- Final, BI-usable GL fact at transaction grain.
-- Reads the unioned intermediate and enriches with descriptive attributes.
--
-- Account master is joined now. The service center roster will be joined later
-- once its staging model exists (see the commented block near the join).

with gl as (

    select * from {{ ref('int_planful_erp_gl_unioned') }}

),

accounts as (

    select
        *
    from {{ ref('stg_gl_account_master') }}

)

select
    -- keys / dimensions from the union
    g.source_type,
    g.scenario,
    g.planful_je_flag,
    g.gl_date,
    g.trans_date,
    g.reporting_type,
    g.currency,

    -- segments
    g.account_code,
    g.gl_code,
    g.intercompany,
    g.ips_dept,
    g.future_1,

    -- account master attributes
    a.* exclude(account_code),

    -- service center roster attributes will be added here later, e.g.:
    -- sc.service_center_name,
    -- sc.region,
    -- sc.division,

    -- measures
    g.trans_amt,
    g.aop_amt,
    g.fcst_amt,
    g.loaded_at

from gl as g

left join accounts as a
    on g.account_code = a.account_code

-- Service center roster join goes here once stg_reference__service_center exists:
-- left join {{ '{{' }} ref('stg_reference__service_center') }} as sc
--     on g.gl_code = sc.service_center_code