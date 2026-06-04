"""
Rastreamento de doadores de campanha TSE.

Uso:
    from dossie.doador import DossieDoador
    d = DossieDoador.from_env()

    # por CPF/CNPJ exato
    relatorio = d.por_cpf_cnpj("02781881686")   # Fabiano Zettel

    # por fragmento de nome (case-insensitive)
    relatorio = d.por_nome("ZETTEL")

    # imprimir relatório em texto
    d.imprimir(relatorio)
"""
from __future__ import annotations

import json
import textwrap
from dataclasses import dataclass, field
from typing import Optional

from .client import SupabaseClient


@dataclass
class DoacaoCampanha:
    ano_eleicao: int
    cpf_cnpj_doador: str
    nome_doador: str
    nome_candidato: str
    cargo: Optional[str]
    sigla_partido: Optional[str]
    uf: Optional[str]
    valor: float
    tipo_doador: Optional[str]
    setor_economico: Optional[str]
    data_receita: Optional[str]
    resultado_eleicao: Optional[str]
    parlamentar_ativo: Optional[bool]
    id_camara: Optional[int]


@dataclass
class RelatorioDossieDoador:
    cpf_cnpj: Optional[str]
    nome_busca: str
    doacoes: list[DoacaoCampanha] = field(default_factory=list)

    @property
    def total_doado(self) -> float:
        return sum(d.valor for d in self.doacoes)

    @property
    def anos(self) -> list[int]:
        return sorted(set(d.ano_eleicao for d in self.doacoes))

    @property
    def receptores_unicos(self) -> list[str]:
        seen = {}
        for d in sorted(self.doacoes, key=lambda x: -x.valor):
            if d.nome_candidato not in seen:
                seen[d.nome_candidato] = d
        return list(seen.keys())

    def por_ano(self, ano: int) -> list[DoacaoCampanha]:
        return [d for d in self.doacoes if d.ano_eleicao == ano]

    def ranking_receptores(self) -> list[dict]:
        totais: dict[str, dict] = {}
        for d in self.doacoes:
            k = d.nome_candidato
            if k not in totais:
                totais[k] = {
                    "nome": d.nome_candidato,
                    "partido": d.sigla_partido,
                    "uf": d.uf,
                    "cargo": d.cargo,
                    "total": 0.0,
                    "n": 0,
                    "anos": set(),
                    "ativo": d.parlamentar_ativo,
                    "id_camara": d.id_camara,
                }
            totais[k]["total"] += d.valor
            totais[k]["n"] += 1
            totais[k]["anos"].add(d.ano_eleicao)
        resultado = sorted(totais.values(), key=lambda x: -x["total"])
        for r in resultado:
            r["anos"] = sorted(r["anos"])
        return resultado


