import logging
import uuid
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv

# Precisa rodar antes de qualquer import de ingestao.subradar.* — esses módulos lêem
# SUPABASE_URL/SUPABASE_KEY de os.environ na hora do import (não sob demanda), então
# se o .env ainda não foi carregado nesse ponto, os módulos ficam com valores vazios
# "congelados" pro resto do processo.
load_dotenv()

logger = logging.getLogger("subradar.handler")
# O runtime da Lambda já anexa um handler ao root logger antes do código do
# usuário rodar, então logging.basicConfig() vira no-op (só configura se não
# houver handlers ainda) — os logger.info() de todo o pacote ficavam mudos.
# setLevel funciona independente de handlers já existirem.
logging.getLogger().setLevel(logging.INFO)

# Vários conectores fazem requests.get/post sem timeout= — sem isso, uma fonte
# fora do ar trava o worker indefinidamente. Injeta um timeout padrão em toda
# chamada que não especificar um, inclusive via requests.Session() customizada.
_ORIG_SESSION_REQUEST = requests.Session.request


def _request_with_default_timeout(self, method, url, **kwargs):
    kwargs.setdefault("timeout", 15)
    return _ORIG_SESSION_REQUEST(self, method, url, **kwargs)


requests.Session.request = _request_with_default_timeout

# ~25 dos 35 conectores herdam de SubradarSource, que passa timeout=30 (+ até 3
# retries) explicitamente em toda chamada — isso ignora o setdefault acima e pode
# custar até ~90s por fonte fora do ar. SubradarSource é usada por ~86 arquivos em
# vários pipelines, então não mexemos no valor default da classe (base.py); só
# reduzimos aqui, em runtime, dentro deste processo Lambda, sem tocar no código-fonte.
from ingestao.subradar.base import SubradarSource

SubradarSource.timeout = 8

from mangum import Mangum

from api_subradar import app

_api_handler = Mangum(app)


def handler(event, context):
    if isinstance(event, dict) and event.get("job_type") == "subradar_pf_consulta":
        return _run_worker(event)
    return _api_handler(event, context)


def _run_worker(event: dict) -> dict:
    from ingestao.subradar.base import patch
    from ingestao.subradar.runner_pf import processar_cpf

    consulta_id = event["consulta_id"]
    cpf = event["cpf"]
    nome = event.get("nome", "")
    # "completa" (paga) roda FONTES_PF_AVULSA (inclui fontes pagas); "simples"
    # roda só FONTES_PF (gratuitas). Ver ingestao/subradar/runner_pf.py.
    avulsa = event.get("tipo") == "completa"
    try:
        cliente_id = str(uuid.UUID(str(event.get("cliente_id", ""))))
    except (ValueError, TypeError, AttributeError):
        # cliente_id do request não é um UUID válido (ex: "default") — sub_pf_resultados
        # e sub_pf_dados exigem uuid, então cai pro id da própria consulta.
        cliente_id = consulta_id

    ciclo = datetime.now(timezone.utc).strftime("%Y-%m")
    resultado_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{cpf}-{ciclo}"))

    patch("sub_pf_consultas", {"id": consulta_id}, {"status": "processando"})
    logger.info("Worker iniciado: consulta_id=%s cpf=%s avulsa=%s", consulta_id, cpf, avulsa)

    try:
        processar_cpf(cpf=cpf, cliente_id=cliente_id, nome=nome, dry_run=False, avulsa=avulsa)
        patch("sub_pf_consultas", {"id": consulta_id}, {
            "status": "concluida",
            "resultado_id": resultado_id,
        })
        logger.info("Worker concluído: consulta_id=%s", consulta_id)
    except Exception as e:
        logger.exception("Worker falhou: consulta_id=%s", consulta_id)
        patch("sub_pf_consultas", {"id": consulta_id}, {
            "status": "erro",
            "erro": str(e)[:500],
        })

    return {"status": "ok", "consulta_id": consulta_id}
