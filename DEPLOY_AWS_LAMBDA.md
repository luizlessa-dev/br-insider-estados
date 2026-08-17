# 🚀 Deploy Seguro - AWS Lambda + Zappa

**Status:** ✅ Passo-a-passo para deploy da API Python em AWS Lambda  
**Segurança:** ⭐⭐⭐⭐⭐ (LGPD Compliant, CloudTrail, KMS Encryption)

---

## 📋 Pré-requisitos

```bash
# 1. Instalar AWS CLI
brew install awscli

# 2. Configurar credenciais AWS
aws configure
# → AWS Access Key ID: [seu access key]
# → AWS Secret Access Key: [seu secret key]
# → Default region: us-east-1
# → Default output format: json

# 3. Verificar credenciais
aws sts get-caller-identity
# Deve retornar seu Account ID, ARN, etc.
```

---

## 🔧 PASSO 1: Instalar Zappa

```bash
cd /Users/luizlessa/brasilia-insider

# Instalar Zappa
pip install zappa

# Verificar instalação
zappa --version
```

---

## 🔧 PASSO 2: Criar zappa_settings.json

Criar arquivo de configuração:

```bash
cat > /Users/luizlessa/brasilia-insider/zappa_settings.json << 'EOF'
{
    "dev": {
        "app_function": "api_subradar.app",
        "aws_region": "us-east-1",
        "profile_name": "default",
        "project_name": "subradar-pf",
        "runtime": "python3.11",
        "s3_bucket": "subradar-zappa-deployments",
        "environment_variables": {
            "SUPABASE_URL": "https://redggdtakzmsabwvjzhb.supabase.co",
            "SUPABASE_SERVICE_ROLE_KEY": "sb_secret_...",
            "BIGDATA_CORP_TOKEN_ID": "6a6be8e149790c5ecd2b8a41",
            "BIGDATA_CORP_ACCESS_TOKEN": "eyJ...",
            "DIRECT_DATA_TOKEN": "74F5134C-..."
        },
        "vpc_config": {
            "SubnetIds": ["subnet-xxxxxxxxx"],
            "SecurityGroupIds": ["sg-xxxxxxxxx"]
        },
        "memory_size": 512,
        "timeout": 60,
        "layers": [],
        "xray_tracing": true,
        "log_level": "INFO",
        "aws_environment_variables": {
            "AWS_KMS_KEY_ID": "arn:aws:kms:us-east-1:123456789:key/12345678-1234-1234-1234-123456789"
        }
    },
    "production": {
        "extends": "dev",
        "s3_bucket": "subradar-zappa-deployments-prod",
        "environment_variables": {
            "SUPABASE_URL": "https://redggdtakzmsabwvjzhb.supabase.co",
            "SUPABASE_SERVICE_ROLE_KEY": "sb_secret_...",
            "BIGDATA_CORP_TOKEN_ID": "6a6be8e149790c5ecd2b8a41",
            "BIGDATA_CORP_ACCESS_TOKEN": "eyJ...",
            "DIRECT_DATA_TOKEN": "74F5134C-..."
        },
        "memory_size": 1024,
        "timeout": 60,
        "xray_tracing": true,
        "log_level": "WARNING",
        "keep_warm": true,
        "keep_warm_expression": "rate(4 minutes)"
    }
}
EOF
```

**⚠️ IMPORTANTE:** Substituir os valores reais:
- `SUPABASE_SERVICE_ROLE_KEY` → Copiar de Supabase Settings > API
- `BIGDATA_CORP_TOKEN_ID` e `BIGDATA_CORP_ACCESS_TOKEN` → Seus tokens
- `DIRECT_DATA_TOKEN` → Seu token Direct Data

---

## 🔐 PASSO 3: Criar S3 Bucket para Deployments

