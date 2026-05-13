SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'broker_accounts', 'terminal_sessions')
ORDER BY table_name;

SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('users', 'broker_accounts', 'terminal_sessions')
ORDER BY table_name, ordinal_position;