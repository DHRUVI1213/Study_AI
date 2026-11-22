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
    const { document_id, quiz_type, question_count = 10 } = await req.json();

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

    const prompt = `You are an expert tutor. Generate a quiz based on the following study material.
    
    QUIZ TYPE: ${quiz_type}
    NUMBER OF QUESTIONS: ${question_count} (You MUST generate exactly ${question_count} questions. Do not generate fewer than 10.)
    
    You MUST respond with a JSON object matching this structure:
    {
      "title": "A short descriptive title for the quiz",
      "quiz_type": "${quiz_type}",
      "questions": [
        {
          "question": "The question text",
          "options": ["Option A", "Option B", "Option C", "Option D"], // Only include if quiz_type is 'mcq' or 'true_false'. For 'true_false', the options MUST be ["True", "False"]. For short_answer/descriptive, set to null or omit.
          "correct_answer": "The exact string representing the correct answer (for MCQ/TF, it must match one of the options)",
          "explanation": "A helpful explanation of why this answer is correct"
        }
      ]
    }
    
    STUDY MATERIAL:
    ${context}
    `;

    let quizJsonText = "";
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
          quizJsonText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
          if (quizJsonText) {
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

    if (!quizJsonText) {
      throw new Error("Failed to receive structured quiz response from Gemini");
    }

    const quizData = JSON.parse(quizJsonText);
    let questionsList: any[] = [];
    let quizTitle = `${doc.title} Quiz`;
    
    if (quizData && Array.isArray(quizData.questions)) {
      questionsList = quizData.questions;
      quizTitle = quizData.title ?? quizTitle;
    } else if (Array.isArray(quizData)) {
      questionsList = quizData;
    } else if (quizData && typeof quizData === "object") {
      quizTitle = quizData.title ?? quizTitle;
      for (const key of Object.keys(quizData)) {
        if (Array.isArray(quizData[key])) {
          questionsList = quizData[key];
          break;
        }
      }
    }
    
    const formattedQuestions = questionsList.map((q: any) => {
      const questionText = q.question ?? q.text ?? q.q ?? "";
      const options = q.options ?? q.choices ?? q.answers ?? null;
      const correctAnswer = q.correct_answer ?? q.correctAnswer ?? q.answer ?? "";
      const explanation = q.explanation ?? q.reason ?? "";
      return {
        question: String(questionText),
        options: Array.isArray(options) ? options.map(o => String(o)) : null,
        correct_answer: String(correctAnswer),
        explanation: String(explanation),
      };
    }).filter(q => q.question.trim() !== "");

    // Insert into DB
    const { data: newQuiz, error: insertError } = await supabase
      .from("quizzes")
      .insert({
        user_id: user.id,
        document_id: document_id,
        title: quizTitle,
        quiz_type: quiz_type,
        questions: formattedQuestions,
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify(newQuiz), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
