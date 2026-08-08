import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  PDFDocument,
  rgb,
  StandardFonts,
  PDFPage,
} from "https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1/dist/pdf-lib.esm.js";

interface DossieRequest {
  cpf: string;
  nome: string;
  email: string;
  action: "send" | "generate";
}

interface AlertaRecord {
  titulo: string;
  descricao: string;
  severidade: "critico" | "atencao" | "info";
}

interface DossieData {
  cpf: string;
  nome: string;
  score: number;
  faixa: "BAIXO" | "MÉDIO" | "ALTO" | "CRÍTICO";
  alertas: AlertaRecord[];
}

// ── Cores ─────────────────────────────────────────────────────────────
const COLORS = {
  slate900: rgb(15 / 255, 23 / 255, 42 / 255),
  slate400: rgb(148 / 255, 163 / 255, 184 / 255),
  slate500: rgb(100 / 255, 116 / 255, 139 / 255),
  slate200: rgb(226 / 255, 232 / 255, 240 / 255),
  red600: rgb(220 / 255, 38 / 255, 38 / 255),
  red50: rgb(254 / 255, 242 / 255, 242 / 255),
  green700: rgb(21 / 255, 128 / 255, 61 / 255),
  green50: rgb(240 / 255, 253 / 255, 244 / 255),
  amber600: rgb(217 / 255, 119 / 255, 6 / 255),
  amber50: rgb(255 / 255, 251 / 255, 235 / 255),
  orange600: rgb(234 / 255, 88 / 255, 12 / 255),
  orange50: rgb(254 / 255, 215 / 255, 170 / 255),
  white: rgb(255 / 255, 255 / 255, 255 / 255),
  black: rgb(0, 0, 0),
};

function fmtCpf(cpf: string): string {
  const d = cpf.replace(/\D/g, "").padStart(11, "0").slice(0, 11);
  return `${d.slice(0, 3)}.${d.slice(3, 6)}.${d.slice(6, 9)}-${d.slice(9)}`;
}

function getRiskTheme(faixa: string): {
  label: string;
  color: any;
  bgColor: any;
} {
  const themes: Record<string, any> = {
    BAIXO: {
      label: "BAIXO",
      color: COLORS.green700,
      bgColor: COLORS.green50,
    },
    MÉDIO: {
      label: "MÉDIO",
      color: COLORS.amber600,
      bgColor: COLORS.amber50,
    },
    ALTO: {
      label: "ALTO",
      color: COLORS.orange600,
      bgColor: COLORS.orange50,
    },
    CRÍTICO: {
      label: "CRÍTICO",
      color: COLORS.red600,
      bgColor: COLORS.red50,
    },
  };
  return themes[faixa.toUpperCase()] || themes.BAIXO;
}

