# Обоснование ограничений FoodExpress

## Enum-типы

| Тип | Значения | BR |
|---|---|---|
| `restaurant_status` | `активен`, `неактивен` | BR-4.3 |
| `product_status` | `доступно`, `нет_в_наличии`, `архив` | BR-5.5 |
| `courier_status` | `свободен`, `занят`, `на_доставке`, `уволен` | BR-6.2 |
| `order_status` | `создан`, `готовится`, `в_доставке`, `доставлен`, `отменён` | BR-7.7 |
| `order_pay_status` | `ожидает`, `оплачен`, `ошибка` | BR-7.9 |
| `payment_status` | `успех`, `ошибка`, `в_обработке` | BR-8.2 |
| `payment_type` | `карта`, `наличные`, `безнал` | BR-8.2 |
| `review_entity_type` | `блюдо`, `ресторан`, `заказ` | BR-9.1 |

## Ловушки

### Ловушка 1. `payment` — неполная сущность

Добавлены `payment_type` (способ оплаты), `amount` (сумма попытки), `transaction_id` (внешний идентификатор), `payment_timestamp` (время операции), `status` (результат попытки). Эти поля нужны по BR-8.2. `transaction_id` имеет тип `uuid` и уникален: это идентификатор (BR-11.1, BR-8.3), а не данные карты (BR-8.5).

Тип оплаты находится в `payment`, а не в `order`, потому что один заказ может иметь несколько попыток с разными способами оплаты (BR-8.6).

### Ловушка 2. `order.address_id` — адрес клиента

Использован составной внешний ключ `foreign key (client_id, address_id) references client_address(client_id, address_id)`. Он не позволяет указать адрес, не привязанный к клиенту заказа (BR-7.4). Обычный FK только по `address_id` этого не гарантировал бы.

### Ловушка 3. `order_structure` — один ресторан

Три функции сравнивают `product.restaurant_id` и `order.restaurant_id` (BR-7.3). `check_order_structure_restaurant()` срабатывает при вставке или изменении позиции, `check_order_restaurant()` — при смене ресторана заказа, `check_product_restaurant()` — при смене ресторана блюда. Отдельный `restaurant_id` в `order_structure` не хранится, чтобы не дублировать ресторан заказа и блюда.

### Ловушка 4. `review` — полиморфизм

Использована пара `entity_type` и `entity_id` (BR-9.1). `entity_type` определяет, с какой таблицей связан отзыв: `product`, `restaurant` или `order`. Обычный FK для `entity_id` невозможен, потому что одна колонка может ссылаться на три разные таблицы. `order_id` связан обычным FK с заказом, а `client_id` — с клиентом (BR-9.2). **Ограничение текущей реализации:** валидность целевого `entity_id` и принадлежность объекта заказу пока не обеспечены ограничением БД; эту проверку нужно реализовать или явно определить уровень её выполнения.

## CHECK-ограничения

