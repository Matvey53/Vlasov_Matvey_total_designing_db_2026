create or replace procedure vlasov_food.insert_test_data(value integer)
language plpgsql
as $$
declare
    alphabet constant text := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
    clients uuid[] := '{}';
    addresses uuid[] := '{}';
    restaurants uuid[] := '{}';
    couriers uuid[] := '{}';
    categories uuid[] := '{}';
    products uuid[] := '{}';
    prices numeric[] := '{}';
    rest_products uuid[];
    rest_prices numeric[];
    qtys integer[];
    chosen integer[];
    new_id uuid;
    v_order_id uuid;
    v_entity_id uuid;
    v_price numeric(12, 2);
    order_amount numeric(12, 2);
    v_commission numeric(12, 2);
    v_total numeric(12, 2);
    order_time timestamp;
    month_start timestamp;
    last_month timestamp := date_trunc('month', localtimestamp);
    v_delivery timestamp;
    current_coefficient numeric(3, 1);
    next_coefficient numeric(3, 1);
    commissions numeric(12, 2);
    v_hire date;
    v_dismissal date;
    v_work_start time;
    v_work_end time;
    v_courier_status vlasov_food.courier_status;
    v_order_status vlasov_food.order_status;
    v_payment_type vlasov_food.payment_type;
    v_review_type vlasov_food.review_entity_type;
    delivered_count integer;
    n_dishes integer;
    qty integer;
    client_index integer;
    address_index integer;
    courier_index integer;
    i integer;
    j integer;
    k integer;
