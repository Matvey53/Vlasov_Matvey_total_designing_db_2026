create table vlasov_food.client (
    client_id uuid primary key default exts.uuid_generate_v4(),
    login varchar(100) not null unique,
    password varchar(32) not null,
    phone_number char(11) not null unique
);

create table vlasov_food.address (
    address_id uuid primary key default exts.uuid_generate_v4(),
    street varchar(150) not null,
    house_number varchar(20) not null,
    apartment_office varchar(20)
);

create table vlasov_food.client_address (
    client_id uuid not null references vlasov_food.client(client_id),
    address_id uuid not null references vlasov_food.address(address_id),
    primary key (client_id, address_id)
);

create table vlasov_food.restaurant (
    restaurant_id uuid primary key default exts.uuid_generate_v4(),
    restaurant_name varchar(150) not null,
    address_id uuid not null unique references vlasov_food.address(address_id),
    description text not null,
    work_start time not null,
    work_end time not null,
    company_details text not null,
    rating numeric(3, 2),
    status vlasov_food.restaurant_status not null,
    check (work_end > work_start),
    check (rating between 0 and 5)
);

create table vlasov_food.courier (
    courier_id uuid primary key default exts.uuid_generate_v4(),
    fio varchar(150) not null,
    phone_number char(11) not null,
    status vlasov_food.courier_status not null,
    hire_date date not null,
    dismissal_date date,
    coefficient numeric(3, 1) not null default 0.1,
    check (coefficient between 0.1 and 0.5),
    check (dismissal_date is null or dismissal_date >= hire_date),
    check (status <> 'уволен' or dismissal_date is not null)
);

create table vlasov_food.courier_pay (
    year integer not null,
    month integer not null,
    courier_id uuid not null references vlasov_food.courier(courier_id),
    amount numeric(12, 2) not null,
    coefficient_used numeric(3, 1) not null,
    primary key (year, month, courier_id),
    check (month between 1 and 12),
    check (amount >= 0),
    check (coefficient_used between 0.1 and 0.5)
);

create table vlasov_food.product_category (
    product_category_id uuid primary key default exts.uuid_generate_v4(),
    product_category_name varchar(100) not null
);

create table vlasov_food.product (
    product_id uuid primary key default exts.uuid_generate_v4(),
    product_name varchar(150) not null,
    product_category_id uuid not null references vlasov_food.product_category(product_category_id),
    price numeric(12, 2) not null,
    restaurant_id uuid not null references vlasov_food.restaurant(restaurant_id),
    photo_url text,
    rating numeric(3, 2),
    status vlasov_food.product_status not null,
    description text not null,
    check (price >= 0),
    check (rating between 0 and 5)
);

create table vlasov_food."order" (
    order_id uuid primary key default exts.uuid_generate_v4(),
    courier_id uuid not null references vlasov_food.courier(courier_id),
    client_id uuid not null references vlasov_food.client(client_id),
    address_id uuid not null references vlasov_food.address(address_id),
    restaurant_id uuid not null references vlasov_food.restaurant(restaurant_id),
    order_timestamp timestamp not null default current_timestamp,
    delivery_timestamp timestamp,
    order_amount numeric(12, 2) not null,
    commission numeric(12, 2) not null,
    total_amount numeric(12, 2) not null,
    status vlasov_food.order_status not null,
    pay_status vlasov_food.order_pay_status not null,
    description text,
    foreign key (client_id, address_id)
        references vlasov_food.client_address(client_id, address_id),
    check (order_amount >= 0),
    check (commission = round(order_amount * 0.10, 2)),
    check (total_amount = order_amount + commission),
    check (total_amount >= 1000),
    check (delivery_timestamp is null or delivery_timestamp >= order_timestamp),
    check (status <> 'доставлен' or delivery_timestamp is not null)
);

create table vlasov_food.payment (
    payment_id uuid primary key default exts.uuid_generate_v4(),
    order_id uuid not null references vlasov_food."order"(order_id),
    payment_type vlasov_food.payment_type not null,
    amount numeric(12, 2) not null,
    transaction_id uuid not null unique default exts.uuid_generate_v4(),
    payment_timestamp timestamp not null,
    status vlasov_food.payment_status not null,
    check (amount >= 0)
);

create unique index payment_one_success
on vlasov_food.payment(order_id)
where status = 'успех';

create table vlasov_food.order_structure (
    order_id uuid not null references vlasov_food."order"(order_id),
    product_id uuid not null references vlasov_food.product(product_id),
    quantity numeric(12, 3) not null,
    primary key (order_id, product_id),
    check (quantity > 0)
);

create table vlasov_food.review (
    review_id uuid primary key default exts.uuid_generate_v4(),
    client_id uuid not null references vlasov_food.client(client_id),
    review_timestamp timestamp not null,
    entity_id uuid not null,
    entity_type vlasov_food.review_entity_type not null,
    order_id uuid not null references vlasov_food."order"(order_id),
    description text not null,
    photo_url text,
    rating numeric(3, 2) not null,
    unique (order_id, entity_type, entity_id),
    check (rating between 1 and 5)
);
