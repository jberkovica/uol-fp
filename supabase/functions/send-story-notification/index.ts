// Supabase Edge Function for sending story notification emails
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  storyId: string
  kidId: string
  parentEmail: string
  parentName: string
  kidName: string
  storyTitle: string
  approvalMode: 'app' | 'email'
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const resendApiKey = Deno.env.get('RESEND_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseKey)

    const { 
      storyId, 
      kidId, 
      parentEmail, 
      parentName, 
      kidName, 
      storyTitle,
      approvalMode 
    }: EmailRequest = await req.json()

    // Generate secure review token for email approval
    const reviewToken = crypto.randomUUID()
    
    // Store review token in database (expires in 7 days)
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7)
    
    await supabase
      .from('story_review_tokens')
      .insert({
        token: reviewToken,
        story_id: storyId,
        expires_at: expiresAt.toISOString()
      })

    // Construct email content based on approval mode
    let emailHtml = ''
    let subject = `New story from ${kidName}: "${storyTitle}"`

    if (approvalMode === 'email') {
      // Email review mode - include approve/decline links
      const baseUrl = Deno.env.get('APP_URL') || 'http://127.0.0.1:8000'
      const approveUrl = `${baseUrl}/api/review-story?token=${reviewToken}&action=approve`
      const declineUrl = `${baseUrl}/api/review-story?token=${reviewToken}&action=decline`

      emailHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #6B46C1; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .story-info { background-color: white; padding: 20px; border-radius: 10px; margin: 20px 0; }
              .button { display: inline-block; padding: 12px 30px; margin: 10px; text-decoration: none; border-radius: 5px; font-weight: bold; }
              .approve { background-color: #10B981; color: white; }
              .decline { background-color: #EF4444; color: white; }
              .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>📚 New Story from ${kidName}</h1>
              </div>
              <div class="content">
                <p>Hi ${parentName},</p>
                <p>${kidName} has created a new story that needs your review!</p>
                
                <div class="story-info">
                  <h2>${storyTitle}</h2>
                  <p><strong>Created:</strong> ${new Date().toLocaleDateString()}</p>
                </div>
                
                <p>Please review the story and decide whether to approve it:</p>
                
                <div style="text-align: center; margin: 30px 0;">
                  <a href="${approveUrl}" class="button approve">✓ Approve Story</a>
                  <a href="${declineUrl}" class="button decline">✗ Decline Story</a>
                </div>
                
                <p>Or you can review it in the Mira app on your phone.</p>
                
                <div class="footer">
                  <p>This link will expire in 7 days.</p>
                  <p>© Mira Storyteller - Safe stories for curious minds</p>
                </div>
              </div>
            </div>
          </body>
        </html>
      `
    } else {
      // App review mode - just notification
      emailHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #6B46C1; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .story-info { background-color: white; padding: 20px; border-radius: 10px; margin: 20px 0; }
              .button { display: inline-block; padding: 12px 30px; margin: 10px; text-decoration: none; border-radius: 5px; font-weight: bold; background-color: #6B46C1; color: white; }
              .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>📚 New Story from ${kidName}</h1>
              </div>
              <div class="content">
                <p>Hi ${parentName},</p>
                <p>${kidName} has created a new story that's waiting for your review!</p>
                
                <div class="story-info">
                  <h2>${storyTitle}</h2>
                  <p><strong>Created:</strong> ${new Date().toLocaleDateString()}</p>
                </div>
                
                <p>Please open the Mira app to review and approve this story.</p>
                
                <div style="text-align: center; margin: 30px 0;">
                  <a href="${baseUrl}/parent-dashboard" class="button">Open Parent Dashboard</a>
                </div>
                
                <div class="footer">
                  <p>© Mira Storyteller - Safe stories for curious minds</p>
                </div>
              </div>
            </div>
          </body>
        </html>
      `
    }

    // Send email via Resend
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from: 'Mira Storyteller <notifications@lunimuni.com>',
        to: [parentEmail],
        subject: subject,
        html: emailHtml,
      }),
    })

    if (!emailResponse.ok) {
      throw new Error(`Failed to send email: ${await emailResponse.text()}`)
    }

    const data = await emailResponse.json()

    return new Response(
      JSON.stringify({ success: true, emailId: data.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Error sending email:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      },
    )
  }
})