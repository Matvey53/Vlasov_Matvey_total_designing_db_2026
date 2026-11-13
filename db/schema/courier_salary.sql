create or replace procedure vlasov_food.courier_salary()
language plpgsql as $$
declare
    c record;
    month_start timestamp := date_trunc('month', current_timestamp);
    deliveries integer;
    commissions numeric;
    new_coefficient numeric(3,1);
    used_coefficient numeric(3,1);
begin
    for c in select courier_id, status, coefficient
             from vlasov_food.courier loop
        select count(*), coalesce(sum(commission), 0)
        into deliveries, commissions
        from vlasov_food."order"
        where courier_id = c.courier_id
          and status = 'доставлен'
          and order_timestamp >= month_start
          and order_timestamp < month_start + interval '1 month';

        new_coefficient := case
            when deliveries <= 150 then 0.1
            when deliveries <= 250 then 0.2
            when deliveries <= 500 then 0.3
            else 0.5
        end;

        select cp.coefficient_used into used_coefficient
        from vlasov_food.courier_pay cp
        where cp.courier_id = c.courier_id
          and cp.year = extract(year from month_start)::integer
          and cp.month = extract(month from month_start)::integer;

        if not found then
            used_coefficient := c.coefficient;
        end if;

        insert into vlasov_food.courier_pay
            (year, month, courier_id, amount, coefficient_used)
        values (
            extract(year from month_start)::integer,
            extract(month from month_start)::integer,
            c.courier_id,
            round(used_coefficient * commissions, 2),
            used_coefficient
        )
        on conflict (year, month, courier_id)
        do update set amount = excluded.amount,
                      coefficient_used = excluded.coefficient_used;

        if c.status <> 'уволен' then
            update vlasov_food.courier
            set coefficient = new_coefficient
            where courier_id = c.courier_id;
        end if;
    end loop;
end;
$$;
