#!/usr/bin/env python3
"""Consolida hits do probe Implanta num inventario (JSON + CSV) de conselhos de classe."""
import json, re, csv, collections

UFS = set('ac al am ap ba ce df es go ma mg ms mt pa pb pe pi pr rj rn ro rr rs sc se sp to'.split())
UF_NOME = {'ac':'Acre','al':'Alagoas','am':'Amazonas','ap':'Amapá','ba':'Bahia','ce':'Ceará','df':'Distrito Federal','es':'Espírito Santo','go':'Goiás','ma':'Maranhão','mg':'Minas Gerais','ms':'Mato Grosso do Sul','mt':'Mato Grosso','pa':'Pará','pb':'Paraíba','pe':'Pernambuco','pi':'Piauí','pr':'Paraná','rj':'Rio de Janeiro','rn':'Rio Grande do Norte','ro':'Rondônia','rr':'Roraima','rs':'Rio Grande do Sul','sc':'Santa Catarina','se':'Sergipe','sp':'São Paulo','to':'Tocantins'}

# sigla raiz -> (nome do sistema, profissao)
SISTEMA = {
 'confea':('CONFEA','Engenharia e Agronomia (federal)'), 'crea':('CREA','Engenharia e Agronomia'),
 'cau':('CAU','Arquitetura e Urbanismo'),
 'cfm':('CFM','Medicina (federal)'), 'crm':('CRM','Medicina'),
 'cofen':('COFEN','Enfermagem (federal)'), 'coren':('COREN','Enfermagem'),
 'cfo':('CFO','Odontologia (federal)'), 'cro':('CRO','Odontologia'),
 'cfc':('CFC','Contabilidade (federal)'), 'crc':('CRC','Contabilidade'),
 'cff':('CFF','Farmácia (federal)'), 'crf':('CRF','Farmácia'),
 'cfmv':('CFMV','Medicina Veterinária (federal)'), 'crmv':('CRMV','Medicina Veterinária'),
 'cfa':('CFA','Administração (federal)'), 'cra':('CRA','Administração'),
 'cfp':('CFP','Psicologia (federal)'), 'crp':('CRP','Psicologia'),
 'cfq':('CFQ','Química (federal)'), 'crq':('CRQ','Química'),
 'cfn':('CFN','Nutrição (federal)'), 'crn':('CRN','Nutrição'),
 'cfess':('CFESS','Serviço Social (federal)'), 'cress':('CRESS','Serviço Social'),
 'cffa':('CFFa','Fonoaudiologia (federal)'), 'crfa':('CRFa','Fonoaudiologia'),
 'coffito':('COFFITO','Fisioterapia e Terapia Ocupacional (federal)'),
 'crefito':('CREFITO','Fisioterapia e Terapia Ocupacional'),
 'cft':('CFT','Técnicos Industriais (federal)'), 'crt':('CRT','Técnicos Industriais'),
 'cofecon':('COFECON','Economia (federal)'), 'corecon':('CORECON','Economia'),
 'confef':('CONFEF','Educação Física (federal)'), 'cref':('CREF','Educação Física'),
 'conter':('CONTER','Técnicos em Radiologia (federal)'), 'crtr':('CRTR','Técnicos em Radiologia'),
 'cofeci':('COFECI','Corretores de Imóveis (federal)'), 'creci':('CRECI','Corretores de Imóveis'),
 'crbio':('CRBio','Biologia'), 'crb':('CRB','Biblioteconomia'), 'conre':('CONRE','Estatística'),
}

def classify(host):
    sub = host.split('.')[0]
    m = re.match(r'^([a-z]+?)-?(\d+|[a-z]{2}|br)$', sub)
    sig_root, suf, regiao, tipo = sub, '', '', 'desconhecido'
    if m:
        sig_root, suf = m.group(1), m.group(2)
        if suf == 'br':
            tipo, regiao = 'federal', 'Nacional'
        elif suf in UFS:
            tipo, regiao = 'regional', UF_NOME[suf]
        elif suf.isdigit():
            tipo, regiao = 'regional', f'{suf}ª Região'
    nome_sist, prof = SISTEMA.get(sig_root, (sig_root.upper(), 'Conselho profissional'))
    sigla_disp = f'{nome_sist}-{suf.upper()}' if suf and suf != 'br' else f'{nome_sist}-BR' if suf == 'br' else nome_sist
    return {'sigla': sigla_disp, 'sistema': nome_sist, 'profissao': prof, 'tipo': tipo, 'regiao': regiao}

