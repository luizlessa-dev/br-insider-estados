-- bloco 11_triggers — gerado por split_baseline.py (ordem interna = ordem do dump)
CREATE OR REPLACE TRIGGER "trg_cases_updated_at" BEFORE UPDATE ON "cidadania_ai"."cases" FOR EACH ROW EXECUTE FUNCTION "cidadania_ai"."set_updated_at"();

CREATE OR REPLACE TRIGGER "trg_library_docs_updated_at" BEFORE UPDATE ON "cidadania_ai"."library_docs" FOR EACH ROW EXECUTE FUNCTION "cidadania_ai"."set_updated_at"();

CREATE OR REPLACE TRIGGER "trg_set_cnpjs_limit" BEFORE INSERT OR UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_cnpjs_limit"();
