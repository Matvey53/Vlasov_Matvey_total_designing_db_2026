
create or replace procedure vlasov_food.add_product(
    p_product_name varchar(150),
    p_product_category_id uuid,
    p_price numeric(12, 2),
    p_restaurant_id uuid,
    p_photo_url text,
    p_rating numeric(3, 2),
    p_status vlasov_food.product_status,
    p_description text
)
language plpgsql
as $$
begin
    insert into vlasov_food.product (
        product_name,
        product_category_id,
        price,
        restaurant_id,
        photo_url,
        rating,
        status,
        description
    )
    values (
        p_product_name,
        p_product_category_id,
        p_price,
        p_restaurant_id,
        p_photo_url,
        p_rating,
        p_status,
        p_description
    );
end;
$$;

