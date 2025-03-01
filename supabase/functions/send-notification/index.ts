import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createSupabaseClient();
    const { to_user_id, title, body, data } = await req.json();

    const tokens = await getDeviceTokens(supabaseAdmin, to_user_id);
    if (!tokens) {
      return createErrorResponse("Usuário de destino não tem tokens registrados");
    }

    const fcmAccessToken = await getFcmAccessToken();
    const responses = await sendNotifications(tokens, title, body, data, fcmAccessToken);

    return new Response(JSON.stringify({ success: true, responses }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Erro:", error);
    return createErrorResponse(error.message, 400);
  }
});

const createSupabaseClient = () => {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );
};

const getDeviceTokens = async (supabaseAdmin, to_user_id) => {
  const { data: tokens, error } = await supabaseAdmin
    .from("device_tokens")
    .select("token")
    .eq("user_id", to_user_id);

  if (error) throw new Error(`Erro ao buscar tokens: ${error.message}`);
  return tokens.length ? tokens : null;
};

const getFcmAccessToken = async () => {
  const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!serviceAccountJson) throw new Error("Variável de ambiente FCM_SERVICE_ACCOUNT não definida");

  const serviceAccount = JSON.parse(serviceAccountJson);
  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error("FCM_SERVICE_ACCOUNT deve conter client_email e private_key");
  }

  const jwt = await createJWT({
    alg: "RS256",
    typ: "JWT"
  }, {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: `https://oauth2.googleapis.com/token`,
    exp: Math.floor(Date.now() / 1000) + 3600,
    iat: Math.floor(Date.now() / 1000),
  }, serviceAccount.private_key);

  const response = await fetch(`https://oauth2.googleapis.com/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!response.ok) throw new Error(`Erro ao obter token OAuth 2.0: ${await response.text()}`);
  return (await response.json()).access_token;
};

const sendNotifications = async (tokens, title, body, data, fcmAccessToken) => {
  const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/servblu-d9b69/messages:send`;

  return Promise.all(
    tokens.map(async ({ token }) => {
      const fcmPayload = {
        message: {
          token,
          notification: { title, body },
          data: data || {},
        },
      };

      const fcmResponse = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${fcmAccessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      });

      if (!fcmResponse.ok) {
        const errorText = await fcmResponse.text();
        console.error(`Erro ao enviar notificação: ${errorText}`);
        throw new Error(`FCM error: ${errorText}`);
      }

      return await fcmResponse.json();
    })
  );
};

const createJWT = async (header, payload, privateKey) => {
  const encoder = new TextEncoder();
  const pemContents = privateKey.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: { name: "SHA-256" } },
    false,
    ["sign"]
  );

  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "");
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "");
  const dataToSign = encoder.encode(`${encodedHeader}.${encodedPayload}`);

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5", hash: { name: "SHA-256" } },
    key,
    dataToSign
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return `${encodedHeader}.${encodedPayload}.${encodedSignature}`;
};

const createErrorResponse = (message, status = 400) => {
  return new Response(
    JSON.stringify({ error: message }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" }, status }
  );
};
