#!/usr/bin/env node
/**
 * BR Insider — Análise de Grupo Empresarial
 * ==========================================
 * Dado um conjunto de CNPJs de um grupo econômico, consolida:
 *   1. Cota parlamentar (CEAP) — quanto o grupo recebe de deputados, por tipo
 *   2. Emendas parlamentares — quanto o grupo recebeu e de quem
 *   3. Contratos PNCP — quanto o grupo tem em contratos federais de publicidade
 *   4. TSE Receitas — quanto o grupo doou para campanhas (pré-2017)
 *
 * Uso:
 *   node scripts/grupo-empresarial.mjs --cnpjs 03585183 07154355 --nome "FSB"
 *   node scripts/grupo-empresarial.mjs --cnpjs 03585183000142 07154355000265 --nome "FSB"
 *   node scripts/grupo-empresarial.mjs --arquivo cnpjs-fsb.txt --nome "FSB"
 *
 * CNPJs aceitos com ou sem sufixo (8 ou 14 dígitos). Zeros à esquerda preservados.
 *
 * Saída: console + JSON em dados/grupo_<nome>_<data>.json
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dir = dirname(fileURLToPath(import.meta.url))
const ROOT  = resolve(__dir, '..')

// ── Config ────────────────────────────────────────────────────────────────────

const SUPABASE_URL = process.env.SUPABASE_URL?.replace(/\/$/, '')
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY
  || process.env.INTERNAL_SUPABASE_SERVICE_ROLE_KEY

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Faltam SUPABASE_URL e/ou SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

const HEADERS = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  'Content-Type': 'application/json',
}

// ── Args ──────────────────────────────────────────────────────────────────────

function parseArgs() {
  const argv = process.argv.slice(2)
  const get  = (flag) => {
    const i = argv.indexOf(flag)
    return i >= 0 ? argv[i + 1] : null
  }
  const getMulti = (flag) => {
    const results = []
    for (let i = 0; i < argv.length; i++) {
      if (argv[i] === flag) results.push(argv[i + 1])
    }
    return results
  }

  // --cnpjs A B C ... (todos os valores até o próximo flag)
  let cnpjs = []
  const idx = argv.indexOf('--cnpjs')
  if (idx >= 0) {
    let j = idx + 1
    while (j < argv.length && !argv[j].startsWith('--')) {
      cnpjs.push(argv[j++])
    }
  }

  const arquivo = get('--arquivo')
  if (arquivo) {
    const raw = readFileSync(arquivo, 'utf8')
    cnpjs = [...cnpjs, ...raw.split(/\s+/).filter(Boolean)]
  }

  const nome = get('--nome') || 'grupo'

  if (!cnpjs.length) {
    console.error('Passe ao menos um CNPJ com --cnpjs XXXXXXXX [YYYYYYYY ...]')
    process.exit(1)
  }

  return { cnpjs: normalizarCNPJs(cnpjs), nome }
}

function normalizarCNPJs(lista) {
  return lista.map(c => {
    const digits = c.replace(/\D/g, '')
    if (digits.length === 8) return digits          // só basico — expandir depois
    if (digits.length === 14) return digits
    console.warn(`CNPJ ignorado (tamanho inválido): ${c}`)
    return null
  }).filter(Boolean)
}

// Retorna tanto o basico (8 dígitos) quanto o completo (14 dígitos)
function cnpjBasicos(lista) {
  return [...new Set(lista.map(c => c.slice(0, 8)))]
}

function cnpjCompletos(lista) {
  // se o usuário passou só basico (8 dígitos), retorna o basico para ILIKE
  return lista
}

// ── Supabase RPC ──────────────────────────────────────────────────────────────

async function sql(query) {
  const resp = await fetch(`${SUPABASE_URL}/rest/v1/rpc/execute_sql`, {
    method: 'POST',
    headers: HEADERS,
    body: JSON.stringify({ query }),
  })
  if (!resp.ok) {
    const err = await resp.text()
    throw new Error(`SQL error: ${err}`)
  }
  const data = await resp.json()
  return data?.result ?? data
}

// Fallback: PostgREST direto para queries simples
async function pgrest(table, params) {
  const url = new URL(`${SUPABASE_URL}/rest/v1/${table}`)
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v))
  const resp = await fetch(url, { headers: { ...HEADERS, Prefer: 'count=exact' } })
  if (!resp.ok) throw new Error(`PostgREST error ${resp.status}: ${await resp.text()}`)
  return resp.json()
}

// ── Queries ───────────────────────────────────────────────────────────────────

async function resolverCNPJsCompletos(basicos) {
  // Descobre os CNPJs de 14 dígitos que existem na cota para cada basico
  const conds = basicos.map(b => `cnpj_norm >= '${b}0000000' AND cnpj_norm <= '${b}9999999'`).join(' OR ')
  const query = `SELECT DISTINCT cnpj_norm FROM cota_despesa WHERE ${conds} LIMIT 100`
  const rows = await sql(query).catch(() => [])
  return rows.map(r => r.cnpj_norm).filter(Boolean)
}

async function analisarCota(cnpjsCompletos, cnpjsBasicos) {
  // Usar range numérico (usa índice b-tree) em vez de LIKE
  let todos14 = cnpjsCompletos.filter(c => c.length === 14)
  if (!todos14.length) {
    todos14 = await resolverCNPJsCompletos(cnpjsBasicos)
  } else {
    // Complementar com os do banco para cobrir filiais não mapeadas
    const extras = await resolverCNPJsCompletos(cnpjsBasicos)
    todos14 = [...new Set([...todos14, ...extras])]
  }

  if (!todos14.length) return []

  const lista = todos14.map(c => `'${c}'`).join(', ')
  const query = `
    SELECT
      cd.nome                          AS deputado,
      cd.partido,
      cd.uf,
      c.tipo_despesa,
      MAX(c.nome_fornecedor)           AS nome_fornecedor,
      c.cnpj_norm,
      SUM(c.valor_liquido)             AS total,
      COUNT(*)                         AS n_notas,
      MIN(c.data_emissao)              AS primeira,
      MAX(c.data_emissao)              AS ultima
    FROM cota_despesa c
    JOIN cota_deputado cd ON cd.id_camara = c.id_deputado
    WHERE c.cnpj_norm IN (${lista})
    GROUP BY cd.nome, cd.partido, cd.uf, c.tipo_despesa, c.cnpj_norm
    ORDER BY total DESC
  `
  return sql(query)
}

async function analisarEmendas(cnpjsCompletos, cnpjsBasicos) {
  const conditions = [
    ...cnpjsCompletos.filter(c => c.length === 14).map(c => `ef.codigo_favorecido = '${c}'`),
    ...cnpjsBasicos.map(b => `ef.codigo_favorecido LIKE '${b}%'`),
  ].join(' OR ')

  const query = `
    SELECT
      ef.codigo_favorecido             AS cnpj,
      ef.favorecido,
      ef.nome_autor,
      ef.codigo_autor,
      ef.tipo_emenda,
      ef.ano_emenda,
      ef.uf_favorecido,
      SUM(ef.valor_recebido::numeric)  AS total,
      COUNT(*)                         AS n_pagamentos
    FROM emendas_favorecidos ef
    WHERE ${conditions}
    GROUP BY ef.codigo_favorecido, ef.favorecido, ef.nome_autor, ef.codigo_autor,
             ef.tipo_emenda, ef.ano_emenda, ef.uf_favorecido
    ORDER BY total DESC
  `
  return sql(query)
}

async function analisarPNCP(cnpjsBasicos) {
  const conditions = cnpjsBasicos.map(b => `cnpj_fornecedor LIKE '${b}%'`).join(' OR ')
  const query = `
    SELECT
      cnpj_fornecedor,
      nome_fornecedor,
      nome_orgao,
      uf_orgao,
      ano_contrato,
      SUM(valor_global)                AS total,
      COUNT(*)                         AS n_contratos,
      STRING_AGG(DISTINCT objeto_contrato, ' || ' ORDER BY objeto_contrato) AS objetos_amostra
    FROM pncp_publicidade
    WHERE ${conditions}
    GROUP BY cnpj_fornecedor, nome_fornecedor, nome_orgao, uf_orgao, ano_contrato
    ORDER BY total DESC
  `
  return sql(query).catch(() => []) // tabela pode estar vazia
}

async function analisarTSE(cnpjsBasicos) {
  const conditions = cnpjsBasicos.map(b => `r.cpf_cnpj_doador LIKE '${b}%'`).join(' OR ')
  const query = `
    SELECT
      r.cpf_cnpj_doador               AS cnpj,
      r.nome_doador,
      r.ano_eleicao,
      r.nome_candidato,
      r.cargo,
      r.sigla_partido,
      SUM(r.valor)                    AS total_doado,
      COUNT(*)                        AS n_transacoes
    FROM tse_receitas r
    WHERE ${conditions}
    GROUP BY r.cpf_cnpj_doador, r.nome_doador, r.ano_eleicao,
             r.nome_candidato, r.cargo, r.sigla_partido
    ORDER BY total_doado DESC
  `
  return sql(query).catch(() => [])
}

async function analisarCadastro(cnpjsBasicos) {
  const conditions = cnpjsBasicos.map(b => `cnpj_basico = '${b}'`).join(' OR ')
  const query = `
    SELECT cnpj_basico, razao_social, natureza_juridica, capital_social, porte_empresa
    FROM cnpj_empresas
    WHERE ${conditions}
  `
  return sql(query).catch(() => [])
}

// ── Sumarização ───────────────────────────────────────────────────────────────

function sumarizar(dados) {
  const { cota, emendas, pncp, tse, cadastro } = dados

  const totalCota    = cota.reduce((s, r) => s + Number(r.total || 0), 0)
  const totalEmendas = emendas.reduce((s, r) => s + Number(r.total || 0), 0)
  const totalPNCP    = pncp.reduce((s, r) => s + Number(r.total || 0), 0)
  const totalTSE     = tse.reduce((s, r) => s + Number(r.total_doado || 0), 0)

  const depsCota = [...new Set(cota.map(r => r.deputado))].filter(Boolean)
  const autoresEmenda = [...new Set(emendas.map(r => r.nome_autor))].filter(Boolean)

  const cotaPorTipo = {}
  for (const r of cota) {
    cotaPorTipo[r.tipo_despesa] = (cotaPorTipo[r.tipo_despesa] || 0) + Number(r.total || 0)
  }

  const emendaPorAno = {}
  for (const r of emendas) {
    emendaPorAno[r.ano_emenda] = (emendaPorAno[r.ano_emenda] || 0) + Number(r.total || 0)
  }

  return {
    resumo: {
      total_cota_brl:    totalCota,
      total_emendas_brl: totalEmendas,
      total_pncp_brl:    totalPNCP,
      total_tse_doado:   totalTSE,
      total_geral:       totalCota + totalEmendas + totalPNCP,
      n_deputados_pagantes: depsCota.length,
      n_autores_emenda:     autoresEmenda.length,
    },
    cota_por_tipo:     cotaPorTipo,
    emenda_por_ano:    emendaPorAno,
    deputados_cota:    depsCota,
    autores_emenda:    autoresEmenda,
    cadastro,
  }
}

function fmt(n) {
  return `R$ ${Number(n).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`
}

function imprimir(nome, resumo, dados) {
  const { r } = { r: resumo.resumo }
  console.log(`\n${'='.repeat(60)}`)
  console.log(`  GRUPO: ${nome.toUpperCase()}`)
  console.log('='.repeat(60))

  if (resumo.cadastro?.length) {
    console.log('\n── Cadastro RFB ──────────────────────────────────────────')
    for (const e of resumo.cadastro) {
      console.log(`  ${e.cnpj_basico}  ${e.razao_social}  (${e.natureza_juridica}, ${e.porte_empresa})`)
    }
  }

  console.log('\n── Totais consolidados ───────────────────────────────────')
  console.log(`  Cota parlamentar (CEAP):  ${fmt(r.total_cota_brl)}`)
  console.log(`  Emendas parlamentares:    ${fmt(r.total_emendas_brl)}`)
  console.log(`  Contratos PNCP pub.:      ${fmt(r.total_pncp_brl)}`)
  console.log(`  Doações TSE (pré-2017):   ${fmt(r.total_tse_doado)}`)
  console.log(`  ─────────────────────────────────────────────`)
  console.log(`  TOTAL (cota+emendas+PNCP): ${fmt(r.total_geral)}`)

  console.log('\n── Cota por tipo de despesa ──────────────────────────────')
  for (const [tipo, val] of Object.entries(resumo.cota_por_tipo).sort((a,b) => b[1]-a[1])) {
    console.log(`  ${fmt(val).padStart(20)}  ${tipo}`)
  }

  if (Object.keys(resumo.emenda_por_ano).length) {
    console.log('\n── Emendas por ano ───────────────────────────────────────')
    for (const [ano, val] of Object.entries(resumo.emenda_por_ano).sort()) {
      console.log(`  ${ano}: ${fmt(val)}`)
    }
  }

  console.log('\n── Deputados que pagaram via cota ────────────────────────')
  resumo.deputados_cota.forEach(d => console.log(`  · ${d}`))

  if (resumo.autores_emenda.length) {
    console.log('\n── Autores de emendas ────────────────────────────────────')
    resumo.autores_emenda.forEach(a => console.log(`  · ${a}`))
  }

  if (dados.pncp?.length) {
    console.log('\n── Contratos PNCP publicidade ────────────────────────────')
    for (const p of dados.pncp.slice(0, 10)) {
      console.log(`  ${fmt(p.total).padStart(20)}  ${p.nome_orgao} (${p.uf_orgao}, ${p.ano_contrato})`)
    }
  }

  if (dados.tse?.length) {
    console.log('\n── Doações para campanhas (TSE) ──────────────────────────')
    for (const t of dados.tse.slice(0, 10)) {
      console.log(`  ${fmt(t.total_doado).padStart(20)}  ${t.nome_candidato} (${t.sigla_partido}, ${t.ano_eleicao})`)
    }
  }

  console.log('')
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const { cnpjs, nome } = parseArgs()
  const basicos = cnpjBasicos(cnpjs)

  console.log(`\nAnalisando grupo "${nome}"`)
  console.log(`CNPJs: ${cnpjs.join(', ')}`)
  console.log(`Basicos: ${basicos.join(', ')}`)

  const [cota, emendas, pncp, tse, cadastro] = await Promise.all([
    analisarCota(cnpjs, basicos).catch(e => { console.warn('Cota:', e.message); return [] }),
    analisarEmendas(cnpjs, basicos).catch(e => { console.warn('Emendas:', e.message); return [] }),
    analisarPNCP(basicos).catch(e => { console.warn('PNCP:', e.message); return [] }),
    analisarTSE(basicos).catch(e => { console.warn('TSE:', e.message); return [] }),
    analisarCadastro(basicos).catch(e => { console.warn('Cadastro:', e.message); return [] }),
  ])

  const dados = { cota, emendas, pncp, tse, cadastro }
  const resumo = sumarizar(dados)

  imprimir(nome, resumo, dados)

  // Salvar JSON
  const data = new Date().toISOString().slice(0, 10)
  const nomeArq = nome.toLowerCase().replace(/\s+/g, '_')
  const saida = resolve(ROOT, 'dados', `grupo_${nomeArq}_${data}.json`)
  mkdirSync(resolve(ROOT, 'dados'), { recursive: true })
  writeFileSync(saida, JSON.stringify({ cnpjs, basicos, resumo, dados }, null, 2))
  console.log(`JSON salvo: ${saida}`)
}

main().catch(err => { console.error(err); process.exit(1) })
