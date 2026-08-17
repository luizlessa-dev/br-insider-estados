# WIP — Roadmap "5 Novas Fontes" (não está em produção)

Estes 4 arquivos **não são usados em produção**. A versão de produção do Subradar PF é
`ingestao/subradar/runner_pf.py` (36 fontes, "Enterprise"), chamada por:

- `runner_pf_api.py` → API Lambda assíncrona disparada por `subradar-web/app/api/pf/submit`
- `.github/workflows/subradar-pf-runner.yml` (fallback manual)

## O que tem aqui

Cadeia incremental construída em 08/2026 seguindo `ROADMAP_5_NOVAS_FONTES.md` (raiz do repo),
um plano de 4 dias pra adicionar 5 fontes novas ao Subradar PF. O checklist do Dia 4
("Deploy em staging" / "Deploy") nunca foi marcado — o trabalho parou no Dia 3, nenhuma
dessas fontes chegou a `runner_pf.py`.

```
runner_pf_extended.py        + CNPI, CCF, RENAJUD (3 fontes gratuitas)
  → runner_pf_extended_v2.py + Cartório de Imóveis (Cofiex, paga)
    → runner_pf_complete.py  + SERASA Score (paga)
      → runner_pf_complete_final.py + BDC Negativações/Protestos (já em runner_pf.py hoje)
```

Cada arquivo importa o anterior e soma 1-2 fontes — nenhum é standalone.

## Status por fonte (2026-08-17)

| Fonte | Custo | Credencial nos secrets? | Status |
|---|---|---|---|
| CNPI (Banco Central) | Gratuita | — | Não integrada em produção |
| CCF (Cheque Sem Fundo) | Gratuita | — | Não integrada em produção |
| Alienação RENAJUD | Gratuita | — | Não integrada em produção |
| Cartório de Imóveis (Cofiex) | ~R$5/consulta | `COFIEX_API_KEY`/`COFIEX_CERT_PATH` ausentes | Não integrada, sem credencial |
| SERASA Score | ~R$100-200/consulta | `SERASA_API_KEY`/`SERASA_CLIENT_ID`/`SERASA_CLIENT_SECRET` ausentes | Não integrada, sem credencial |
| BDC Negativações | — | Configurada (`BIGDATA_CORP_*`) | Já em produção via `runner_pf.py` |
| Protestos Nacional | Pay-per-use | Configurada (`DIRECT_DATA_TOKEN`) | Já em produção via `runner_pf.py` |

## Se for retomar

As 3 fontes gratuitas (CNPI/CCF/RENAJUD) são as mais baratas de terminar — sem
dependência de credencial nova. Cofiex e SERASA exigem contratar acesso antes de
fazer sentido integrar.

Pra promover: portar os `Connector()` relevantes pra lista `FONTES_PF` em
`../runner_pf.py`, não continuar essa cadeia de arquivos.
