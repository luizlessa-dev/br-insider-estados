import requests, os

headers = {'chave-api-dados': os.environ['PORTAL_TRANSPARENCIA_API_KEY']}

def brl(s):
    return float(s.replace('.', '').replace(',', '.')) if s else 0.0

todas = []
pagina = 1
while True:
    r = requests.get('https://api.portaldatransparencia.gov.br/api-de-dados/emendas',
                     params={'codigoFavorecido': '27819676000168', 'pagina': pagina},
                     headers=headers, timeout=20)
    if not r.ok:
        print('ERRO HTTP', r.status_code)
        break
    d = r.json()
    if not d:
        break
    todas.extend(d)
    if len(d) < 15:
        break
    pagina += 1

print(f'Total emendas: {len(todas)}')
tot_emp = tot_pago = tot_rpago = 0
for e in sorted(todas, key=lambda x: -brl(x.get('valorPago', '0'))):
    emp = brl(e.get('valorEmpenhado', '0'))
    pago = brl(e.get('valorPago', '0'))
    rpago = brl(e.get('valorRestoPago', '0'))
    tot_emp += emp
    tot_pago += pago
    tot_rpago += rpago
    print(f"{e.get('codigoEmenda','?'):14} {str(e.get('ano','?')):4} "
          f"{e.get('nomeAutor','?')[:24]:24} emp={emp:>12,.0f} "
          f"pago={pago:>12,.0f} restopago={rpago:>12,.0f}")
print('-' * 100)
print(f'TOTAIS: empenhado={tot_emp:,.0f} | pago_ano={tot_pago:,.0f} | resto_pago={tot_rpago:,.0f}')
print(f'DESEMBOLSO EFETIVO (pago+resto_pago) = R$ {tot_pago + tot_rpago:,.2f}')
