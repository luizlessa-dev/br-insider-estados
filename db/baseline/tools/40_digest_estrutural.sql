with app as (select unnest(array['public','public_api','analytics','bcb','cidadania_ai','homabrasil','portal_transparencia']) s)
select 'colunas' k, md5(string_agg(x, '|' order by x)) v from (
  select n.nspname||'.'||c.relname||'.'||a.attname||'.'||format_type(a.atttypid,a.atttypmod)||'.'||a.attnotnull||'.'||coalesce(pg_get_expr(d.adbin,d.adrelid),'')||'.'||a.attnum x
  from pg_class c join pg_namespace n on n.oid=c.relnamespace and n.nspname in (select s from app)
  join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
  left join pg_attrdef d on d.adrelid=c.oid and d.adnum=a.attnum
  where c.relkind in ('r','p')) t
union all
select 'constraints', md5(string_agg(x, '|' order by x)) from (
  select conrelid::regclass::text||'.'||conname||'.'||pg_get_constraintdef(cn.oid) x
  from pg_constraint cn join pg_namespace n on n.oid=cn.connamespace and n.nspname in (select s from app)
  where cn.conrelid<>0) t
union all
select 'indexes', md5(string_agg(x, '|' order by x)) from (
  select schemaname||'.'||tablename||'.'||indexname||'.'||indexdef x from pg_indexes
  where schemaname in (select s from app)) t
union all
select 'functions', md5(string_agg(x, '|' order by x)) from (
  select n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||').'||md5(pg_get_functiondef(p.oid)) x
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace and n.nspname in (select s from app)
  where p.oid not in (select objid from pg_depend where deptype='e') and p.prokind in ('f','p')) t
union all
select 'views', md5(string_agg(x, '|' order by x)) from (
  select schemaname||'.'||viewname||'.'||md5(definition) x from pg_views where schemaname in (select s from app)) t
union all
select 'matviews', md5(string_agg(x, '|' order by x)) from (
  select schemaname||'.'||matviewname||'.'||md5(definition) x from pg_matviews where schemaname in (select s from app)) t
union all
select 'triggers', md5(string_agg(x, '|' order by x)) from (
  select c.relname||'.'||t.tgname||'.'||pg_get_triggerdef(t.oid) x
  from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace
  where n.nspname in (select s from app) and not t.tgisinternal) t
union all
select 'policies', md5(string_agg(x, '|' order by x)) from (
  select schemaname||'.'||tablename||'.'||policyname||'.'||coalesce(cmd,'')||'.'||coalesce(array_to_string(roles,','),'')||'.'||coalesce(qual,'')||'.'||coalesce(with_check,'')||'.'||permissive x
  from pg_policies where schemaname in (select s from app)) t
union all
select 'rls_flags', md5(string_agg(x, '|' order by x)) from (
  select n.nspname||'.'||c.relname||'.'||c.relrowsecurity||'.'||c.relforcerowsecurity x
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname in (select s from app) and c.relkind in ('r','p')) t
union all
select 'grants_tabelas', md5(string_agg(x, '|' order by x)) from (
  select table_schema||'.'||table_name||'.'||grantee||'.'||privilege_type x
  from information_schema.table_privileges
  where table_schema in (select s from app) and grantee in ('anon','authenticated','service_role')) t
union all
select 'sequencias', md5(string_agg(x, '|' order by x)) from (
  select schemaname||'.'||sequencename||'.'||data_type::text||'.'||increment_by||'.'||coalesce(cycle::text,'') x
  from pg_sequences where schemaname in (select s from app)) t;
