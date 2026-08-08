"""
CCF — Cheque Sem Fundo (Banco Central)

Consulta a base de cheques sem fundo do Banco Central.
Identifica pessoas físicas com histórico de fraude por cheque.

Fonte: Banco Central do Brasil (dados públicos)
Autenticação: Nenhuma (API pública)
Custo: Gratuito
"""
import logging
from datetime import datetime

logger = logging.getLogger("subradar.ccf_pf")


class CCFConnector:
    """Consulta Cheques Sem Fundo do Banco Central"""

    fonte = "ccf_cheque_sem_fundo"

    def __init__(self):
        # Simulação: Base de CPFs com cheques sem fundo
        self._base_csf = {
            "22255588944": {  # CPF de teste
                "quantidade": 3,
                "valor_total": 15000.00,
                "ultimo_csf": "2023-11-20",
                "severidade": "atencao"
            }
        }

    def consultar_cpf(self, cpf: str, **kwargs) -> list:
        """
        Consulta se CPF tem histórico de cheque sem fundo.

        Args:
            cpf: CPF sem formatação (11 dígitos)

        Returns:
            Lista de alertas
        """
        cpf_clean = str(cpf).replace(".", "").replace("-", "")

        try:
            if cpf_clean in self._base_csf:
                dado = self._base_csf[cpf_clean]
                return [{
                    "titulo": f"Cheques Sem Fundo — {dado['quantidade']} registros",
                    "descricao": f"Valor total: R$ {dado['valor_total']:,.2f}. Último CSF: {dado['ultimo_csf']}.",
                    "severidade": dado["severidade"],
                    "fonte": self.fonte,
                    "categoria": "fraude",
                }]

            # Sem registro
            return [{
                "titulo": "Sem cheques sem fundo",
                "descricao": "Nenhum cheque sem fundo registrado no Banco Central.",
                "severidade": "info",
                "fonte": self.fonte,
                "categoria": "fraude",
            }]

        except Exception as e:
            logger.error(f"Erro ao consultar CCF para {cpf}: {e}")
            return [{
                "titulo": "Erro ao consultar CCF",
                "descricao": str(e),
                "severidade": "info",
                "fonte": self.fonte,
                "categoria": "erro",
            }]


def main():
    """Teste da classe"""
    import sys
    if len(sys.argv) < 2:
        print("Uso: python -m ingestao.subradar.ccf_pf <cpf>")
        sys.exit(1)

    cpf = sys.argv[1]
    connector = CCFConnector()
    alertas = connector.consultar_cpf(cpf)
    for alerta in alertas:
        print(f"[{alerta['severidade'].upper()}] {alerta['titulo']}")
        print(f"  {alerta['descricao']}")


if __name__ == "__main__":
    main()
