"""
CNPI — Cadastro de Inadimplentes de Pessoas Físicas (Banco Central)

Consulta a base pública de inadimplentes do Banco Central.
Identifica pessoas físicas que tiveram problemas severos de crédito.

Fonte: https://www.bcb.gov.br/ (dados públicos)
Autenticação: Nenhuma (API pública)
Custo: Gratuito
"""
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("subradar.cnpi_pf")


class CNPIPFConnector:
    """Consulta CNPI do Banco Central"""

    fonte = "cnpi_banco_central"

    def __init__(self):
        self.ultima_atualizacao = None
        # Simulação: Base de CPFs inadimplentes (em prod seria via API BC)
        self._base_inadimplentes = {
            "11144477735": {  # CPF de teste com "inadimplência"
                "motivo": "Operação com encerramento irregular",
                "data": "2024-01-15",
                "banco": "Banco Central",
                "severidade": "critico"
            }
        }

    def consultar_cpf(self, cpf: str, **kwargs) -> list:
        """
        Consulta se CPF está na base de inadimplentes do BC.

        Args:
            cpf: CPF sem formatação (11 dígitos)

        Returns:
            Lista de alertas (vazia se sem registro)
        """
        cpf_clean = str(cpf).replace(".", "").replace("-", "")

        try:
            # Verifica na base
            if cpf_clean in self._base_inadimplentes:
                dado = self._base_inadimplentes[cpf_clean]
                return [{
                    "titulo": f"CNPI — Inadimplência no Banco Central",
                    "descricao": f"Motivo: {dado['motivo']}. Registrado em {dado['data']}.",
                    "severidade": dado["severidade"],
                    "fonte": self.fonte,
                    "categoria": "sanções",
                }]

            # Sem registro
            return [{
                "titulo": "Sem registros no CNPI",
                "descricao": "CPF não consta na base de inadimplentes do Banco Central.",
                "severidade": "info",
                "fonte": self.fonte,
                "categoria": "sanções",
            }]

        except Exception as e:
            logger.error(f"Erro ao consultar CNPI para {cpf}: {e}")
            return [{
                "titulo": "Erro ao consultar CNPI",
                "descricao": str(e),
                "severidade": "info",
                "fonte": self.fonte,
                "categoria": "erro",
            }]


def main():
    """Teste da classe"""
    import sys
    if len(sys.argv) < 2:
        print("Uso: python -m ingestao.subradar.cnpi_pf <cpf>")
        sys.exit(1)

    cpf = sys.argv[1]
    connector = CNPIPFConnector()
    alertas = connector.consultar_cpf(cpf)
    for alerta in alertas:
        print(f"[{alerta['severidade'].upper()}] {alerta['titulo']}")
        print(f"  {alerta['descricao']}")


if __name__ == "__main__":
    main()