def main():
    seen = {}
    for l in open('/tmp/all_hits.jsonl'):
        h = json.loads(l); seen[h['host']] = h
    rows = []
    for host, h in sorted(seen.items()):
        c = classify(host)
        eps = h.get('endpoints', [])
        rows.append({
            **c,
            'host': host,
            'spec_url': h.get('spec_url'),
            'base_rest': h.get('spec_url','').replace('/swagger/docs/v1','').replace('/api/swagger/docs/v1','/api') if h.get('spec_url') else None,
            'n_endpoints': h.get('n_endpoints', 0),
            'tem_pagamentos': 'Pagamentos' in eps,
            'tem_contratos': 'Contratos' in eps,
            'tem_licitacoes': 'Licitacoes' in eps,
            'endpoints': eps,
        })
    # ordena: sistema, regiao
    rows.sort(key=lambda r: (r['sistema'], r['regiao']))
    sist = collections.Counter(r['sistema'] for r in rows)
    inv = {
        'fonte': 'Implanta Informática / PortalTransparencia.Net',
        'metodo': 'Sweep do endpoint OpenAPI /transparencia/api/swagger/docs/v1 em subdominios {sigla}-{uf|br|NNN}.implanta.net.br',
        'data_levantamento': '2026-06-21',
        'assinatura_confirmada': 'HTTP 200 + JSON swagger com paths; title "API REST do Portal da Transparência"',
        'periodo_param': 'MM/AAAA (referenciaInicio/referenciaTermino); recortes mensais ou anuais',
        'cnpj_observacao': 'CPF_CNPJ vem CHEIO para pessoa juridica (CNPJ), MASCARADO para pessoa fisica (CPF). NOME_RAZAO_SOCIAL sempre presente.',
        'totais': {
            'conselhos_confirmados': len(rows),
            'com_dados_publicados': sum(1 for r in rows if r['n_endpoints'] > 0),
            'com_endpoint_pagamentos': sum(1 for r in rows if r['tem_pagamentos']),
            'com_contratos': sum(1 for r in rows if r['tem_contratos']),
            'federais': sum(1 for r in rows if r['tipo'] == 'federal'),
            'regionais': sum(1 for r in rows if r['tipo'] == 'regional'),
            'por_sistema': dict(sist.most_common()),
        },
        'amostra_financeira_2024': {
            'metodo': 'soma VALOR de Pagamentos, mes a mes, ano 2024',
            'conselhos': {
                'CONFEA': {'total_valor': 279163750.18, 'n_pagamentos': 15918, 'cnpj_cpf_distintos': 2448},
                'COFEN':  {'total_valor': 179258194.07, 'n_pagamentos': 7595,  'cnpj_cpf_distintos': 711},
                'CREA-MG':{'total_valor': 146528062.79, 'n_pagamentos': 22718, 'cnpj_cpf_distintos': 3256},
                'CAU-BR': {'total_valor': 66353038.70,  'n_pagamentos': 6864,  'cnpj_cpf_distintos': 686},
                'CRQ-SP': {'total_valor': 56267233.67,  'n_pagamentos': 4288,  'cnpj_cpf_distintos': 490},
                'CAU-AL': {'total_valor': 1971633.50,   'n_pagamentos': 874,   'cnpj_cpf_distintos': 73},
            },
            'soma_amostra_6_conselhos': 729541912.91,
        },
        'conselhos': rows,
    }
    with open('dados/inventario_implanta_conselhos.json', 'w') as f:
        json.dump(inv, f, ensure_ascii=False, indent=2)
    with open('dados/inventario_implanta_conselhos.csv', 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['sigla','sistema','profissao','tipo','regiao','host','spec_url','n_endpoints','tem_pagamentos','tem_contratos','tem_licitacoes'])
        for r in rows:
            w.writerow([r['sigla'],r['sistema'],r['profissao'],r['tipo'],r['regiao'],r['host'],r['spec_url'],r['n_endpoints'],r['tem_pagamentos'],r['tem_contratos'],r['tem_licitacoes']])
    print('Inventario gravado:', len(rows), 'conselhos')
    print('Por sistema:', dict(sist.most_common()))
    print('Com Pagamentos:', inv['totais']['com_endpoint_pagamentos'])

if __name__ == '__main__':
    main()
