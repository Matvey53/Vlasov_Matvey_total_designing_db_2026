create or replace function vlasov_food.get_statistic()
returns table (
    restaurant_name varchar(150),
    best_product_name varchar(150),
    total_amount numeric,
    avg_amount numeric,
    best_user varchar(100)
)
language sql as $$
    with delivered as (
        select o.order_id, o.restaurant_id, o.client_id, o.total_amount
        from vlasov_food."order" o
        where o.status = 'доставлен'
    ),
    money as (
        select restaurant_id,
               sum(total_amount) as total_amount,
               avg(total_amount) as avg_amount
        from delivered
        group by restaurant_id
    ),
    product_qty as (
        select d.restaurant_id, p.product_name, sum(os.quantity) as qty
        from delivered d
        join vlasov_food.order_structure os on os.order_id = d.order_id
        join vlasov_food.product p on p.product_id = os.product_id
        group by d.restaurant_id, p.product_id, p.product_name
    ),
    best_products as (
        select distinct on (restaurant_id) restaurant_id, product_name
        from (
            select restaurant_id, product_name, qty, random() as tie_break
            from product_qty
        ) s
        order by restaurant_id, qty desc, tie_break
    ),
    client_qty as (
        select d.restaurant_id, c.login, count(*) as cnt
        from delivered d
        join vlasov_food.client c on c.client_id = d.client_id
        group by d.restaurant_id, c.client_id, c.login
    ),
    best_clients as (
        select distinct on (restaurant_id) restaurant_id, login
        from (
            select restaurant_id, login, cnt, random() as tie_break
            from client_qty
        ) s
        order by restaurant_id, cnt desc, tie_break
    )
    select r.restaurant_name,
           bp.product_name,
           m.total_amount,
           m.avg_amount,
           bc.login
    from vlasov_food.restaurant r
    left join money m on m.restaurant_id = r.restaurant_id
    left join best_products bp on bp.restaurant_id = r.restaurant_id
    left join best_clients bc on bc.restaurant_id = r.restaurant_id;
$$;
