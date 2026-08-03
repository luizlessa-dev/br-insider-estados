-- The BR Insider — Bets licenciadas SPA/MF
-- Fonte: planilha-de-autorizacoes-13-05-2026.csv (gov.br/fazenda/spa)
-- 81 operadoras únicas, 186 marcas — atualizado 2026-05-13

CREATE TABLE IF NOT EXISTS public.bets_licenciadas (
  id              SERIAL PRIMARY KEY,
  cnpj            CHAR(14)    NOT NULL UNIQUE,
  nome            TEXT        NOT NULL,
  portaria        TEXT,
  marcas          TEXT[],
  dominios        TEXT[],
  data_ingestao   DATE        NOT NULL DEFAULT CURRENT_DATE
);

COMMENT ON TABLE public.bets_licenciadas IS
  'Operadoras autorizadas pela SPA/MF a explorar apostas de quota fixa. '
  'Fonte: gov.br/fazenda/spa, planilha-de-autorizacoes-13-05-2026.csv (81 operadoras, 186 marcas).';

CREATE INDEX IF NOT EXISTS idx_bets_licenciadas_cnpj ON public.bets_licenciadas(cnpj);

INSERT INTO public.bets_licenciadas (cnpj, nome, portaria, marcas, dominios)
VALUES
  ('55590815000160', 'BPX BETS SPORTS GROUP LTDA', 'SPA/MF nº 797, de 23 de março de 2026', ARRAY['VAIDEBET','BETPIX365','OBABET'], ARRAY['vaidebet.bet.br','betpix365.bet.br','obabet.bet.br']),
  ('60828451000143', 'NOSSO TIME IGAMING LTDA', 'SPA/MF nº 604, de 6 de março de 2026', ARRAY['JOGA JUNTO'], ARRAY['jogajunto.bet.br']),
  ('57522731000114', 'BB GAMING LTDA', 'SPA/MF nº 92, de 13 de janeiro de 2026', ARRAY['BRA','XX'], ARRAY['bra.bet.br','xx.bet.br']),
  ('56108627000115', 'ESTADOX LTDA', 'SPA/MF nº 2.325, de 14 de outubro de 2025', ARRAY['TROPINO','BZ','55W'], ARRAY['tropino.bet.br','bz.bet.br','55w.bet.br']),
  ('55459453000172', 'OIG GAMING BRAZIL LTDA', 'SPA/MF nº 2.040, de 11 de setembro de 2025', ARRAY['R7','7GAMES','BETÃO','ICE'], ARRAY['ice.bet.br','betao.bet.br','r7.bet.br','7games.bet.br']),
  ('53429401000128', 'ENSEADA SERVIÇOS E TECNOLOGIA LTDA', 'SPA/MF nº 1.792, de 13 de agosto de 2025', ARRAY['KBET'], ARRAY['kbet.bet.br']),
  ('50920462000103', 'LAGUNA SERVIÇOS E TECNOLOGIA LTDA', 'SPA/MF nº 1.791, de 13 de agosto de 2025', ARRAY['NOSSABET'], ARRAY['nossa.bet.br']),
  ('47974569000111', 'DEFY LTDA', 'SPA/MF nº 1.666, de 29 de julho de 2025', ARRAY['1XBET'], ARRAY['1xbet.bet.br']),
  ('24038490000183', 'CAIXA LOTERIAS S.A.', 'SPA/MF nº 1.665, de 29 de julho de 2025', ARRAY['BETCAIXA','MEGABET','XBET CAIXA'], ARRAY['betcaixa.bet.br','megabet.bet.br','xbetcaixa.bet.br']),
  ('55238676000100', 'TQJ-PAR PARTICIPAÇÕES SOCIETÁRIAS S.A.', 'SPA/MF nº 1.344, de 18 de junho de 2025', ARRAY['BAÚ BINGO','BET DO MILHÃO'], ARRAY['bau.bet.br','milhao.bet.br']),
  ('56905647000117', 'RESPONSA GAMMING BRASIL LIMITADA', 'SPA/MF nº 1.343, de 18 de junho de 2025', ARRAY['JOGA LIMPO','ENERGIA'], ARRAY['jogalimpo.bet.br','energia.bet.br']),
  ('56875122000186', 'SELECT OPERATIONS LTDA', 'SPA/MF nº 1.112, de 21 de maio de 2025', ARRAY['MMA','BETVIP','PAPIGAMES'], ARRAY['mmabet.bet.br','betvip.bet.br','papigames.bet.br']),
  ('56257966000163', 'SPORTVIP GROUP INTERNATIONAL APOSTAS LTDA', 'SPA/MF nº 1.055, de 14 de maio de 2025', ARRAY['ESPORTIVAVIP','CBESPORTES','DONOSDABOLA'], ARRAY['esportivavip.bet.br','cbesportes.bet.br','donosdabola.bet.br']),
  ('56442917000109', '7MBR LTDA', 'SPA/MF nº 844, de 17 de abril de 2025', ARRAY['VERT','CGG','FANBIT'], ARRAY['vert.bet.br','cgg.bet.br','fanbit.bet.br']),
  ('40633348000130', 'PIXBET SOLUÇÕES TECNOLÓGICAS LTDA.', 'SPA/MF nº 806, de 14 de abril de 2025', ARRAY['PIXBET','GANHEIBET','BET DA SORTE'], ARRAY['pix.bet.br','ganhei.bet.br','betdasorte.bet.br']),
  ('56885537000130', 'VANGUARD ENTRETENIMENTO BRASIL LTDA', 'SPA/MF nº 693, de 1º de abril de 2025', ARRAY['ESPORTE 365','BET AKI','JOGO DE OURO'], ARRAY['esporte365.bet.br','betaki.bet.br','jogodeouro.bet.br']),
  ('06023798000173', 'SISTEMA LOTÉRICO DE PERNAMBUCO LTDA.', 'SPA/MF nº 528, de 14 de março de 2025', ARRAY['MCGAMES','PLAY','MONTECARLOS'], ARRAY['mcgames.bet.br','play.bet.br','montecarlos.bet.br']),
  ('56441713000145', 'LBBR APOSTAS DE QUOTA FIXA LIMITADA', 'SPA/MF nº 527, de 14 de março de 2025', ARRAY['LUCK.BET','1 PRA 1','STARTBET'], ARRAY['luck.bet.br','1pra1.bet.br','start.bet.br']),
  ('56195600000107', 'MERIDIAN GAMING BRASIL SPE LTDA', 'SPA/MF nº 526, de 14 de março de 2025', ARRAY['MERIDIAN','PIN'], ARRAY['meridianbet.bet.br','pin.bet.br']),
  ('23159703000162', 'Rr Participacoes e Intermediacoes de Negocios LTDA', 'SPA/MF nº 525, de 14 de março de 2025', ARRAY['MULTIBET','RICOBET','BRXBET'], ARRAY['multi.bet.br','rico.bet.br','brx.bet.br']),
  ('55258645000110', 'PIX NA HORA', 'SPA/MF nº 524, de 14 de março de 2025', ARRAY['APOSTA1','APOSTAMAX','AVIÃOBET'], ARRAY['aposta1.bet.br','apostamax.bet.br','aviao.bet.br']),
  ('53570592000143', 'EA ENTRETENIMENTO E ESPORTES S.A.', 'SPA/MF nº 523, de 14 de março de 2025', ARRAY['BATEU BET','ESPORTIVA BET'], ARRAY['bateu.bet.br','esportiva.bet.br']),
  ('54362120000168', 'HILGARDO GAMING LTDA', 'SPA/MF nº 475, de 10 de março de 2025', ARRAY['A247','HILGARDO','HILGARDO GAMING'], ARRAY['a247.bet.br','a definir','a definir']),
  ('55080231000144', 'Versus Brasil Ltda', 'SPA/MF nº 474, de 10 de março de 2025', ARRAY['VERSUSBET','VS - VERSUS'], ARRAY['versus.bet.br','a definir']),
  ('55822818000181', 'WORLD SPORTS TECHNOLOGY DO BRASIL S.A.', 'SPA/MF nº 473, de 10 de março de 2025', ARRAY['BETCOPA','BRASIL DA SORTE','FYBET'], ARRAY['betcopa.bet.br','brasildasorte.bet.br','fybet.bet.br']),
  ('56706644000154', 'B3T4 INTERNATIONAL GROUP LTDA', 'SPA/MF nº 472, de 10 de março de 2025', ARRAY['BET4','APOSTA BET','FAZ O BET'], ARRAY['bet4.bet.br','aposta.bet.br','fazo.bet.br']),
  ('56431248000161', 'FOGGO ENTERTAINMENT LTDA', 'SPA/MF nº 471, de 10 de março de 2025', ARRAY['BLAZE','JONBET'], ARRAY['blaze.bet.br','jonbet.bet.br']),
  ('56706701000103', 'TRACK GAMING BRASIL LTDA', 'SPA/MF nº 470, de 10 de março de 2025', ARRAY['BETWARRIOR','DR. BINGO'], ARRAY['betwarrior.bet.br','drbingo.bet.br']),
  ('37456039000128', 'GORILLAS GROUP DO BRASIL LTDA', 'SPA/MF nº 469, de 10 de março de 2025', ARRAY['BET GORILLAS','BET BUFFALOS','BET FALCONS'], ARRAY['betgorillas.bet.br','betbuffalos.bet.br','betfalcons.bet.br']),
  ('37486405000191', 'BLOW MARKETPLACE LTDA', 'SPA/MF nº 468, de 10 de março de 2025', ARRAY['BRAVO','TRADICIONAL','APOSTATUDO'], ARRAY['bravo.bet.br','tradicional.bet.br','apostatudo.bet.br']),
  ('55980542000160', 'FAST GAMING S.A.', 'SPA/MF nº 467, de 10 de março de 2025', ARRAY['BETFAST','FAZ1BET','TIVOBET'], ARRAY['betfast.bet.br','faz1.bet.br','tivo.bet.br']),
  ('55399607000188', 'FUTURAS APOSTAS LTDA', 'SPA/MF nº 466, de 10 de março de 2025', ARRAY['BRAZINO777'], ARRAY['brazino777.bet.br']),
  ('56195099000189', 'GAMEWIZ BRASIL LTDA', 'SPA/MF nº 465, de 10 de março de 2025', ARRAY['6R','IJOGO','BET.APP','P9','FOGO777','9F'], ARRAY['p9.bet.br','ijogo.bet.br','fogo777.bet.br','6r.bet.br','9f.bet.br','betapp.bet.br']),
  ('04426418000116', 'SABIA ADMINISTRACAO LTDA', 'SPA/MF nº 399, de 24 de fevereiro de 2025', ARRAY['BR4BET','GOL DE BET','LOTOGREEN'], ARRAY['br4.bet.br','goldebet.bet.br','lotogreen.bet.br']),
  ('55927219000122', 'SKILL ON NET LTDA', 'SPA/MF nº 374, de 24 de fevereiro de 2025', ARRAY['BACANAPLAY','PLAYUZU'], ARRAY['bacanaplay.bet.br','playuzu.bet.br']),
  ('55881028000177', 'BETBR LOTERIAS LTDA', 'SPA/MF nº 373, de 24 de fevereiro de 2025', ARRAY['APOSTOU','B1 BET','BRBET'], ARRAY['apostou.bet.br','b1bet.bet.br','brbet.bet.br']),
  ('56197912000150', 'UX ENTERTAINMENT LTDA', 'SPA/MF nº 372, de 24 de fevereiro de 2025', ARRAY['REALS','BINGO','BETGO'], ARRAY['reals.bet.br','bingo.bet.br','betgo.bet.br']),
  ('17385948000105', 'SIMULCASTING BRASIL SOM E IMAGEM S.A.', 'SPA/MF nº 371, de 24 de fevereiro de 2025', ARRAY['BETSSON'], ARRAY['betsson.bet.br']),
  ('41590869000110', 'BIG BRAZIL TECNOLOGIA E LOTERIA S.A.', 'SPA/MF nº 370, de 24 de fevereiro de 2025', ARRAY['BIG','"'], ARRAY['big.bet.br']),
  ('53274124000121', 'OPEN GAMING S.A.', 'SPA/MF nº 326, de 17 fevereiro de 2025', ARRAY['BET.BET','DONALDBET'], ARRAY['betpontobet.bet.br','donald.bet.br']),
  ('56504413000168', 'SEVENX GAMING LTDA', 'SPA/MF nº 325, de  17 fevereiro de 2025', ARRAY['BULLSBET','JOGÃO','JOGOS'], ARRAY['bullsbet.bet.br','jogao.bet.br','jogos.bet.br']),
  ('56349116000195', 'LOGAME DO BRASIL LTDA', 'SPA/MF nº 324, de  17 fevereiro de 2025', ARRAY['LÍDERBET','GERALBET'], ARRAY['lider.bet.br','geralbet.bet.br']),
  ('56236761000100', 'UPBET BRASIL LTDA', 'SPA/MF nº 323, de 17 de fevereiro de 2025', ARRAY['UPBETBR','9D','WJCASINO'], ARRAY['up.bet.br','9d.bet.br','wjcasino.bet.br']),
  ('55933850000134', 'ANA GAMING BRASIL S.A.', 'SPA/MF nº 322, de 17 de fevereiro de 2025', ARRAY['7K','CASSINO','VERA'], ARRAY['7k.bet.br','cassino.bet.br','vera.bet.br']),
  ('55404799000173', 'HIPER BET TECNOLOGIA LTDA.', 'SPA/MF nº 321, de 17 de fevereiro de 2025', ARRAY['HIPERBET'], ARRAY['hiper.bet.br']),
  ('52639845000125', 'EB INTERMEDIACOES E JOGOS S.A.', 'SPA/MF nº 320, de 17 de fevereiro de 2025', ARRAY['ESTRELABET','VUPI'], ARRAY['estrelabet.bet.br','vupi.bet.br']),
  ('51897834000182', 'F12 DO BRASIL JOGOS ELETRONICOS LTDA', 'SPA/MF nº 319, de 17 de fevereiro de 2025', ARRAY['F12.BET','LUVA.BET','BRASIL.BET'], ARRAY['f12.bet.br','luva.bet.br','brasil.bet.br']),
  ('56638458000125', 'BELL VENTURES DIGITAL LTDA', 'SPA/MF nº 270, de 10 de fevereiro de 2025', ARRAY['BANDBET'], ARRAY['bandbet.bet.br']),
  ('55078134000117', 'NEXUS INTERNATIONAL LTDA', 'SPA/MF nº 265, de 07 de fevereiro de 2025', ARRAY['MEGAPOSTA'], ARRAY['megaposta.bet.br']),
  ('56873267000148', 'OLAVIR LTDA', 'SPA/MF nº 264, de 07 de fevereiro de 2025', ARRAY['RIVALO'], ARRAY['rivalo.bet.br']),
  ('56525936000190', 'STAKE BRAZIL LTDA', 'SPA/MF nº 263, de 07 de fevereiro de 2025', ARRAY['STAKE'], ARRAY['stake.bet.br']),
  ('56302709000104', 'JOGO PRINCIPAL LTDA', 'SPA/MF nº 262, de 07 de fevereiro de 2025', ARRAY['GINGABET','QGBET','VIVASORTE'], ARRAY['ginga.bet.br','qg.bet.br','vivasorte.bet.br']),
  ('56259060000188', 'BRILLIANT GAMING LTDA', 'SPA/MF nº 261, de 07 de fevereiro de 2025', ARRAY['AFUN','AI','6Z'], ARRAY['afun.bet.br','ai.bet.br','6z.bet.br']),
  ('54989030000100', 'SORTENABET GAMING BRASIL S.A.', 'SPA/MF nº 260, de 07 de fevereiro de 2025', ARRAY['SORTENABET','BETOU','BETFUSION'], ARRAY['sortenabet.bet.br','betou.bet.br','betfusion.bet.br']),
  ('55045663000114', 'LEVANTE BRASIL LTDA', 'SPA/MF nº 259, de 07 de fevereiro de 2025', ARRAY['SORTE ONLINE','LOTTOLAND'], ARRAY['sorteonline.bet.br','lottoland.bet.br']),
  ('56061524000147', 'BETSPEED LTDA', 'SPA/MF nº 258, de 07 de fevereiro de 2025', ARRAY['TIGER.BET','PQ777','5G'], ARRAY['tiger.bet.br','pq777.bet.br','5g.bet.br']),
  ('56295104000125', 'BETESPORTE APOSTAS ON LINE LTDA', 'SPA/MF nº 257, de 07 de fevereiro de 2025', ARRAY['BETESPORTE','LANCE DE SORTE'], ARRAY['betesporte.bet.br','lancedesorte.bet.br']),
  ('56183358000151', 'SUPREMA BET LTDA', 'SPA/MF nº 256, de 07 de fevereiro de 2025', ARRAY['SUPREMABET','MAXIMABET','ULTRABET'], ARRAY['suprema.bet.br','maxima.bet.br','ultra.bet.br']),
  ('56636543000154', 'CDA GAMING LTDA', 'SPA/MF nº 255, de 07 de fevereiro de 2025', ARRAY['CASA DE APOSTAS','BET SUL','JOGO ONLINE'], ARRAY['casadeapostas.bet.br','betsul.bet.br','jogoonline.bet.br']),
  ('54068631000171', 'SC OPERATING BRAZIL LTDA', 'SPA/MF nº 254, de 07 de fevereiro de 2025', ARRAY['VBET','VIVARO'], ARRAY['vbet.bet.br','vivaro.bet.br']),
  ('56303755000110', 'H2 LICENSED LTDA', 'SPA/MF nº 253, de 07 de fevereiro de 2025', ARRAY['SEUBET','H2 BET'], ARRAY['seu.bet.br','h2.bet.br']),
  ('56212040000151', 'LUCKY GAMING LTDA', 'SPA/MF nº 252, de 07 de fevereiro de 2025', ARRAY['4WIN','4PLAY','PAGOL'], ARRAY['4win.bet.br','4play.bet.br','pagol.bet.br']),
  ('56001749000108', 'APOSTA GANHA LOTERIAS LTDA', 'SPA/MF nº 251, de 07 de fevereiro de 2025', ARRAY['APOSTA GANHA','RECEBA'], ARRAY['apostaganha.bet.br','receba.bet.br']),
  ('47123407000170', 'HS DO BRASIL LTDA', 'SPA/MF nº 250, de 07 de fevereiro de 2025', ARRAY['BET365'], ARRAY['bet365.bet.br']),
  ('50587712000127', 'NVBT GAMING LTDA', 'SPA/MF nº 249, de 07 fevereiro de 2025', ARRAY['NOVIBET'], ARRAY['novibet.bet.br']),
  ('55229080000143', 'NSX BETFAIR BRASIL S.A', 'SPA/MF nº 248, de 07 de fevereiro de 2025', ARRAY['BETFAIR'], ARRAY['betfair.bet.br']),
  ('52868380000184', 'VENTMEAR BRASIL S.A.', 'SPA/MF nº 247, de 07 de fevereiro de 2025', ARRAY['SPORTINGBET','BETBOO'], ARRAY['sportingbet.bet.br','betboo.bet.br']),
  ('46786961000174', 'KAIZEN GAMING BRASIL LTDA', 'SPA/MF nº 246, de 07 de fevereiro de 2025', ARRAY['BETANO','ONABET','LOTTU'], ARRAY['betano.bet.br','ona.bet.br','lottu.bet.br']),
  ('50550511000155', 'LINDAU GAMING BRASIL S.A.', 'SPA/MF nº 2.105, de 30 de dezembro de 2024', ARRAY['OLEYBET'], ARRAY['oleybet.bet.br']),
  ('54951974000180', 'BETBOOM LTDA', 'SPA/MF nº 2.103, de 30 de dezembro de 2024', ARRAY['BETBOOM'], ARRAY['betboom.bet.br']),
  ('56147145000174', 'A2FBR S.A.', 'SPA/MF nº 2.102, de 30 de dezembro de 2024', ARRAY['MATCHBOOK','PINNACLE','BETBRA','BOLSA DE APOSTA','BETESPECIAL','FULLTBET'], ARRAY['betespecial.bet.br','pinnacle.bet.br','betbra.bet.br','matchbook.bet.br','fulltbet.bet.br','bolsadeaposta.bet.br']),
  ('55359927000104', 'ALFA ENTRETENIMENTO S.A.', 'SPA/MF nº 2.100, de 30 de dezembro de 2024', ARRAY['ALFA.BET'], ARRAY['alfa.bet.br']),
  ('56060798000111', 'DIGIPLUS BRAZIL INTERACTIVE LTDA', 'SPA/MF nº 2.099, de 30 de dezembro de 2024', ARRAY['ARENAPLUS','BINGOPLUS'], ARRAY['arenaplus.bet.br','bingoplus.bet.br']),
  ('53837227000152', 'BOA LION S.A.', 'SPA/MF nº 2.098, de 30 de dezembro de 2024', ARRAY['BETMGM','MGM'], ARRAY['betmgm.bet.br','mgm.bet.br']),
  ('56268974000105', 'SEGURO BET LTDA', 'SPA/MF nº 2.097, de 30 de dezembro de 2024', ARRAY['SEGURO BET','KING PANDA'], ARRAY['seguro.bet.br','kingpanda.bet.br']),
  ('55988317000170', 'BLAC JOGOS LTDA', 'SPA/MF nº 2.095, de 30 de dezembro de 2024', ARRAY['SPORTYBET'], ARRAY['sporty.bet.br']),
  ('31853299000150', 'GALERA GAMING JOGOS ELETRONICOS S.A.', 'SPA/MF nº 2.094, de 30 de dezembro de 2024', ARRAY['GALERA.BET'], ARRAY['galera.bet.br']),
  ('54923003000126', 'APOLLO OPERATIONS LTDA', 'SPA/MF nº 2.093, de 30 de dezembro de 2024', ARRAY['KTO'], ARRAY['kto.bet.br']),
  ('55056104000100', 'NSX BRASIL S.A.', 'SPA/MF nº 2.092, de 30 de dezembro de 2024', ARRAY['BETNACIONAL'], ARRAY['betnacional.bet.br']),
  ('34935286000119', 'MMD TECNOLOGIA, ENTRETENIMENTO E MARKETING LTDA', 'SPA/MF nº 2.091, de 30 de dezembro 2024', ARRAY['REI DO PITACO','PITACO','RdP'], ARRAY['reidopitaco.bet.br','pitaco.bet.br','rdp.bet.br']),
  ('54071596000140', 'SPRBT INTERACTIVE BRASIL LTDA', 'SPA/MF nº 2.090, de 30 de dezembro de 2024', ARRAY['SUPERBET','MAGICJACKPOT','SUPER'], ARRAY['superbet.bet.br','magicjackpot.bet.br','super.bet.br'])
