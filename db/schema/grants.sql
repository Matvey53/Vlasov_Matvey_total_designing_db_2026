do $$
begin
    if not exists (select 1 from pg_catalog.pg_roles where rolname = 'inspector') then
        create role inspector login password 'NetoSQL2025';
    end if;
end;
$$;

grant usage, create on schema vlasov_food to inspector;
grant all privileges on all tables in schema vlasov_food to inspector;
grant all privileges on all sequences in schema vlasov_food to inspector;
grant execute on all functions in schema vlasov_food to inspector;
grant execute on all procedures in schema vlasov_food to inspector;
grant usage on schema exts to inspector;
