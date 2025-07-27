"""Email review endpoints for story approval."""
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from typing import Optional
import os

from ...services.supabase import get_supabase_service
from ...types.domain import StoryStatus
from ...utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/api", tags=["email-review"])


@router.get("/review-story")
async def review_story_via_email(
    token: str = Query(..., description="Review token from email"),
    action: str = Query(..., description="Action: approve or decline")
):
    """Handle story review from email links."""
    try:
        supabase = get_supabase_service()
        
        # Validate token and get story info
        token_result = supabase.client.table("story_review_tokens").select(
            "*, stories!inner(id, title, kid_id, kids!inner(name, user_id))"
        ).eq("token", token).single().execute()
        
        if not token_result.data:
            return HTMLResponse(
                content=_generate_error_page("Invalid or expired review link"),
                status_code=400
            )
        
        token_data = token_result.data
        story_id = token_data["story_id"]
        story_title = token_data["stories"]["title"]
        kid_name = token_data["stories"]["kids"]["name"]
        
        # Check if token is expired
        from datetime import datetime
        expires_at = datetime.fromisoformat(token_data["expires_at"].replace('Z', '+00:00'))
        if datetime.now(expires_at.tzinfo) > expires_at:
            return HTMLResponse(
                content=_generate_error_page("This review link has expired"),
                status_code=400
            )
        
        # Process the action
        if action == "approve":
            # Update story status to approved
            await supabase.update_story(story_id, {
                "status": StoryStatus.APPROVED.value
            })
            
            # Log the action
            supabase.client.table("story_review_actions").insert({
                "story_id": story_id,
                "user_id": token_data["stories"]["kids"]["user_id"],
                "action": "approve",
                "review_method": "email"
            }).execute()
            
            # Delete the token (one-time use)
            supabase.client.table("story_review_tokens").delete().eq("token", token).execute()
            
            return HTMLResponse(
                content=_generate_success_page(
                    f"✅ Story Approved!",
                    f'"{story_title}" by {kid_name} has been approved.',
                    "The story is now available in your child's library."
                )
            )
            
        elif action == "decline":
            # For decline, we might want to show a form for feedback
            # For now, just mark as declined
            await supabase.update_story(story_id, {
                "status": StoryStatus.REJECTED.value,
                "declined_reason": "Declined via email"
            })
            
            # Log the action
            supabase.client.table("story_review_actions").insert({
                "story_id": story_id,
                "user_id": token_data["stories"]["kids"]["user_id"],
                "action": "decline",
                "review_method": "email",
                "declined_reason": "Declined via email"
            }).execute()
            
            # Delete the token
            supabase.client.table("story_review_tokens").delete().eq("token", token).execute()
            
            return HTMLResponse(
                content=_generate_success_page(
                    f"❌ Story Declined",
                    f'"{story_title}" by {kid_name} has been declined.',
                    "This story will not be shown to your child."
                )
            )
        
        else:
            return HTMLResponse(
                content=_generate_error_page("Invalid action specified"),
                status_code=400
            )
            
    except Exception as e:
        logger.error(f"Error processing email review: {e}")
        return HTMLResponse(
            content=_generate_error_page("An error occurred while processing your request"),
            status_code=500
        )


