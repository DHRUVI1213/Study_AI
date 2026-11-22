import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { document_id, summary_type } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const authHeader = req.headers.get("Authorization")!;
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check if summary already exists
    const { data: existingSummary } = await supabase
      .from("summaries")
      .select("content")
      .eq("document_id", document_id)
      .eq("summary_type", summary_type)
      .eq("user_id", user.id)
      .maybeSingle();

    if (existingSummary) {
      return new Response(JSON.stringify({ content: existingSummary.content }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get document content
    const { data: doc, error: docError } = await supabase
      .from("documents")
      .select("extracted_text, title")
      .eq("id", document_id)
      .eq("user_id", user.id)
      .single();

    if (docError || !doc) {
      return new Response(JSON.stringify({ error: "Document not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const context = doc.extracted_text?.slice(0, 30000) ?? "";
    if (!context) {
      return new Response(JSON.stringify({ error: "Document has no text content" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let summaryPrompt = "";
    if (summary_type === "short") {
      summaryPrompt = "Generate a short, concise summary (bullet points of the core facts) of the following study material.";
    } else if (summary_type === "medium") {
      summaryPrompt = "Generate a medium-length summary of the following study material, structured with section headings and brief descriptions for each section.";
    } else {
      summaryPrompt = "Generate a comprehensive, detailed set of study notes and summary covering all important topics and details from the following study material.";
    }

    let summaryContent = "";
    const models = [
      "gemini-2.5-flash",
      "gemini-3.5-flash",
      "gemini-flash-latest",
      "gemini-2.0-flash",
      "gemini-3.1-flash-lite"
    ];

    for (const model of models) {
      try {
        console.log(`Trying model: ${model}`);
        const geminiRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${Deno.env.get("GEMINI_API_KEY")}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{
                parts: [{
                  text: `${summaryPrompt}\n\nDOCUMENT TITLE: ${doc.title}\n\nSTUDY MATERIAL:\n${context}`,
                }],
              }],
            }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          summaryContent = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
          if (summaryContent) {
            console.log(`Success with model: ${model}`);
            break;
          }
        } else {
          const errText = await geminiRes.text();
          console.warn(`Model ${model} failed with status ${geminiRes.status}: ${errText}`);
        }
      } catch (e) {
        console.error(`Error trying model ${model}:`, (e as any).message);
      }
    }

    if (!summaryContent) {
      summaryContent = "Could not generate summary.";
    }

    // Insert into DB
    const { error: insertError } = await supabase
      .from("summaries")
      .insert({
        user_id: user.id,
        document_id: document_id,
        summary_type: summary_type,
        content: summaryContent,
      });

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify({ content: summaryContent }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