ON CONFLICT (cnpj) DO UPDATE SET
  nome = EXCLUDED.nome,
  portaria = EXCLUDED.portaria,
  marcas = EXCLUDED.marcas,
  dominios = EXCLUDED.dominios;


-- ─── View: bets × doadores de campanha ───────────────────────────────────────
CREATE OR REPLACE VIEW public.v_bets_doadores_campanha AS
SELECT
  b.cnpj,
  b.nome                        AS operadora,
  b.marcas,
  r.ano_eleicao,
  r.cpf_candidato,
  r.nome_candidato,
  r.cargo,
  r.sigla_partido,
  r.uf,
  SUM(r.valor)                  AS total_doado,
  COUNT(*)                      AS num_doacoes
FROM public.bets_licenciadas b
JOIN public.tse_receitas r ON r.cpf_cnpj_doador = b.cnpj
GROUP BY b.cnpj, b.nome, b.marcas, r.ano_eleicao, r.cpf_candidato, r.nome_candidato, r.cargo, r.sigla_partido, r.uf
ORDER BY total_doado DESC;

-- ─── View: bets × favorecidos de emendas ─────────────────────────────────────
CREATE OR REPLACE VIEW public.v_bets_favorecidas_emendas AS
SELECT
  b.cnpj,
  b.nome                        AS operadora,
  b.marcas,
  f.nome_autor                  AS parlamentar,
  f.codigo_autor,
  SUM(f.valor_recebido)         AS total_emendas,
  COUNT(*)                      AS num_transferencias
FROM public.bets_licenciadas b
JOIN public.emendas_favorecidos f ON f.codigo_favorecido = b.cnpj
GROUP BY b.cnpj, b.nome, b.marcas, f.nome_autor, f.codigo_autor
ORDER BY total_emendas DESC;

-- ─── View: circuito fechado — doou E recebeu emenda do mesmo parlamentar ──────
-- Nota: o join usa codigo_autor × id_camara pois nomes podem divergir por grafia
CREATE OR REPLACE VIEW public.v_bets_circuito_completo AS
SELECT
  d.cnpj,
  d.operadora,
  d.marcas,
  d.nome_candidato              AS candidato_financiado,
  d.cargo,
  d.sigla_partido,
  d.uf,
  d.ano_eleicao,
  d.total_doado,
  e.total_emendas,
  e.num_transferencias          AS num_emendas_recebidas
FROM public.v_bets_doadores_campanha d
JOIN public.parlamentares p
  ON p.cpf = d.cpf_candidato
JOIN public.v_bets_favorecidas_emendas e
  ON e.cnpj = d.cnpj
  AND e.codigo_autor = p.id_camara::text
ORDER BY (d.total_doado + COALESCE(e.total_emendas, 0)) DESC;
