create or replace view vlasov_food.how_much_money as
with recursive
monthly_orders as (
    select date_trunc('month', order_timestamp)::date as month_start,
           sum(order_amount) as sum_no_commission,
           sum(total_amount) as sum_with_commission
    from vlasov_food."order"
    where status = 'доставлен'
    group by 1
),
bounds as (
    select min(month_start) as first_month, max(month_start) as last_month
    from monthly_orders
),
months(month_start) as (
    select first_month from bounds where first_month is not null
    union all
    select (m.month_start + interval '1 month')::date
    from months m cross join bounds b
    where m.month_start < b.last_month
),
monthly_pay as (
    select make_date(year, month, 1) as month_start,
           sum(amount) as courier_pay
    from vlasov_food.courier_pay
    group by 1
),
totals as (
    select m.month_start,
           coalesce(o.sum_no_commission, 0)::numeric as sum_no_commission,
           coalesce(o.sum_with_commission, 0)::numeric as sum_with_commission,
           (coalesce(o.sum_with_commission, 0) -
            coalesce(o.sum_no_commission, 0))::numeric as commission,
           coalesce(p.courier_pay, 0)::numeric as courier_pay
    from months m
    left join monthly_orders o on o.month_start = m.month_start
    left join monthly_pay p on p.month_start = m.month_start
),
with_previous as (
    select *, lag(commission) over (order by month_start) as prev_commission
    from totals
)
select to_char(month_start, 'YYYY-MM')::text as year_month,
       sum_no_commission, sum_with_commission, commission,
       prev_commission,
       (commission - prev_commission)::numeric as commission_diff,
       courier_pay,
       (commission - courier_pay)::numeric as net_profit
from with_previous;
