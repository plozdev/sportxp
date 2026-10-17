-- Read-only diagnostic: run in your existing Supabase SQL Editor.
-- Share results with the developer; no keys or user records are returned.
select table_name, column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('courts', 'profiles', 'match_rooms', 'match_results')
order by table_name, ordinal_position;

select p.proname, pg_get_function_arguments(p.oid) as arguments,
  pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'record_match_and_update_elo';

select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('courts', 'profiles', 'match_rooms', 'match_results');