async function buildPdfPf(data: DossieData): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  const page = doc.addPage([595, 842]); // A4
  const W = 595;
  const H = 842;
  const MARGIN = 40;
  const INNER = W - 2 * MARGIN;

  const helvetica = await doc.embedFont(StandardFonts.Helvetica);
  const helveticaBold = await doc.embedFont(StandardFonts.HelveticaBold);

  const theme = getRiskTheme(data.faixa);
  let y = H - MARGIN;

  // ── Cabeçalho escuro ────────────────────────────────────────────
  const HDR_H = 45;
  page.drawRectangle({
    x: 0,
    y: H - HDR_H,
    width: W,
    height: HDR_H,
    color: COLORS.slate900,
  });

  page.drawText("SUBRADAR", {
    x: MARGIN,
    y: H - HDR_H + 20,
    size: 13,
    font: helveticaBold,
    color: COLORS.white,
  });

  page.drawText("COMPLIANCE PF", {
    x: MARGIN,
    y: H - HDR_H + 6,
    size: 7,
    font: helvetica,
    color: COLORS.slate400,
  });

  const today = new Date().toLocaleDateString("pt-BR");
  page.drawText(`DOSSIÊ DE COMPLIANCE  ·  ${today}`, {
    x: W - MARGIN - 180,
    y: H - HDR_H + 16,
    size: 7,
    font: helveticaBold,
    color: COLORS.slate400,
  });

  y = H - HDR_H - 15;

  // ── Faixa hero vermelha ────────────────────────────────────────
  const HERO_H = 75;
  page.drawRectangle({
    x: 0,
    y: y - HERO_H,
    width: W,
    height: HERO_H,
    color: COLORS.red600,
  });

  // Nome
  page.drawText(data.nome.slice(0, 48), {
    x: MARGIN,
    y: y - HERO_H + 52,
    size: 13,
    font: helveticaBold,
    color: COLORS.white,
  });

  // CPF
  page.drawText(`CPF  ${fmtCpf(data.cpf)}`, {
    x: MARGIN,
    y: y - HERO_H + 30,
    size: 8,
    font: helvetica,
    color: rgb(252 / 255, 165 / 255, 165 / 255),
  });

  // Score (grande) - centralizado à direita
  const scoreX = W - MARGIN - 60;
  page.drawText(String(data.score), {
    x: scoreX,
    y: y - HERO_H + 22,
    size: 38,
    font: helveticaBold,
    color: COLORS.white,
  });

  page.drawText(theme.label, {
    x: scoreX,
    y: y - HERO_H + 2,
    size: 8,
    font: helveticaBold,
    color: rgb(252 / 255, 165 / 255, 165 / 255),
  });

  y -= HERO_H + 35;

  // ── Resultado ──────────────────────────────────────────────────
  page.drawText("Resultado da avaliação", {
    x: MARGIN,
    y,
    size: 9,
    font: helveticaBold,
    color: COLORS.slate600 || COLORS.slate500,
  });
  y -= 20;

  const resumos: Record<string, string> = {
    BAIXO: "Nenhum indício relevante de risco foi identificado para o titular.",
    MÉDIO:
      "Foram identificados pontos de atenção que recomendam monitoramento periódico.",
    ALTO: "Indícios relevantes de risco exigem diligência reforçada.",
    CRÍTICO:
      "Risco crítico identificado. Recomenda-se apuração jurídica antes de qualquer contratação.",
  };

  const resumoTxt = resumos[data.faixa] || "Status indeterminado.";
  page.drawText(
    `O titular ${data.nome} (CPF ${fmtCpf(data.cpf)}) obteve score de ${data.score}/100, classificado na faixa ${theme.label}.`,
    {
      x: MARGIN,
      y,
      size: 8.5,
      font: helvetica,
      color: COLORS.slate500,
      maxWidth: W - 2 * MARGIN,
    }
  );
  y -= 25;

  page.drawText(resumoTxt, {
    x: MARGIN,
    y,
    size: 8.5,
    font: helvetica,
    color: COLORS.slate500,
    maxWidth: W - 2 * MARGIN,
  });
  y -= 35;

  // ── Escala de risco ────────────────────────────────────────────
  page.drawText("Escala de risco", {
    x: MARGIN,
    y,
    size: 8,
    font: helveticaBold,
    color: COLORS.slate600 || COLORS.slate500,
  });
  y -= 16;

  // Tabela faixas com melhor alinhamento
  const faixas = [
    { label: "BAIXO", score: "0–20", color: COLORS.green700 },
    { label: "MÉDIO", score: "21–50", color: COLORS.amber600 },
    { label: "ALTO", score: "51–80", color: COLORS.orange600 },
    { label: "CRÍTICO", score: "81–100", color: COLORS.red600 },
  ];

  for (const f of faixas) {
    // Caixa colorida com label
    const boxW = 65;
    page.drawRectangle({
      x: MARGIN,
      y: y - 16,
      width: boxW,
      height: 16,
      color: f.color,
    });
    page.drawText(f.label, {
      x: MARGIN + 6,
      y: y - 13,
      size: 7.5,
      font: helveticaBold,
      color: COLORS.white,
    });

    // Score ao lado
    page.drawText(f.score, {
      x: MARGIN + boxW + 12,
      y: y - 13,
      size: 7,
      font: helvetica,
      color: COLORS.slate600 || COLORS.slate500,
    });
    y -= 19;
  }

  y -= 12;

  // ── Alertas ────────────────────────────────────────────────────
  if (data.alertas && data.alertas.length > 0) {
    page.drawText("Ocorrências encontradas", {
      x: MARGIN,
      y,
      size: 8,
      font: helveticaBold,
      color: COLORS.slate600 || COLORS.slate500,
    });
    y -= 16;

    for (const alerta of data.alertas.slice(0, 4)) {
      const sevMap: Record<string, any> = {
        critico: { color: COLORS.red600, bg: COLORS.red50 },
        atencao: { color: COLORS.amber600, bg: COLORS.amber50 },
        info: { color: COLORS.slate500, bg: COLORS.amber50 },
      };
      const sev = sevMap[alerta.severidade] || sevMap.info;

      // Cabeçalho do alerta
      const HDR_ALERT = 13;
      page.drawRectangle({
        x: MARGIN,
        y: y - HDR_ALERT,
        width: INNER,
        height: HDR_ALERT,
        color: sev.color,
      });
      page.drawText(alerta.titulo.slice(0, 55), {
        x: MARGIN + 6,
        y: y - 10,
        size: 7,
        font: helveticaBold,
        color: COLORS.white,
      });
      y -= HDR_ALERT + 1;

      // Corpo do alerta
      const BODY_H = 16;
      page.drawRectangle({
        x: MARGIN,
        y: y - BODY_H,
        width: INNER,
        height: BODY_H,
        color: sev.bg,
      });
      page.drawText(alerta.descricao.slice(0, 70), {
        x: MARGIN + 6,
        y: y - 9,
        size: 6.5,
        font: helvetica,
        color: COLORS.slate500,
        maxWidth: INNER - 12,
      });
      y -= BODY_H + 3;
    }
  } else {
    page.drawText("Nenhuma ocorrência significativa encontrada.", {
      x: MARGIN,
      y,
      size: 8,
      font: helvetica,
      color: COLORS.green700,
    });
    y -= 18;
  }

  y -= 15;

  // ── Rodapé ─────────────────────────────────────────────────────
  page.drawRectangle({
    x: 0,
    y: 0,
    width: W,
    height: 40,
    color: COLORS.slate900,
  });
  page.drawText("Subradar  ·  Lessa Labs Tecnologia Ltda", {
    x: MARGIN,
    y: 10,
    size: 7,
    font: helvetica,
    color: COLORS.slate400,
  });
  page.drawText(`Gerado em ${today}`, {
    x: W - MARGIN - 100,
    y: 10,
    size: 7,
    font: helvetica,
    color: COLORS.slate400,
  });

  const pdfBytes = await doc.save();
  return pdfBytes;
}

