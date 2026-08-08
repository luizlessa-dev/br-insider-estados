// Supabase Edge Function — Processa consulta Subradar PF
//
// Fluxo:
// 1. Edge Function /dossiee recebe CPF + email
// 2. Registra na fila (sub_pf_queue)
// 3. Este Function monitora a fila
// 4. Chama Python runner via HTTP (localhost:8000)
// 5. Aguarda conclusão
// 6. Executa /dossiee para gerar PDF + email

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface ProcessRequest {
  cpf: string;
  nome: string;
  email: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

async function callRunnerPF(cpf: string, nome: string): Promise<any> {
  const runnerUrl = Deno.env.get("RUNNER_PF_URL") || "http://localhost:8000";

  try {
    const response = await fetch(`${runnerUrl}/consulta`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        cpf: cpf.replace(/\D/g, "").padStart(11, "0"),
        nome: nome,
        cliente_id: crypto.randomUUID(),
      }),
    });

    if (!response.ok) {
      throw new Error(`Runner retornou ${response.status}`);
    }

    return await response.json();
  } catch (err) {
    console.error("Erro ao chamar runner PF:", err);
    throw err;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Método não permitido", { status: 405, headers: corsHeaders });
  }

  try {
    const payload = await req.json() as ProcessRequest;
    const { cpf, nome, email } = payload;

    if (!cpf || !nome || !email) {
      return new Response(
        JSON.stringify({ erro: "cpf, nome e email são obrigatórios" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Processando: ${cpf} — ${nome}`);

    // Chama runner PF
    const resultado = await callRunnerPF(cpf, nome);

    if (!resultado.sucesso) {
      return new Response(
        JSON.stringify({ erro: resultado.erro || "Erro ao processar" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Agora chama o dossiee para gerar PDF + enviar email
    const docsieUrl = Deno.env.get("DOSSIEE_URL") ||
                      `https://${new URL(req.url).host}/functions/v1/dossiee`;

    const pdfResponse = await fetch(docsieUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        cpf: cpf.replace(/\D/g, "").padStart(11, "0"),
        nome: nome,
        email: email,
        action: "send",
      }),
    });

    if (pdfResponse.ok) {
      return new Response(
        JSON.stringify({
          sucesso: true,
          mensagem: "Consulta processada e email enviado",
          score: resultado.score,
          faixa: resultado.faixa,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      return new Response(
        JSON.stringify({
          sucesso: true,
          mensagem: "Consulta processada (PDF pendente)",
          score: resultado.score,
          faixa: resultado.faixa,
        }),
        { status: 202, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (err) {
    console.error("Erro:", err);
    return new Response(
      JSON.stringify({ erro: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
