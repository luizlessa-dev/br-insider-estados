"""Modelos de dados CGU — The Brasilia Insider."""
from __future__ import annotations
from dataclasses import dataclass, field
from datetime import date
from typing import Optional


@dataclass
class ProcessoDisciplinar:
    numero_processo: str          # PK natural — NumeroPadPrincipal

    tipo_processo: Optional[str]
    assuntos: list[str]           # array parseado
    pasta: Optional[str]          # ministério supervisor
    entidade: Optional[str]       # órgão onde ocorreu o processo

    uf: Optional[str]
    cidade: Optional[str]

    data_instauracao: Optional[date]
    fase_atual: Optional[str]
    data_fase: Optional[date]

    n_investigados: int = 0
    n_advertencias: int = 0
    n_suspensoes: int = 0
    n_expulsivas: int = 0
    n_outras_sancoes: int = 0
