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
    const { document_id, count = 15 } = await req.json();

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

    // Check if flashcards already exist
    const { data: existingCards } = await supabase
      .from("flashcards")
      .select("*")
      .eq("document_id", document_id)
      .eq("user_id", user.id);

    if (existingCards && existingCards.length > 0) {
      return new Response(JSON.stringify({ flashcards: existingCards }), {
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

    const prompt = `You are an expert tutor. Extract the key terms, definitions, questions, and important concepts from the following study material and represent them as flashcards. You MUST generate at least 10 flashcards (up to ${count} total). Do not generate fewer than 10 flashcards.
    
    You MUST respond with a JSON object matching this structure:
    {
      "flashcards": [
        {
          "front": "The term or question on the front of the card",
          "back": "The definition, answer, or explanation on the back of the card"
        }
      ]
    }
    
    STUDY MATERIAL:
    ${context}
    `;

    let flashcardsJsonText = "";
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
                  text: prompt,
                }],
              }],
              generationConfig: {
                responseMimeType: "application/json",
              },
            }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          flashcardsJsonText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
          if (flashcardsJsonText) {
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

    if (!flashcardsJsonText) {
      throw new Error("Failed to receive structured flashcards from Gemini");
    }

    const parsedData = JSON.parse(flashcardsJsonText);
    let flashcardsList: any[] = [];
    
    if (Array.isArray(parsedData)) {
      flashcardsList = parsedData;
    } else if (parsedData && Array.isArray(parsedData.flashcards)) {
      flashcardsList = parsedData.flashcards;
    } else if (parsedData && typeof parsedData === "object") {
      for (const key of Object.keys(parsedData)) {
        if (Array.isArray(parsedData[key])) {
          flashcardsList = parsedData[key];
          break;
        }
      }
    }

    const cardsToInsert = flashcardsList.map((c: any) => {
      const front = c.front ?? c.question ?? c.q ?? c.term ?? c.key ?? "";
      const back = c.back ?? c.answer ?? c.a ?? c.definition ?? c.value ?? "";
      return {
        user_id: user.id,
        document_id: document_id,
        front: String(front),
        back: String(back),
      };
    }).filter(c => c.front.trim() !== "" && c.back.trim() !== "");

    const { data: insertedCards, error: insertError } = await supabase
      .from("flashcards")
      .insert(cardsToInsert)
      .select();

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify({ flashcards: insertedCards }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