begin
    if value is null or value < 1 then
        raise exception 'value должен быть положительным';
    end if;

    for i in 1..value loop
        v_courier_status := case
            when random() < 0.2 then 'уволен'::vlasov_food.courier_status
            else (enum_range(null::vlasov_food.courier_status))[
                1 + floor(random() * cardinality(enum_range(null::vlasov_food.courier_status)))::int
            ]
        end;
        v_hire := current_date - (random() * 180)::int;
        if v_courier_status = 'уволен' then
            v_dismissal := v_hire + floor(random() * (current_date - v_hire + 1))::int;
        else
            v_dismissal := null;
        end if;

        insert into vlasov_food.courier (
            fio, phone_number, status, hire_date, dismissal_date, coefficient
        ) values (
            repeat(
                substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                1 + floor(random() * 3)::int
            ),
            '7' || lpad(floor(random() * 10000000000)::bigint::text, 10, '0'),
            v_courier_status,
            v_hire,
            v_dismissal,
            0.1
        ) returning courier_id into new_id;
        couriers := array_append(couriers, new_id);

        insert into vlasov_food.client (login, password, phone_number)
        values (
            substring(
                repeat(
                    substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                    1 + floor(random() * 2)::int
                ) || md5(random()::text),
                1,
                100
            ),
            md5(random()::text),
            '7' || lpad(floor(random() * 10000000000)::bigint::text, 10, '0')
        ) returning client_id into new_id;
        clients := array_append(clients, new_id);

        insert into vlasov_food.product_category (product_category_name)
        values (
            repeat(
                substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                1 + floor(random() * 3)::int
            )
        ) returning product_category_id into new_id;
        categories := array_append(categories, new_id);
    end loop;

    if not exists (
        select 1 from vlasov_food.courier where status <> 'уволен'
    ) then
        update vlasov_food.courier
        set status = 'свободен', dismissal_date = null
        where courier_id = couriers[1];
    end if;

    for i in 1..value * 5 loop
        insert into vlasov_food.address (street, house_number, apartment_office)
        values (
            repeat(
                substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                1 + floor(random() * 3)::int
            ),
            (1 + floor(random() * 200)::int)::text,
            case
                when random() < 0.3 then null
                else (1 + floor(random() * 100)::int)::text
            end
        ) returning address_id into new_id;
        addresses := array_append(addresses, new_id);
    end loop;

    for i in 1..value loop
        v_work_start := time '08:00' + floor(random() * 6)::int * interval '1 hour';
        v_work_end := v_work_start + (4 + floor(random() * 6)::int) * interval '1 hour';

        insert into vlasov_food.restaurant (
            restaurant_name, address_id, description, work_start, work_end,
            company_details, status
        ) values (
            repeat(
                substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                1 + floor(random() * 3)::int
            ),
            addresses[i],
            substring(md5(random()::text), 1, 1 + floor(random() * 31)::int),
            v_work_start,
            v_work_end,
            substring(md5(random()::text), 1, 1 + floor(random() * 31)::int),
            (enum_range(null::vlasov_food.restaurant_status))[
                1 + floor(random() * cardinality(enum_range(null::vlasov_food.restaurant_status)))::int
            ]
        ) returning restaurant_id into new_id;
        restaurants := array_append(restaurants, new_id);
    end loop;

    for i in 1..value * 4 loop
        j := ((i - 1) / 4) + 1;
        insert into vlasov_food.client_address (client_id, address_id)
        values (clients[j], addresses[value + i]);
    end loop;

    for i in 1..value * 5 loop
        j := ((i - 1) % value) + 1;
        v_price := 1000 + floor(random() * 4000)::int;
        insert into vlasov_food.product (
            product_name, product_category_id, price, restaurant_id,
            photo_url, status, description
        ) values (
            repeat(
                substring(alphabet, 1, 1 + floor(random() * length(alphabet))::int),
                1 + floor(random() * 3)::int
            ),
            categories[1 + floor(random() * value)::int],
            v_price,
            restaurants[j],
            case
                when random() < 0.5 then null
                else 'https://cdn.foodexpress.ru/img/' || md5(random()::text) || '.jpg'
            end,
            (enum_range(null::vlasov_food.product_status))[
                1 + floor(random() * cardinality(enum_range(null::vlasov_food.product_status)))::int
            ],
            substring(md5(random()::text), 1, 1 + floor(random() * 31)::int)
        ) returning product_id into new_id;
        products := array_append(products, new_id);
        prices := array_append(prices, v_price);
    end loop;

    for i in 1..value * 5 loop
        j := ((i - 1) % value) + 1;
        client_index := 1 + floor(random() * value)::int;
        address_index := value + (client_index - 1) * 4 + 1 + floor(random() * 4)::int;
        courier_index := 1 + floor(random() * value)::int;

        rest_products := array[
            products[j],
            products[j + value],
            products[j + 2 * value],
            products[j + 3 * value],
            products[j + 4 * value]
        ];
        rest_prices := array[
            prices[j],
            prices[j + value],
            prices[j + 2 * value],
            prices[j + 3 * value],
            prices[j + 4 * value]
        ];
        n_dishes := 1 + floor(random() * 5)::int;
        chosen := '{}';
        while coalesce(array_length(chosen, 1), 0) < n_dishes loop
            k := 1 + floor(random() * 5)::int;
            if not k = any(chosen) then
                chosen := array_append(chosen, k);
            end if;
        end loop;

        qtys := '{}';
        order_amount := 0;
        for k in 1..n_dishes loop
            qty := 1 + floor(random() * 5)::int;
            qtys := array_append(qtys, qty);
            order_amount := order_amount + round(rest_prices[chosen[k]] * qty, 2);
        end loop;
        v_commission := round(order_amount * 0.10, 2);
        v_total := order_amount + v_commission;

        order_time := localtimestamp - (random() * 180)::int * interval '1 day';
        if order_time > localtimestamp - interval '3 hours' then
            order_time := localtimestamp - interval '3 hours';
        end if;

        v_order_status := (enum_range(null::vlasov_food.order_status))[
            1 + floor(random() * cardinality(enum_range(null::vlasov_food.order_status)))::int
        ];
        v_payment_type := (enum_range(null::vlasov_food.payment_type))[
            1 + floor(random() * cardinality(enum_range(null::vlasov_food.payment_type)))::int
        ];
        v_review_type := (enum_range(null::vlasov_food.review_entity_type))[
            1 + floor(random() * cardinality(enum_range(null::vlasov_food.review_entity_type)))::int
        ];
        if v_order_status = 'доставлен' then
            v_delivery := order_time + interval '1 hour';
        else
            v_delivery := null;
        end if;

        insert into vlasov_food."order" (
            courier_id, client_id, address_id, restaurant_id,
            order_timestamp, delivery_timestamp, order_amount,
            commission, total_amount, status, pay_status, description
        ) values (
            couriers[courier_index],
            clients[client_index],
            addresses[address_index],
            restaurants[j],
            order_time,
            v_delivery,
            order_amount,
            v_commission,
            v_total,
            v_order_status,
            'оплачен',
            substring(md5(random()::text), 1, 1 + floor(random() * 31)::int)
        ) returning order_id into v_order_id;

        for k in 1..n_dishes loop
            insert into vlasov_food.order_structure (order_id, product_id, quantity)
            values (v_order_id, rest_products[chosen[k]], qtys[k]);
        end loop;

        insert into vlasov_food.payment (
            order_id, payment_type, amount, transaction_id,
            payment_timestamp, status
        ) values (
            v_order_id,
            v_payment_type,
            v_total,
            exts.uuid_generate_v4(),
            order_time + interval '30 minutes',
            'успех'
        );

        v_entity_id := case v_review_type
            when 'блюдо' then rest_products[chosen[1 + floor(random() * n_dishes)::int]]
            when 'ресторан' then restaurants[j]
            else v_order_id
        end;

        insert into vlasov_food.review (
            client_id, review_timestamp, entity_id, entity_type,
            order_id, description, photo_url, rating
        ) values (
            clients[client_index],
            order_time + interval '2 hours',
            v_entity_id,
            v_review_type,
            v_order_id,
            substring(md5(random()::text), 1, 1 + floor(random() * 31)::int),
            case
                when random() < 0.5 then null
                else 'https://cdn.foodexpress.ru/img/' || md5(random()::text) || '.jpg'
            end,
            1 + floor(random() * 5)::int
        );
    end loop;

    update vlasov_food.product p
    set rating = (
        select round(avg(r.rating), 2)
        from vlasov_food.review r
        where r.entity_type = 'блюдо'
          and r.entity_id = p.product_id
    );

    update vlasov_food.restaurant t
    set rating = (
        select round(avg(r.rating), 2)
        from vlasov_food.review r
        where r.entity_type = 'ресторан'
          and r.entity_id = t.restaurant_id
    );

    for j in 1..value loop
        select status into v_courier_status
        from vlasov_food.courier
        where courier_id = couriers[j];

        current_coefficient := 0.1;
        for month_start in
            select generate_series(
                date_trunc('month', localtimestamp) - interval '5 months',
                date_trunc('month', localtimestamp),
                interval '1 month'
            )
        loop
            select count(*), coalesce(sum(commission), 0)
            into delivered_count, commissions
            from vlasov_food."order"
            where courier_id = couriers[j]
              and status = 'доставлен'
              and order_timestamp >= month_start
              and order_timestamp < month_start + interval '1 month';

            insert into vlasov_food.courier_pay (
                year, month, courier_id, amount, coefficient_used
            ) values (
                extract(year from month_start)::int,
                extract(month from month_start)::int,
                couriers[j],
                round(current_coefficient * commissions, 2),
                current_coefficient
            );

            next_coefficient := case
                when delivered_count <= 150 then 0.1
                when delivered_count <= 250 then 0.2
                when delivered_count <= 500 then 0.3
                else 0.5
            end;

            if month_start < last_month or v_courier_status <> 'уволен' then
                current_coefficient := next_coefficient;
            end if;
        end loop;

        update vlasov_food.courier
        set coefficient = current_coefficient
        where courier_id = couriers[j];
    end loop;
end;
$$;
