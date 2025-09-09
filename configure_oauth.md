# Configure OAuth Redirect URL for E-Pon

## Issue
The Google OAuth sign-in is failing with "Access blocked: This app's request is invalid" due to redirect URI mismatch.

## Solution
Add the redirect URI `io.supabase.epon://login-callback` to your Supabase project's URL configuration.

## Method 1: Dashboard Configuration (Recommended)
1. Go to https://supabase.com/dashboard
2. Select your E-Pon project
3. Navigate to Authentication → URL Configuration
4. Add `io.supabase.epon://login-callback` to "Additional Redirect URLs"
5. Click Save

## Method 2: Management API Configuration
```bash
# Get your access token from https://supabase.com/dashboard/account/tokens
export SUPABASE_ACCESS_TOKEN="your-access-token"
export PROJECT_REF="wasrcfohojjdaqzrkojh"

# Add redirect URL
curl -X PATCH "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "additional_redirect_urls": ["io.supabase.epon://login-callback"]
  }'
```

## Verification
After adding the redirect URL:
1. Test the Google OAuth sign-in flow
2. The "Access blocked" error should be resolved
3. Users should be redirected back to the app after authentication

## Current Configuration
- Redirect URI: `io.supabase.epon://login-callback`
- Android scheme: `io.supabase.epon`
- Android host: `login-callback`
- Supabase URL: `https://wasrcfohojjdaqzrkojh.supabase.co`
