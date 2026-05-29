"""
Modelos canônicos de dados — The Brasilia Insider
Todos os conectores convertem para estes dataclasses antes de persistir.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Optional


@dataclass
class Deputado:
    id: str                          # assembly_id + "_" + id_original
    nome: str
    partido: str
    uf: str
    assembly_id: str                 # "almg", "alesp", "cldf", etc.
    mandato_inicio: Optional[date] = None
    mandato_fim: Optional[date] = None
    foto_url: Optional[str] = None
    email: Optional[str] = None
    telefone: Optional[str] = None
    raw: dict = field(default_factory=dict)

    @property
    def slug(self) -> str:
        import unicodedata, re
        s = unicodedata.normalize("NFD", self.nome.lower())
        s = s.encode("ascii", "ignore").decode()
        s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
        return f"{self.assembly_id}-{s}"


@dataclass
class Proposicao:
    id: str                          # assembly_id + "_" + id_original
    numero: str
    ano: int
    tipo: str                        # "PL", "PEC", "PLO", "PDL", etc.
    ementa: str
    assembly_id: str
    autor: Optional[str] = None
    autor_id: Optional[str] = None
    data_apresentacao: Optional[date] = None
    situacao: Optional[str] = None
    url: Optional[str] = None
    regime: Optional[str] = None     # "urgência", "ordinário", etc.
    assuntos: list[str] = field(default_factory=list)
    raw: dict = field(default_factory=dict)


@dataclass
class VotoDeputado:
    deputado_id: str
    deputado_nome: str
    voto: str                        # "sim", "não", "abstenção", "ausente"
    partido: Optional[str] = None


@dataclass
class Votacao:
    id: str                          # assembly_id + "_" + id_original
    proposicao_id: str
    assembly_id: str
    data: Optional[date] = None
    hora: Optional[str] = None
    resultado: Optional[str] = None  # "aprovado", "rejeitado", "prejudicado"
    votos_sim: int = 0
    votos_nao: int = 0
    votos_abstencao: int = 0
    votos_ausente: int = 0
    detalhes: list[VotoDeputado] = field(default_factory=list)
    raw: dict = field(default_factory=dict)


@dataclass
class AssemblyMeta:
    """Metadados estáticos de cada assembleia."""
    id: str
    nome: str
    nome_curto: str
    uf: str
    capital: str
    n_deputados: int                 # fórmula Art. 27 CF
    tier: int                        # 1=API, 2=CSV, 3=scraping, 4=fechado
    base_url: str
    api_url: Optional[str] = None
    notas: Optional[str] = None