| Таблица | Столбец | Условие | BR | Обоснование |
|---|---|---|---|---|
| `restaurant` | `work_start`, `work_end` | `work_end > work_start` | BR-4.4 | Закрытие позже открытия |
| `restaurant` | `rating` | `rating between 0 and 5` | BR-4.2 | Диапазон рейтинга ресторана |
| `courier` | `coefficient` | `coefficient between 0.1 and 0.5` | BR-6.4 | Допустимый коэффициент |
| `courier` | `dismissal_date`, `hire_date` | `dismissal_date is null or dismissal_date >= hire_date` | BR-6.1, BR-6.3 | Дата увольнения не раньше найма |
| `courier` | `status`, `dismissal_date` | `status <> 'уволен' or dismissal_date is not null` | BR-6.3 | Уволенный курьер обязан иметь дату увольнения |
| `courier_pay` | `month` | `month between 1 and 12` | BR-10.1 | Выплата относится к календарному месяцу |
| `courier_pay` | `amount` | `amount >= 0` | BR-10.4 | Зарплата неотрицательна |
| `courier_pay` | `coefficient_used` | `coefficient_used between 0.1 and 0.5` | BR-6.4, BR-10.2 | Сохраняется допустимый применённый коэффициент |
| `product` | `price` | `price >= 0` | BR-5.3 | Цена неотрицательна |
| `product` | `rating` | `rating between 0 and 5` | BR-5.4 | Диапазон рейтинга блюда |
| `order` | `order_amount` | `order_amount >= 0` | BR-7.10 | Сумма блюд используется в расчёте заказа |
| `order` | `commission` | `commission = round(order_amount * 0.10, 2)` | BR-1.4, BR-7.10 | Комиссия равна 10% |
| `order` | `total_amount` | `total_amount = order_amount + commission` | BR-7.10 | Общая сумма включает комиссию |
| `order` | `total_amount` | `total_amount >= 1000` | BR-1.8, BR-7.11 | Минимальная сумма заказа |
| `order` | `delivery_timestamp`, `order_timestamp` | `delivery_timestamp is null or delivery_timestamp >= order_timestamp` | BR-7.13 | Доставка не раньше создания |
| `order` | `status`, `delivery_timestamp` | `status <> 'доставлен' or delivery_timestamp is not null` | BR-7.12 | Доставленный заказ имеет время доставки |
| `payment` | `amount` | `amount >= 0` | BR-8.2, BR-8.4 | Сумма попытки оплаты должна соответствовать сумме заказа |
| `order_structure` | `quantity` | `quantity > 0` | BR-7.15 | Количество положительное |
| `review` | `rating` | `rating between 1 and 5` | BR-9.4 | Допустимый рейтинг отзыва |

## UNIQUE-ограничения

| Таблица | Столбцы | BR | Обоснование |
|---|---|---|---|
| `client` | `login` | BR-2.2 | Уникальный логин |
| `client` | `phone_number` | BR-2.2 | Уникальный телефон |
| `restaurant` | `address_id` | BR-3.3 | Два ресторана не могут иметь один адрес |
| `payment` | `transaction_id` | BR-8.3 | Внешний идентификатор транзакции уникален |
| `payment` | `order_id where status = 'успех'` | BR-8.1 | Частичный уникальный индекс: не больше одной успешной попытки |
| `review` | `(order_id, entity_type, entity_id)` | BR-9.5 | Один отзыв на объект в рамках заказа |

Первичные ключи `client_address(client_id, address_id)`, `order_structure(order_id, product_id)` и `courier_pay(year, month, courier_id)` также обеспечивают уникальность сочетаний по BR-2.5, BR-7.16 и BR-10.3 соответственно.

## FK-ограничения

| Таблица | Столбцы | → Таблица | BR | Обоснование |
|---|---|---|---|---|
| `client_address` | `client_id` | `client(client_id)` | BR-2.4 | Адрес связан с существующим клиентом |
| `client_address` | `address_id` | `address(address_id)` | BR-2.4 | Привязка к существующему адресу |
| `restaurant` | `address_id` | `address(address_id)` | BR-3.3 | Ресторан имеет адрес |
| `courier_pay` | `courier_id` | `courier(courier_id)` | BR-10.1 | Выплата относится к курьеру |
| `product` | `product_category_id` | `product_category(product_category_id)` | BR-5.1 | Блюдо относится к категории |
| `product` | `restaurant_id` | `restaurant(restaurant_id)` | BR-5.1 | Блюдо принадлежит ресторану |
| `order` | `courier_id` | `courier(courier_id)` | BR-7.5 | Заказ доставляет курьер |
| `order` | `client_id` | `client(client_id)` | BR-7.1 | Заказ оформляет клиент |
| `order` | `address_id` | `address(address_id)` | BR-7.4 | Адрес существует |
| `order` | `restaurant_id` | `restaurant(restaurant_id)` | BR-7.2 | Заказ относится к ресторану |
| `order` | `(client_id, address_id)` | `client_address(client_id, address_id)` | BR-7.4 | Адрес принадлежит клиенту заказа |
| `payment` | `order_id` | `order(order_id)` | BR-8.1 | Попытка оплаты относится к заказу |
| `order_structure` | `order_id` | `order(order_id)` | BR-7.14 | Позиция относится к заказу |
| `order_structure` | `product_id` | `product(product_id)` | BR-7.14 | Позиция содержит блюдо |
| `review` | `client_id` | `client(client_id)` | BR-9.2 | Отзыв оставляет клиент |
| `review` | `order_id` | `order(order_id)` | BR-9.2 | Отзыв связан с заказом |

