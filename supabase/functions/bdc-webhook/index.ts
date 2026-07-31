/**
 * Edge Function: bdc-webhook
 *
 * Recebe callbacks assíncronos do BigDataCorp para datasets ondemand
 * (PGFN, Débitos Estaduais, CNJ, etc.) e converte em alertas Subradar.
 *
 * URL pública: https://redggdtakzmsabwvjzhb.supabase.co/functions/v1/bdc-webhook
 * Passar como NotificationUrl nas queries BDC.
 *
 * Segurança: header BDC_WEBHOOK_SECRET deve bater com env var homônima.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("BDC_WEBHOOK_SECRET") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ── Parsers por dataset ───────────────────────────────────────────────────────

type Alerta = {
  fonte: string;
  categoria: string;
  severidade: "critico" | "atencao" | "info" | "ok";
  titulo: string;
  descricao: string;
  url_fonte?: string;
  referencia_id?: string;
  metadados?: Record<string, unknown>;
};

function parsePGFN(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandPgfn"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["certidao_negativa"];
  const tipo = String(d["Tipo"] ?? d["tipo"] ?? "");
  if (negativa === true || tipo.toLowerCase().includes("negativa")) return [];
  return [{
    fonte: "pgfn",
    categoria: "fiscal",
    severidade: "atencao",
    titulo: `PGFN — certidão positiva: ${cnpj}`,
    descricao: `Débitos junto à PGFN/RFB. Tipo: ${tipo || "Positiva"}.`,
    url_fonte: "https://solucoes.receita.fazenda.gov.br/Servicos/certidaointernet/PJ/Emitir",
    referencia_id: `bdc-pgfn-${cnpj}`,
    metadados: { tipo, raw: d },
  }];
}

function parseDebitosEstaduais(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandDebitosEstaduaisNegativa"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["certidao_negativa"] ?? d["Negativa"];
  const uf = String(d["UF"] ?? d["uf"] ?? "");
  const situacao = String(d["Situacao"] ?? d["situacao"] ?? "");
  if (negativa === true) return [];
  const irregular = ["positiva", "irregular", "pendente", "devedor"]
    .some(k => situacao.toLowerCase().includes(k));
  if (!irregular && negativa !== false) return [];
  return [{
    fonte: "sefaz_estadual",
    categoria: "fiscal",
    severidade: "atencao",
    titulo: `SEFAZ${uf ? `-${uf}` : ""} — débito estadual: ${cnpj}`,
    descricao: `Pendência fiscal estadual${uf ? ` em ${uf}` : ""}. Situação: ${situacao || "irregular"}.`,
    referencia_id: `bdc-sefaz-${uf}-${cnpj}`,
    metadados: { uf, situacao, raw: d },
  }];
}

function parseCNJNegativa(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandCnjNegativa"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["certidao_negativa"] ?? d["Negativa"];
  if (negativa === true) return [];
  const total = Number(d["TotalProcessos"] ?? d["total_processos"] ?? 0);
  if (!total && negativa !== false) return [];
  return [{
    fonte: "datajud",
    categoria: "judicial",
    severidade: "atencao",
    titulo: `CNJ — processos judiciais: ${cnpj}`,
    descricao: `${total || "Processos"} encontrado(s) no CNJ para o CNPJ/CPF.`,
    url_fonte: "https://www.cnj.jus.br",
    referencia_id: `bdc-cnj-${cnpj}`,
    metadados: { total_processos: total, raw: d },
  }];
}

function parseDebitosTrabalhistas(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandDebitosTrabalhistasNegativa"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["Negativa"];
  if (negativa === true) return [];
  if (negativa !== false) return [];
  return [{
    fonte: "cndt_tst_pj",
    categoria: "trabalhista",
    severidade: "atencao",
    titulo: `CNDT/TST — débitos trabalhistas: ${cnpj}`,
    descricao: "Débitos trabalhistas confirmados junto ao TST.",
    url_fonte: "https://cndt.tst.jus.br",
    referencia_id: `bdc-cndt-${cnpj}`,
    metadados: { raw: d },
  }];
}

function parseFGTS(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandFgts"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["Negativa"] ?? d["Regular"];
  if (negativa === true) return [];
  if (negativa !== false) return [];
  return [{
    fonte: "crf_fgts_pj",
    categoria: "trabalhista",
    severidade: "atencao",
    titulo: `FGTS — irregularidade: ${cnpj}`,
    descricao: "Irregularidade junto ao FGTS confirmada.",
    url_fonte: "https://sistemas.caixa.gov.br/sitcrf/publico/consultarCrf.asp",
    referencia_id: `bdc-fgts-${cnpj}`,
    metadados: { raw: d },
  }];
}

function parseIbama(dataset: string, data: Record<string, unknown>, cnpj: string): Alerta[] {
  const key = dataset === "ondemand_ibama_embargos"
    ? "OndemandIbamaEmbargos"
    : dataset === "ondemand_ibama_regulatoria"
    ? "OndemandIbamaRegulatoria"
    : "OndemandIbamaNegativa";
  const d = (data[key] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["Negativa"] ?? d["Regular"];
  if (negativa === true) return [];
  const embargos = d["TotalEmbargos"] ?? d["total_embargos"] ?? 0;
  if (!embargos && negativa !== false) return [];
  const subtipo = dataset.replace("ondemand_ibama_", "");
  return [{
    fonte: "ibama",
    categoria: "ambiental",
    severidade: subtipo === "embargos" ? "critico" : "atencao",
    titulo: `IBAMA ${subtipo} — ocorrência: ${cnpj}`,
    descricao: `Ocorrência IBAMA (${subtipo}) para o CNPJ/CPF. ${embargos ? `Embargos: ${embargos}.` : ""}`,
    url_fonte: "https://servicos.ibama.gov.br/ctf/publico/areasembargadas/ConsultarAreasEmbargadas.php",
    referencia_id: `bdc-ibama-${subtipo}-${cnpj}`,
    metadados: { subtipo, total_embargos: embargos, raw: d },
  }];
}

function parseCGU(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandCguNegativa"] ?? data["OndemandCguCorreicionalNegativa"] ?? data) as Record<string, unknown>;
  const negativa = d["CertidaoNegativa"] ?? d["Negativa"];
  if (negativa === true) return [];
  if (negativa !== false) return [];
  return [{
    fonte: "ceis",
    categoria: "sancoes",
    severidade: "critico",
    titulo: `CGU — sanção administrativa: ${cnpj}`,
    descricao: "Sanção administrativa CGU confirmada.",
    url_fonte: "https://portaldatransparencia.gov.br/sancoes",
    referencia_id: `bdc-cgu-${cnpj}`,
    metadados: { raw: d },
  }];
}

function parseAcoesTrabalhistas(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandAcoesTrabalhistas"] ?? data) as Record<string, unknown>;
  const total = Number(d["TotalAcoes"] ?? d["total_acoes"] ?? 0);
  if (!total) return [];
  return [{
    fonte: "cndt_tst_pj",
    categoria: "trabalhista",
    severidade: "atencao",
    titulo: `Ações Trabalhistas — ${total} ação(ões): ${cnpj}`,
    descricao: `${total} ação(ões) trabalhista(s) encontrada(s).`,
    referencia_id: `bdc-acoes-trab-${cnpj}`,
    metadados: { total_acoes: total, raw: d },
  }];
}

function parseAcoesJudiciais(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandAcoesJudiciaisNadaConsta"] ?? data) as Record<string, unknown>;
  const negativa = d["NadaConsta"] ?? d["Negativa"];
  if (negativa === true) return [];
  const total = Number(d["TotalAcoes"] ?? 0);
  if (!total && negativa !== false) return [];
  return [{
    fonte: "datajud",
    categoria: "judicial",
    severidade: "atencao",
    titulo: `Ações Judiciais — ocorrência: ${cnpj}`,
    descricao: `${total || "Ações"} judiciais encontrada(s).`,
    referencia_id: `bdc-acoes-jud-${cnpj}`,
    metadados: { total_acoes: total, raw: d },
  }];
}

function parseCOMPROT(data: Record<string, unknown>, cnpj: string): Alerta[] {
  const d = (data["OndemandComprot"] ?? data) as Record<string, unknown>;
  const total = Number(d["TotalProcessos"] ?? d["total"] ?? 0);
  if (!total) return [];
  return [{
    fonte: "comprot",
    categoria: "regulatorio",
    severidade: "info",
    titulo: `COMPROT — ${total} processo(s): ${cnpj}`,
    descricao: `${total} processo(s) no COMPROT (processos governo federal).`,
    referencia_id: `bdc-comprot-${cnpj}`,
    metadados: { total_processos: total, raw: d },
  }];
}

// PF exclusivos
function parsePoliciaFederal(data: Record<string, unknown>, cpf: string): Alerta[] {
  const d = (data["OndemandPoliciaFederalAntecedentesCriminais"] ?? data) as Record<string, unknown>;
  const negativa = d["NadaConsta"] ?? d["Negativa"];
  if (negativa === true) return [];
  const total = Number(d["TotalOcorrencias"] ?? 0);
  if (!total && negativa !== false) return [];
  return [{
    fonte: "policia_federal_pf",
    categoria: "criminal",
    severidade: "critico",
    titulo: `PF — antecedentes criminais: ${cpf}`,
    descricao: `Antecedentes criminais encontrados na Polícia Federal.`,
    referencia_id: `bdc-pf-antecedentes-${cpf}`,
    metadados: { total_ocorrencias: total, raw: d },
  }];
}

function parseBACEN(data: Record<string, unknown>, cpf: string): Alerta[] {
  const d = (data["OndemandBacenSancoesAdministrativas"] ?? data) as Record<string, unknown>;
  const total = Number(d["TotalSancoes"] ?? 0);
  if (!total) return [];
  return [{
    fonte: "bacen",
    categoria: "financeiro",
    severidade: "critico",
    titulo: `BACEN — sanção administrativa: ${cpf}`,
    descricao: `${total} sanção(ões) administrativa(s) do BACEN.`,
    referencia_id: `bdc-bacen-${cpf}`,
    metadados: { total_sancoes: total, raw: d },
  }];
}

function parseTSE(data: Record<string, unknown>, cpf: string): Alerta[] {
  const d = (data["OndemandTseQuitacaoEleitoral"] ?? data) as Record<string, unknown>;
  const quite = d["Quite"] ?? d["quite"] ?? d["QuitacaoEleitoral"];
  if (quite === true) return [];
  if (quite !== false) return [];
  return [{
    fonte: "tse_situacao_pf",
    categoria: "eleitoral",
    severidade: "info",
    titulo: `TSE — pendência eleitoral: ${cpf}`,
    descricao: "Quitação eleitoral pendente junto ao TSE.",
    referencia_id: `bdc-tse-${cpf}`,
    metadados: { raw: d },
  }];
}

// ── Dispatcher principal ──────────────────────────────────────────────────────

function parseDataset(
  dataset: string,
  data: Record<string, unknown>,
  doc: string,
): Alerta[] {
  switch (dataset) {
    case "ondemand_pgfn":                       return parsePGFN(data, doc);
    case "ondemand_debitos_estaduais_negativa":  return parseDebitosEstaduais(data, doc);
    case "ondemand_cnj_negativa":               return parseCNJNegativa(data, doc);
    case "ondemand_debitos_trabalhistas_negativa": return parseDebitosTrabalhistas(data, doc);
    case "ondemand_fgts":                       return parseFGTS(data, doc);
    case "ondemand_ibama_embargos":
    case "ondemand_ibama_negativa":
    case "ondemand_ibama_regulatoria":          return parseIbama(dataset, data, doc);
    case "ondemand_cgu_negativa":
    case "ondemand_cgu_correcional_negativa":   return parseCGU(data, doc);
    case "ondemand_acoes_trabalhistas":         return parseAcoesTrabalhistas(data, doc);
    case "ondemand_acoes_judiciais_nada_consta": return parseAcoesJudiciais(data, doc);
    case "ondemand_comprot":                    return parseCOMPROT(data, doc);
    case "ondemand_policia_federal_antecedentes_criminais": return parsePoliciaFederal(data, doc);
    case "ondemand_bacen_sancoes_administrativas": return parseBACEN(data, doc);
    case "ondemand_tse_quitacao_eleitoral":     return parseTSE(data, doc);
    default:
      console.warn("bdc-webhook: dataset sem parser:", dataset);
      return [];
  }
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // Verificação de segredo
  const secret = req.headers.get("X-BDC-Secret") ?? req.headers.get("Authorization") ?? "";
  if (WEBHOOK_SECRET && secret !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response("Bad Request", { status: 400 });
  }

  // Extrai queryId do payload BDC
  const queryIdRaw = String(
    body["QueryId"] ?? body["queryid"] ?? body["MatchKeys"] ?? ""
  ).replace("queryid{", "").replace("}", "");

  if (!queryIdRaw) {
    console.error("bdc-webhook: queryId ausente no payload");
    return new Response("missing queryId", { status: 400 });
  }

  // Busca o registro da query no banco
  const { data: queryRow, error: qErr } = await supabase
    .from("sub_bdc_queries")
    .select("id, dossie_id, cnpj, dataset, status")
    .eq("query_id", queryIdRaw)
    .single();

  if (qErr || !queryRow) {
    console.warn("bdc-webhook: queryId não encontrado:", queryIdRaw);
    // Retorna 200 para o BDC não retentar infinitamente
    return new Response("query not found", { status: 200 });
  }

  if (queryRow.status === "processed") {
    return new Response("already processed", { status: 200 });
  }

  // Marca como recebido
  await supabase.from("sub_bdc_queries").update({
    status: "received",
    payload: body,
    received_at: new Date().toISOString(),
  }).eq("id", queryRow.id);

  // Busca contexto: tenta sub_dossies (PJ) e depois sub_pf_resultados (PF)
  let entityId = queryRow.dossie_id;
  let entityDoc = queryRow.cnpj;

  const { data: dossie } = await supabase
    .from("sub_dossies")
    .select("id, cnpj")
    .eq("id", queryRow.dossie_id)
    .maybeSingle();

  if (!dossie) {
    // Tenta como resultado PF
    const { data: pfRow } = await supabase
      .from("sub_pf_resultados")
      .select("id, cpf")
      .eq("id", queryRow.dossie_id)
      .maybeSingle();

    if (!pfRow) {
      // Não encontrado em nenhuma tabela — ainda assim processa para não perder o dado
      console.warn("bdc-webhook: dossie_id não encontrado em sub_dossies nem sub_pf_resultados:", queryRow.dossie_id);
    } else {
      entityId = pfRow.id;
      entityDoc = pfRow.cpf ?? queryRow.cnpj;
    }
  }

  // Parseia dataset → alertas
  const data = (body["Result"] ?? body["Data"] ?? body) as Record<string, unknown>;
  const alertas = parseDataset(queryRow.dataset, data, entityDoc);

  // Insere alertas
  let alertasCriados = 0;
  if (alertas.length > 0) {
    const rows = alertas.map((a) => ({
      ...a,
      dossie_id: entityId,
      cnpj: entityDoc,
      is_novo: true,
    }));
    const { error: insErr } = await supabase.from("sub_alertas").upsert(rows, {
      onConflict: "dossie_id,referencia_id",
      ignoreDuplicates: false,
    });
    if (!insErr) alertasCriados = rows.length;
    else console.error("bdc-webhook: erro ao inserir alertas:", insErr.message);
  }

  // Marca como processado
  await supabase.from("sub_bdc_queries").update({
    status: "processed",
    alertas_criados: alertasCriados,
    processed_at: new Date().toISOString(),
  }).eq("id", queryRow.id);

  console.log(`bdc-webhook: ${queryRow.dataset} → ${alertasCriados} alertas | dossie=${dossie.id}`);
  return new Response(JSON.stringify({ ok: true, alertas: alertasCriados }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
