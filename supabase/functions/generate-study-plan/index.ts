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
    const { exam_date, daily_hours, subjects } = await req.json();

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

    const todayStr = new Date().toISOString().split('T')[0];

    const prompt = `You are an expert study planner. Create a customized day-by-day study schedule for a student based on these inputs:
    
    EXAM DATE: ${exam_date}
    DAILY HOURS DEVOTED: ${daily_hours}
    SUBJECTS TO STUDY: ${subjects.join(", ")}
    CURRENT DATE: ${todayStr}
    
    You MUST respond with a JSON object containing a "schedule" array. Each item in the array represents a single study day:
    {
      "schedule": [
        {
          "date": "YYYY-MM-DD",
          "focus": "Subject Name",
          "topics": [
            "Specific topic to study (e.g. Chapter 1 review)",
            "Another topic or practice task (e.g. Solve sample questions)"
          ]
        }
      ]
    }
    
    Make the schedule logical, spreading subjects evenly, and allocate time based on daily hours.
    `;

    let planJsonText = "";
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
          planJsonText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
          if (planJsonText) {
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

    if (!planJsonText) {
      throw new Error("Failed to receive structured study plan from Gemini");
    }

    const parsedPlan = JSON.parse(planJsonText);
    let scheduleList: any[] = [];
    
    if (parsedPlan && Array.isArray(parsedPlan.schedule)) {
      scheduleList = parsedPlan.schedule;
    } else if (Array.isArray(parsedPlan)) {
      scheduleList = parsedPlan;
    } else if (parsedPlan && typeof parsedPlan === "object") {
      for (const key of Object.keys(parsedPlan)) {
        if (Array.isArray(parsedPlan[key])) {
          scheduleList = parsedPlan[key];
          break;
        }
      }
    }
    
    const formattedSchedule = scheduleList.map((d: any) => {
      const date = d.date ?? d.day ?? "";
      const focus = d.focus ?? d.subject ?? "";
      const topics = d.topics ?? d.tasks ?? [];
      return {
        date: String(date),
        focus: String(focus),
        topics: Array.isArray(topics) ? topics.map(t => String(t)) : [],
      };
    });
    
    const finalPlan = { schedule: formattedSchedule };

    // Insert into DB
    const { data: newPlan, error: insertError } = await supabase
      .from("study_plans")
      .insert({
        user_id: user.id,
        exam_date: exam_date,
        daily_hours: daily_hours,
        subjects: subjects,
        plan_content: finalPlan,
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    return new Response(JSON.stringify(newPlan), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