async function fetchDossieData(
  cpf: string,
  supabaseUrl: string,
  supabaseKey: string
): Promise<DossieData | null> {
  try {
    // Buscar resultado
    const resultRes = await fetch(
      `${supabaseUrl}/rest/v1/sub_pf_resultados?cpf=eq.${cpf}`,
      {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${supabaseKey}`,
        },
      }
    );
    const results = await resultRes.json();
    if (!results || results.length === 0) return null;

    const resultado = results[0];

    // Buscar alertas
    const alertRes = await fetch(
      `${supabaseUrl}/rest/v1/sub_pf_alertas?cpf=eq.${cpf}`,
      {
        headers: {
          apikey: supabaseKey,
          Authorization: `Bearer ${supabaseKey}`,
        },
      }
    );
    const alertas = await alertRes.json();

    return {
      cpf,
      nome: resultado.nome || "Monitorado",
      score: resultado.score_risco || 0,
      faixa: resultado.faixa_risco || "BAIXO",
      alertas: (alertas || []).map((a: any) => ({
        titulo: a.titulo || "Alerta",
        descricao: a.descricao || "",
        severidade: a.severidade || "info",
      })),
    };
  } catch (error) {
    console.error("Erro ao buscar dados:", error);
    return null;
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

async function sendEmailWithPdf(
  to: string,
  nome: string,
  cpf: string,
  pdfBase64: string
): Promise<{ success: boolean; message: string }> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");

  if (!resendApiKey) {
    console.error("RESEND_API_KEY não configurada");
    return { success: false, message: "API key não configurada" };
  }

  try {
    // Enviar email com attachment (Resend espera base64-encoded string)
    const emailBody = {
      from: "Subradar <onboarding@resend.dev>",
      to: to,
      subject: `Dossiê de Compliance Subradar PF - ${nome}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h1 style="color: #0f172a; font-size: 24px; margin-bottom: 20px;">Dossiê de Compliance</h1>
          <p>Olá <strong>${nome}</strong>,</p>
          <p>Seu dossiê de compliance foi gerado com sucesso pelo <strong>Subradar PF</strong>.</p>
          <p><strong>CPF:</strong> ${fmtCpf(cpf)}</p>
          <p><strong>Data:</strong> ${new Date().toLocaleDateString("pt-BR")}</p>
          <p style="color: #0f172a; font-weight: bold; margin-top: 20px;">Confira o PDF anexado para mais detalhes.</p>
          <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 30px 0;">
          <p style="color: #64748b; font-size: 12px;">
            Este é um email automático. Não responda diretamente.
          </p>
          <p style="color: #64748b; font-size: 12px; margin: 10px 0 0 0;">
            Subradar • Lessa Labs Tecnologia Ltda
          </p>
        </div>
      `,
      attachments: [
        {
          filename: `dossiee_${cpf.replace(/\D/g, "")}.pdf`,
          content: pdfBase64,
        },
      ],
    };

    console.log(`Enviando email para ${to}...`);
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(emailBody),
    });

    const responseText = await response.text();
    console.log(`Resend response status: ${response.status}`);
    console.log(`Resend response: ${responseText}`);

    let responseData;
    try {
      responseData = JSON.parse(responseText);
    } catch {
      return {
        success: false,
        message: `Resposta inválida: ${responseText.slice(0, 100)}`,
      };
    }

    if (!response.ok) {
      console.error("Erro Resend API:", responseData);
      return {
        success: false,
        message: responseData.message || "Erro ao enviar email",
      };
    }

    console.log("Email enviado com sucesso:", responseData);
    return { success: true, message: "Email enviado" };
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error("Exceção ao enviar email:", errorMsg);
    return { success: false, message: errorMsg };
  }
}

const handler = async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as DossieRequest;
    const { cpf, nome, email, action } = body;

    if (!cpf || !nome || !email) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Campos obrigatórios ausentes",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    // Buscar dados do Supabase
    const dossieData = await fetchDossieData(cpf, supabaseUrl, supabaseKey);

    // Se não houver dados, usar valores mock
    const finalData: DossieData = dossieData || {
      cpf,
      nome,
      score: 25,
      faixa: "MÉDIO",
      alertas: [],
    };

    // Gerar PDF
    const pdfBytes = await buildPdfPf(finalData);
    const pdfBase64 = btoa(String.fromCharCode(...pdfBytes));

    if (action === "send") {
      // Enviar por email
      try {
        const emailResult = await sendEmailWithPdf(email, nome, cpf, pdfBase64);

        if (!emailResult.success) {
          return new Response(
            JSON.stringify({
              success: false,
              error: emailResult.message || "Falha ao enviar email. Tente novamente.",
            }),
            {
              status: 500,
              headers: { "Content-Type": "application/json", ...corsHeaders },
            }
          );
        }

        return new Response(
          JSON.stringify({
            success: true,
            score: finalData.score,
            faixa: finalData.faixa,
            message: `Dossiê enviado com sucesso para ${email}`,
          }),
          {
            status: 200,
            headers: { "Content-Type": "application/json", ...corsHeaders },
          }
        );
      } catch (emailError) {
        console.error("Erro ao processar envio de email:", emailError);
        return new Response(
          JSON.stringify({
            success: false,
            error: `Erro ao enviar email: ${emailError instanceof Error ? emailError.message : "desconhecido"}`,
          }),
          {
            status: 500,
            headers: { "Content-Type": "application/json", ...corsHeaders },
          }
        );
      }
    } else {
      // Retornar PDF para download
      return new Response(
        JSON.stringify({
          success: true,
          score: finalData.score,
          faixa: finalData.faixa,
          pdf: pdfBase64,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }
  } catch (error) {
    console.error("Erro:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Erro desconhecido",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

serve(handler);