class DossieDoador:
    def __init__(self, client: SupabaseClient) -> None:
        self._client = client

    @classmethod
    def from_env(cls) -> "DossieDoador":
        return cls(SupabaseClient.from_env())

    def _fetch_doacoes(self, params: dict) -> list[DoacaoCampanha]:
        rows = self._client.get_all("tse_v_dossie_doador", params)
        result = []
        for r in rows:
            result.append(DoacaoCampanha(
                ano_eleicao=r.get("ano_eleicao", 0),
                cpf_cnpj_doador=r.get("cpf_cnpj_doador", ""),
                nome_doador=r.get("nome_doador", ""),
                nome_candidato=r.get("nome_candidato", ""),
                cargo=r.get("cargo"),
                sigla_partido=r.get("sigla_partido"),
                uf=r.get("uf"),
                valor=float(r.get("valor") or 0),
                tipo_doador=r.get("tipo_doador"),
                setor_economico=r.get("setor_economico_doador"),
                data_receita=r.get("data_receita"),
                resultado_eleicao=r.get("resultado_eleicao"),
                parlamentar_ativo=r.get("parlamentar_ativo"),
                id_camara=r.get("id_camara"),
            ))
        return result

    def por_cpf_cnpj(self, cpf_cnpj: str) -> RelatorioDossieDoador:
        """Busca todas as doações de um CPF ou CNPJ (apenas dígitos)."""
        digits = "".join(c for c in cpf_cnpj if c.isdigit())
        rows = self._fetch_doacoes({"cpf_cnpj_doador": f"eq.{digits}"})
        nome = rows[0].nome_doador if rows else digits
        return RelatorioDossieDoador(cpf_cnpj=digits, nome_busca=nome, doacoes=rows)

    def por_nome(self, fragmento: str) -> RelatorioDossieDoador:
        """Busca por fragmento de nome (case-insensitive, usa ilike)."""
        rows = self._fetch_doacoes({"nome_doador": f"ilike.*{fragmento}*"})
        return RelatorioDossieDoador(cpf_cnpj=None, nome_busca=fragmento, doacoes=rows)

    def por_nome_originario(self, fragmento: str) -> RelatorioDossieDoador:
        """Busca no campo doador_originario (útil para holdings/grupos empresariais)."""
        rows = self._fetch_doacoes({"nome_doador_originario": f"ilike.*{fragmento}*"})
        return RelatorioDossieDoador(cpf_cnpj=None, nome_busca=fragmento, doacoes=rows)

    @staticmethod
    def imprimir(rel: RelatorioDossieDoador, detalhado: bool = False) -> None:
        """Imprime relatório em texto simples."""
        sep = "=" * 60
        print(sep)
        print(f"DOSSIÊ DOADOR: {rel.nome_busca}")
        if rel.cpf_cnpj:
            print(f"CPF/CNPJ: {rel.cpf_cnpj}")
        print(f"Total doações encontradas: {len(rel.doacoes)}")
        print(f"Total doado: R$ {rel.total_doado:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))
        print(f"Anos eleitorais: {', '.join(map(str, rel.anos))}")
        print(sep)

        print("\nRANKING DE RECEPTORES:")
        print("-" * 60)
        for i, r in enumerate(rel.ranking_receptores(), 1):
            ativo = " [ELEITO/ATIVO]" if r["ativo"] else ""
            print(
                f"{i:2}. {r['nome'][:35]:<35} "
                f"{r['partido'] or '?':6} {r['uf'] or '?':2}  "
                f"R$ {r['total']:>12,.2f}  "
                f"({', '.join(map(str, r['anos']))}){ativo}"
            )

        if detalhado:
            print(f"\nTODAS AS TRANSAÇÕES ({len(rel.doacoes)}):")
            print("-" * 60)
            for d in sorted(rel.doacoes, key=lambda x: -x.valor):
                print(
                    f"  {d.ano_eleicao}  {d.nome_candidato[:30]:<30}  "
                    f"R$ {d.valor:>12,.2f}  {d.data_receita or '?'}"
                )
        print()

    @staticmethod
    def para_json(rel: RelatorioDossieDoador) -> str:
        """Serializa o relatório como JSON para uso em pipelines."""
        return json.dumps({
            "cpf_cnpj": rel.cpf_cnpj,
            "nome_busca": rel.nome_busca,
            "total_doacoes": len(rel.doacoes),
            "total_doado": rel.total_doado,
            "anos": rel.anos,
            "ranking_receptores": rel.ranking_receptores(),
            "transacoes": [
                {
                    "ano": d.ano_eleicao,
                    "candidato": d.nome_candidato,
                    "partido": d.sigla_partido,
                    "uf": d.uf,
                    "cargo": d.cargo,
                    "valor": d.valor,
                    "data": d.data_receita,
                    "tipo_doador": d.tipo_doador,
                    "setor": d.setor_economico,
                    "resultado": d.resultado_eleicao,
                    "parlamentar_ativo": d.parlamentar_ativo,
                    "id_camara": d.id_camara,
                }
                for d in sorted(rel.doacoes, key=lambda x: -x.valor)
            ],
        }, ensure_ascii=False, indent=2, default=str)
