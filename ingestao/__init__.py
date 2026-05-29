"""
Módulo de ingestão — The Brasilia Insider
27 assembleias estaduais + CLDF
"""
from .connectors import REGISTRY, get_connector, all_connectors

__all__ = ["REGISTRY", "get_connector", "all_connectors"]
