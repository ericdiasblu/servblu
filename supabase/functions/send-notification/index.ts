import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    const supabaseClient = createClient(
      Deno.env.get('https://lrwbtpghgmshdtqotsyj.supabase.co') ?? '',
      Deno.env.get('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyd2J0cGdoZ21zaGR0cW90c3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk1OTIsImV4cCI6MjA1NTUzNTU5Mn0.Z53Q-wnvj2ABiASl_FH0tddCdN7dVFqWCeYALruqsC8') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )
    
    const { data: { user } } = await supabaseClient.auth.getUser()
    
    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Não autorizado' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      )
    }
    
    const { to_user_id, title, body, data } = await req.json()
    
    // Verificar permissão do usuário para enviar notificações (implementar sua lógica)
    
    // Buscar tokens do usuário de destino
    const { data: tokens, error: tokensError } = await supabaseClient
      .from('device_tokens')
      .select('token')
      .eq('user_id', to_user_id)
    
    if (tokensError) {
      throw tokensError
    }
    
    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Usuário de destino não tem tokens registrados' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Enviar para o FCM
    const fcmApiKey = Deno.env.get('FCM_SERVER_KEY')
    const fcmEndpoint = 'https://fcm.googleapis.com/fcm/send'
    
    const responses = await Promise.all(
      tokens.map(async ({ token }) => {
        const fcmPayload = {
          to: token,
          notification: {
            title,
            body,
          },
          data: data || {},
        }
        
        const fcmResponse = await fetch(fcmEndpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${fcmApiKey}`,
          },
          body: JSON.stringify(fcmPayload),
        })
        
        return fcmResponse.json()
      })
    )
    
    return new Response(
      JSON.stringify({ success: true, responses }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})