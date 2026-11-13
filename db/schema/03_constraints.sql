create or replace function vlasov_food.check_order_structure_restaurant()
returns trigger
language plpgsql
as $$
begin
    if not exists (
        select 1
        from vlasov_food."order" o
        join vlasov_food.product p on p.product_id = new.product_id
        where o.order_id = new.order_id
          and p.restaurant_id = o.restaurant_id
    ) then
        raise exception 'блюдо не принадлежит ресторану заказа';
    end if;
    return new;
end;
$$;

create or replace function vlasov_food.check_order_restaurant()
returns trigger
language plpgsql
as $$
begin
    if exists (
        select 1
        from vlasov_food.order_structure os
        join vlasov_food.product p on p.product_id = os.product_id
        where os.order_id = new.order_id
          and p.restaurant_id <> new.restaurant_id
    ) then
        raise exception 'нельзя сменить ресторан: в заказе есть блюда другого ресторана';
    end if;
    return new;
end;
$$;

create or replace function vlasov_food.check_product_restaurant()
returns trigger
language plpgsql
as $$
begin
    if exists (
        select 1
        from vlasov_food.order_structure os
        join vlasov_food."order" o on o.order_id = os.order_id
        where os.product_id = new.product_id
          and o.restaurant_id <> new.restaurant_id
    ) then
        raise exception 'нельзя сменить ресторан блюда: оно уже есть в заказе другого ресторана';
    end if;
    return new;
end;
$$;

create trigger check_order_structure_restaurant_trigger
before insert or update on vlasov_food.order_structure
for each row
execute function vlasov_food.check_order_structure_restaurant();

create trigger check_order_restaurant_trigger
before update of restaurant_id on vlasov_food."order"
for each row
execute function vlasov_food.check_order_restaurant();

create trigger check_product_restaurant_trigger
before update of restaurant_id on vlasov_food.product
for each row
execute function vlasov_food.check_product_restaurant();
