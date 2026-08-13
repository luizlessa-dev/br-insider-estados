FROM public.ecr.aws/lambda/python:3.11

# Copiar requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Instalar dependências
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copiar código
COPY api_subradar.py ${LAMBDA_TASK_ROOT}
COPY handler.py ${LAMBDA_TASK_ROOT}
COPY .env ${LAMBDA_TASK_ROOT}

# Pacote ingestao.subradar (conectores) — sem o ingestao/__init__.py real,
# que importa .connectors (pacote de assembleias, não usado aqui)
COPY ingestao/subradar ${LAMBDA_TASK_ROOT}/ingestao/subradar
RUN touch ${LAMBDA_TASK_ROOT}/ingestao/__init__.py

# Set handler
CMD ["handler.handler"]
