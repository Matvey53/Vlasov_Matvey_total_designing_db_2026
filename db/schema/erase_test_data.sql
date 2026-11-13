
create or replace procedure vlasov_food.erase_test_data()
language plpgsql
as $$
begin
    truncate table
        vlasov_food.review,
        vlasov_food.order_structure,
        vlasov_food.payment,
        vlasov_food.courier_pay,
        vlasov_food."order",
        vlasov_food.product,
        vlasov_food.product_category,
        vlasov_food.client_address,
        vlasov_food.restaurant,
        vlasov_food.courier,
        vlasov_food.client,
        vlasov_food.address;
end;
$$;