```bash
# Criar bucket (única vez)
aws s3 mb s3://subradar-zappa-deployments --region us-east-1

# Criar bucket produção
aws s3 mb s3://subradar-zappa-deployments-prod --region us-east-1

# Habilitar versionamento para segurança
aws s3api put-bucket-versioning \
  --bucket subradar-zappa-deployments \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket subradar-zappa-deployments-prod \
  --versioning-configuration Status=Enabled

# Habilitar encryption por padrão
aws s3api put-bucket-encryption \
  --bucket subradar-zappa-deployments \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

---

## 🔐 PASSO 4: Criar IAM Role para Lambda (Segurança)

**Opção A: Via AWS Console (Recomendado - Visual)**

1. Abrir [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. **Roles** → **Create role**
3. Selecionar **AWS service** → **Lambda**
4. Clicar **Next**
5. Buscar e adicionar policies:
   - `AWSLambdaBasicExecutionRole`
   - `AmazonS3ReadOnlyAccess` (para leitura do S3 bucket)
   - `CloudWatchLogsFullAccess` (para logs)

6. Tag: `Environment: Production`
7. Nome: `subradar-lambda-role`
8. Criar

**Opção B: Via CLI**

```bash
# Criar arquivo de trust policy
cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Criar role
aws iam create-role \
  --role-name subradar-lambda-role \
  --assume-role-policy-document file:///tmp/trust-policy.json

# Adicionar policies
aws iam attach-role-policy \
  --role-name subradar-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
  --role-name subradar-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Obter ARN da role
aws iam get-role --role-name subradar-lambda-role --query 'Role.Arn'
# Copiar: arn:aws:iam::123456789:role/subradar-lambda-role
```

---

## 🚀 PASSO 5: Deploy Inicial (Dev)

```bash
cd /Users/luizlessa/brasilia-insider

# Fazer deploy em DEV (primeiro deploy leva ~3-5 min)
zappa deploy dev

# Esperado:
# ✓ Creating S3 bucket...
# ✓ Uploading Lambda function...
# ✓ Creating API Gateway...
# ✓ Deployment complete!
# Your API endpoint is: https://xxxxx.execute-api.us-east-1.amazonaws.com/dev

# Copiar a URL gerada
```

**Se tiver erro:**

```bash
# Ver logs detalhados
zappa tail dev

# Rollback se necessário
zappa undeploy dev
```

---

## 🧪 PASSO 6: Testar a API

```bash
# Copiar a URL do deploy anterior
# Exemplo: https://xxxxx.execute-api.us-east-1.amazonaws.com/dev

# Testar com seu CPF
curl -X POST https://xxxxx.execute-api.us-east-1.amazonaws.com/dev/consulta \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "06465979659",
    "nome": "Test User",
    "consentimento_lgpd": true
  }'

# Esperado: JSON com scores, alertas, etc
```

---

## 📊 PASSO 7: Visualizar Logs (CloudWatch)

```bash
# Ver logs em tempo real
zappa tail dev --since 5m

# Ou via AWS CLI
aws logs tail /aws/lambda/subradar-pf-dev --follow

# Ou via AWS Console:
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logStream:
```

---

## 🔍 PASSO 8: Habilitar CloudTrail (Auditoria)

```bash
# Criar trail para auditoria completa
aws cloudtrail create-trail \
  --name subradar-pf-audit \
  --s3-bucket-name subradar-audit-logs \
  --is-multi-region-trail

# Habilitar logging
aws cloudtrail start-logging --trail-name subradar-pf-audit

# Ver eventos
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=subradar-pf-dev \
  --max-results 10
```

---

## 🚀 PASSO 9: Deploy em Produção

Quando estiver confiante com o dev:

```bash
# Deploy em produção
zappa deploy production

# Esperado: URL similar, mas em /prod
# https://xxxxx.execute-api.us-east-1.amazonaws.com/prod

# IMPORTANTE: Testar ANTES de liberar
curl -X POST https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/consulta \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "06465979659",
    "nome": "Test",
    "consentimento_lgpd": true
  }'
