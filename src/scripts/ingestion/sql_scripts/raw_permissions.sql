GRANT USAGE ON SCHEMA "raw" TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA "raw" TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA "raw" TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA "raw" TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "raw" GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "raw" GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "raw" GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;