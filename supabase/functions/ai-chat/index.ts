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
    const { session_id, message, document_id } = await req.json();

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

    let context = "";
    if (document_id) {
      const { data: doc } = await supabase
        .from("documents")
        .select("extracted_text, title")
        .eq("id", document_id)
        .eq("user_id", user.id)
        .single();
      context = doc?.extracted_text?.slice(0, 30000) ?? "";
    }

    let reply = "";
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
                  text: `You are a helpful study assistant. Prioritize answering the student's question based on the provided study material. If the answer isn't in the material, or if the material is empty/not provided, answer the question using your general knowledge, and mention that the information is outside their uploaded study materials.\n\nSTUDY MATERIAL:\n${context}\n\nSTUDENT QUESTION: ${message}`,
                }],
              }],
            }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          reply = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
          if (reply) {
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

    if (!reply) {
      reply = "Sorry, I couldn't generate a response. The Gemini API is currently experiencing high demand. Please try again in a few moments.";
    }

    await supabase.from("chat_messages").insert([
      { session_id, role: "user", content: message },
      { session_id, role: "assistant", content: reply },
    ]);

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
