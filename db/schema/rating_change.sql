create or replace function vlasov_food.rating_change()
returns trigger language plpgsql as $$
begin
    if tg_op in ('UPDATE', 'DELETE') then
        if old.entity_type = 'блюдо' then
            update vlasov_food.product p
            set rating = (select avg(r.rating) from vlasov_food.review r
                          where r.entity_type = 'блюдо' and r.entity_id = old.entity_id)
            where p.product_id = old.entity_id;
        elsif old.entity_type = 'ресторан' then
            update vlasov_food.restaurant t
            set rating = (select avg(r.rating) from vlasov_food.review r
                          where r.entity_type = 'ресторан' and r.entity_id = old.entity_id)
            where t.restaurant_id = old.entity_id;
        end if;
    end if;

    if tg_op in ('INSERT', 'UPDATE') then
        if new.entity_type = 'блюдо' then
            update vlasov_food.product p
            set rating = (select avg(r.rating) from vlasov_food.review r
                          where r.entity_type = 'блюдо' and r.entity_id = new.entity_id)
            where p.product_id = new.entity_id;
        elsif new.entity_type = 'ресторан' then
            update vlasov_food.restaurant t
            set rating = (select avg(r.rating) from vlasov_food.review r
                          where r.entity_type = 'ресторан' and r.entity_id = new.entity_id)
            where t.restaurant_id = new.entity_id;
        end if;
    end if;
    return null;
end;
$$;

drop trigger if exists rating_change_trigger on vlasov_food.review;
create trigger rating_change_trigger
after insert or update or delete on vlasov_food.review
for each row execute function vlasov_food.rating_change();