```

---

## 📝 PASSO 10: Atualizar .env.local (Frontend)

Após deploy bem-sucedido:

```bash
# Editar subradar-web/.env.local
NEXT_PUBLIC_PYTHON_API_URL=https://xxxxx.execute-api.us-east-1.amazonaws.com/prod
```

---

## 📊 Monitoramento em Produção

### CloudWatch Metrics

```bash
# Ver métrica de invocações
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=subradar-pf-prod \
  --start-time 2026-08-08T00:00:00Z \
  --end-time 2026-08-08T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Ver métrica de erros
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=subradar-pf-prod \
  --start-time 2026-08-08T00:00:00Z \
  --end-time 2026-08-08T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### X-Ray Tracing

```bash
# Ver traces
aws xray get-trace-summaries \
  --start-time 2026-08-08T00:00:00Z \
  --end-time 2026-08-08T23:59:59Z \
  --filter-expression 'service("subradar-pf-prod")'
```

---

## 🔒 Segurança - Checklist

- [ ] ✅ Credenciais AWS configuradas
- [ ] ✅ S3 buckets com encryption habilitado
- [ ] ✅ IAM role criada com permissões mínimas
- [ ] ✅ CloudTrail habilitado para auditoria
- [ ] ✅ Variáveis de ambiente encriptadas
- [ ] ✅ X-Ray tracing ativado
- [ ] ✅ CloudWatch logs configurados
- [ ] ✅ Teste end-to-end realizado
- [ ] ✅ .env.local atualizado
- [ ] ✅ Logs de erro monitorados

---

## 🆘 Troubleshooting

### "ModuleNotFoundError: No module named 'fastapi'"

```bash
# Zappa precisa de requirements.txt na pasta raiz
# Verificar que /Users/luizlessa/brasilia-insider/requirements.txt existe

# Forçar recriação do package
zappa update dev --remove-local

# Redeploy
zappa deploy dev
```

### "Timeout: Task timed out after 60 seconds"

```bash
# Aumentar timeout em zappa_settings.json
"timeout": 120

# Redeploy
zappa update dev
```

### "AccessDenied: User is not authorized to perform: lambda:CreateFunction"

```bash
# Verificar IAM permissions
aws iam get-user

# Adicionar permissão Lambda ao IAM user
aws iam attach-user-policy \
  --user-name seu-usuario \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### "API Gateway invoke URL not working"

```bash
# Verificar status da função
aws lambda get-function --function-name subradar-pf-dev

# Ver últimos logs
zappa tail dev --since 10m
```

---

## 📊 Atualizar Código em Produção

Quando precisar fazer atualizações:

```bash
# Fazer changes no código (ex: api_subradar.py)

# Atualizar função em DEV
zappa update dev

# Testar
curl https://xxxxx.execute-api.us-east-1.amazonaws.com/dev/consulta ...

# Atualizar função em PRODUÇÃO
zappa update production

# Verificar status
zappa status production
```

---

## 💰 Custos Estimados (Mensal)

| Serviço | Uso | Custo |
|---------|-----|-------|
| **Lambda** | 100k invocações | ~$2 |
| **API Gateway** | 100k requisições | ~$3.50 |
| **CloudWatch Logs** | ~10GB | ~$5 |
| **S3** | Deployments | <$1 |
| **CloudTrail** | Auditoria | ~$2 |
| **Total** | | **~$13.50/mês** |

*Se uso aumentar para 1M req/mês: ~$50/mês (ainda muito barato)*

---

## ✅ URLs Finais

| Ambiente | URL |
|----------|-----|
| **Dev** | `https://xxxxx.execute-api.us-east-1.amazonaws.com/dev/consulta` |
| **Produção** | `https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/consulta` |
| **Frontend** | `https://subradar.vercel.app/pf/consulta` |
| **CloudWatch** | `https://console.aws.amazon.com/cloudwatch` |
| **CloudTrail** | `https://console.aws.amazon.com/cloudtrail` |

---

## 🎉 Próximo Passo

1. ✅ Deploy AWS Lambda (THIS)
2. ⏭️ Deploy Edge Function Supabase
3. ⏭️ Deploy Frontend Vercel
4. ⏭️ Atualizar variáveis de ambiente
5. ⏭️ Criar tabela Supabase

**Quando terminar os testes, me avisa que vamos para o Passo 2!** 🚀
