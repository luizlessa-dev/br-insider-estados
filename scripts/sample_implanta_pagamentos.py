#!/usr/bin/env python3
"""Amostra: soma VALOR de Pagamentos de um conselho Implanta para um ano (MM/AAAA), mes a mes se preciso."""
import sys, json, ssl, urllib.request, urllib.error, socket
socket.setdefaulttimeout(40)
CTX=ssl.create_default_context(); CTX.check_hostname=False; CTX.verify_mode=ssl.CERT_NONE
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120 Safari/537.36"

def get(url):
    req=urllib.request.Request(url, headers={"User-Agent":UA,"Accept":"application/json"})
    try:
        with urllib.request.urlopen(req, context=CTX, timeout=40) as r:
            return r.status, r.read(60_000_000)
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, str(e).encode()

def num(v):
    if v is None: return 0.0
    if isinstance(v,(int,float)): return float(v)
    s=str(v).strip().replace('R$','').replace(' ','')
    # formato BR 1.234,56
    if ',' in s and '.' in s: s=s.replace('.','').replace(',','.')
    elif ',' in s: s=s.replace(',','.')
    try: return float(s)
    except: return 0.0

def find_valor(rec):
    for k in rec:
        if k.upper() in ('VALOR','VALOR_PAGO','VLR_PAGO','VALORPAGO','VL_PAGO'):
            return num(rec[k])
    # fallback: primeiro campo que parece valor
    for k,v in rec.items():
        if 'VALOR' in k.upper(): return num(v)
    return 0.0

def sample(base, ano):
    total=0.0; nrec=0; ncnpj=set(); months_ok=0
    for m in range(1,13):
        ref=f"{m:02d}/{ano}"
        url=f"{base}/v1.0/Pagamentos?referenciaInicio={ref}&referenciaTermino={ref}"
        st,body=get(url)
        if st!=200 or not body: continue
        try: data=json.loads(body)
        except: continue
        recs=data if isinstance(data,list) else data.get('value') or data.get('Data') or data.get('data') or []
        if not isinstance(recs,list): continue
        months_ok+=1
        for r in recs:
            if not isinstance(r,dict): continue
            nrec+=1; total+=find_valor(r)
            for k in r:
                if 'CPF' in k.upper() or 'CNPJ' in k.upper():
                    if r[k]: ncnpj.add(str(r[k]))
    return {"base":base,"ano":ano,"meses_com_dados":months_ok,"n_pagamentos":nrec,"n_cpfcnpj_distintos":len(ncnpj),"total_valor":round(total,2)}

if __name__=="__main__":
    base=sys.argv[1].rstrip('/'); ano=sys.argv[2] if len(sys.argv)>2 else "2024"
    print(json.dumps(sample(base,ano), ensure_ascii=False))