@router.get("/email-login")
async def email_login(
    token: str = Query(..., description="Review token from email"),
    redirect: str = Query(..., description="Redirect action: edit or decline")
):
    """Handle auto-login from email links and redirect to story preview."""
    try:
        supabase = get_supabase_service()
        
        # Validate token and get story info
        token_result = supabase.client.table("story_review_tokens").select(
            "*, stories!inner(id, title, kid_id, kids!inner(name, user_id))"
        ).eq("token", token).single().execute()
        
        if not token_result.data:
            return HTMLResponse(
                content=_generate_error_page("Invalid or expired review link"),
                status_code=400
            )
        
        token_data = token_result.data
        story_id = token_data["story_id"]
        user_id = token_data["stories"]["kids"]["user_id"]
        
        # Check if token is expired
        from datetime import datetime
        expires_at = datetime.fromisoformat(token_data["expires_at"].replace('Z', '+00:00'))
        if datetime.now(expires_at.tzinfo) > expires_at:
            return HTMLResponse(
                content=_generate_error_page("This review link has expired"),
                status_code=400
            )
        
        # Get user email for login
        user_email = await supabase.get_user_email(user_id)
        if not user_email:
            return HTMLResponse(
                content=_generate_error_page("Unable to find user information"),
                status_code=400
            )
        
        # Generate a Supabase magic link for passwordless login
        try:
            # Generate the magic link with Supabase Auth Admin API
            base_url = os.getenv('FLUTTER_WEB_URL', 'http://localhost:8080')
            redirect_to = f"{base_url}/parent-dashboard?story={story_id}&action={redirect}"
            
            # Use Supabase Admin API to generate a magic link
            result = supabase.client.auth.admin.generate_link(
                type="magiclink",
                email=user_email,
                options={
                    "redirect_to": redirect_to
                }
            )
            
            if result and hasattr(result, 'properties') and result.properties.get('action_link'):
                # Redirect to the magic link
                return RedirectResponse(url=result.properties['action_link'], status_code=302)
            else:
                # Fallback: redirect to login page with pre-filled email
                login_url = f"{base_url}/login?email={user_email}&redirect={redirect_to}"
                return RedirectResponse(url=login_url, status_code=302)
                
        except Exception as e:
            logger.error(f"Failed to generate magic link: {e}")
            # Fallback to regular login
            base_url = os.getenv('FLUTTER_WEB_URL', 'http://localhost:8080')
            login_url = f"{base_url}/login?email={user_email}&redirect=/parent-dashboard?story={story_id}&action={redirect}"
            return RedirectResponse(url=login_url, status_code=302)
            
    except Exception as e:
        logger.error(f"Error processing email login: {e}")
        return HTMLResponse(
            content=_generate_error_page("An error occurred while processing your request"),
            status_code=500
        )


def _generate_success_page(title: str, message: str, subtitle: str) -> str:
    """Generate a success page for email review actions."""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Mira Storyteller - {title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #6B46C1 0%, #8B5CF6 100%);
                margin: 0;
                padding: 20px;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }}
            .container {{
                background: white;
                border-radius: 20px;
                padding: 40px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
                width: 100%;
            }}
            h1 {{
                color: #1F2937;
                margin-bottom: 20px;
                font-size: 24px;
            }}
            p {{
                color: #6B7280;
                line-height: 1.6;
                margin-bottom: 15px;
            }}
            .subtitle {{
                color: #9CA3AF;
                font-size: 14px;
            }}
            .logo {{
                width: 60px;
                height: 60px;
                background: #6B46C1;
                border-radius: 50%;
                margin: 0 auto 20px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 24px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">📚</div>
            <h1>{title}</h1>
            <p>{message}</p>
            <p class="subtitle">{subtitle}</p>
        </div>
    </body>
    </html>
    """


def _generate_error_page(error_message: str) -> str:
    """Generate an error page for failed email review actions."""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Mira Storyteller - Error</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #EF4444 0%, #F87171 100%);
                margin: 0;
                padding: 20px;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }}
            .container {{
                background: white;
                border-radius: 20px;
                padding: 40px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
                width: 100%;
            }}
            h1 {{
                color: #1F2937;
                margin-bottom: 20px;
                font-size: 24px;
            }}
            p {{
                color: #6B7280;
                line-height: 1.6;
            }}
            .logo {{
                width: 60px;
                height: 60px;
                background: #EF4444;
                border-radius: 50%;
                margin: 0 auto 20px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 24px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">⚠️</div>
            <h1>Oops!</h1>
            <p>{error_message}</p>
            <p>Please try using the Mira app instead, or contact support if the problem persists.</p>
        </div>
    </body>
    </html>
    """