## NOT NULL (только бизнес-обязательные)

Основные обязательные поля уже заданы в `02_tables.sql` по BR-11.3 и соответствующим правилам сущностей. PK и обязательные FK отдельно не перечисляются. Специальные случаи: `payment.transaction_id`, `payment.payment_timestamp`, `payment.status`, `payment.payment_type`, `payment.amount` обязательны по BR-8.2; `review.entity_type`, `review.entity_id`, `review.rating`, `review.review_timestamp`, `review.description` — по BR-9.1 и BR-9.3.

## NULL (осознанно разрешено)

| Таблица | Столбец | BR | Почему NULL |
|---|---|---|---|
| `address` | `apartment_office` | BR-3.2 | Не у каждого адреса есть квартира или офис |
| `product` | `photo_url` | BR-5.6 | Фото необязательно |
| `review` | `photo_url` | BR-9.3 | Фото необязательно |
| `courier` | `dismissal_date` | BR-6.3 | Работающий курьер может не иметь даты увольнения |
| `order` | `delivery_timestamp` | BR-7.12 | Заказ ещё не доставлен |
| `product` | `rating` | BR-9.7 | Пока нет отзывов, рейтинг отсутствует |
| `restaurant` | `rating` | BR-9.7 | Пока нет отзывов, рейтинг отсутствует |
| `order` | `description` | BR-11.3 | В текущей схеме допускается NULL, но явного разрешения в BR нет; требуется исправить или обосновать |

## DEFAULT и GENERATED

| Таблица | Столбец | Что | Обоснование |
|---|---|---|---|
| Таблицы с UUID PK | `*_id` | `default exts.uuid_generate_v4()` | BR-11.1: ID генерируются сервером |
| `courier` | `coefficient` | `default 0.1` | BR-6.5: начальный коэффициент |
| `order` | `order_timestamp` | `default current_timestamp` | BR-7.1, BR-11.2: время создания на сервере |
| `order` | `commission`, `total_amount` | Обычные поля с `check`, не `generated` | BR-7.10: храним суммы и контролируем формулы через `check` |

## Нормализация (3НФ)

В большинстве таблиц неключевые поля зависят от первичного ключа. В таблицах со составным ключом (`client_address`, `order_structure`, `courier_pay`) значения относятся ко всему сочетанию ключей. Сведения о клиенте, адресе, ресторане, категории и блюде вынесены в отдельные таблицы, чтобы не повторять их в заказах.

`order.commission` и `order.total_amount` вычисляются из `order_amount` по BR-7.10. Они оставлены как хранимые значения с проверками, хотя это избыточность; выбор сделан для хранения итоговых сумм заказа. `product.rating` и `restaurant.rating` — агрегаты отзывов, предусмотренные BR-9.6 и BR-9.7; их автоматическое обновление должно быть реализовано триггером `rating_change` в FOOD-105. Это осознанная денормализация ради быстрого чтения рейтинга.

Пара `review.entity_type` + `review.entity_id` позволяет ссылаться на три вида объектов без трёх отдельных колонок. Сам по себе такой полиморфизм не создаёт транзитивной зависимости, но требует проверки существования целевого объекта.

## Что осталось проверить перед сдачей

- BR-9.2: валидность объекта отзыва отдельным ограничением не гарантируется. Генератор ставит отзыв только на блюдо, ресторан или заказ этой же покупки.
- BR-11.3: `order.description` оставлен nullable. В ERD поле есть, но бизнес-правило не говорит, обязателен ли комментарий к заказу.
- BR-7.14, BR-8.4 и BR-8.7 не закрыты отдельными триггерами. В данных генератора сумма оплаты равна сумме заказа, а `pay_status` выводится из единственной попытки.
- Уникальность телефона в BR-2.2 относится к клиенту. Для курьера такого правила нет, поэтому `unique` на `courier.phone_number` не ставится.
