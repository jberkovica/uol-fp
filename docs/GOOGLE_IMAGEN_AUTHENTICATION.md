# Google Imagen 3 Authentication Setup Guide

This guide covers the authentication setup for Google Imagen 3 integration using Google Cloud's recommended best practices for 2025.

## Overview

We use **Application Default Credentials (ADC)** for authentication, which is Google's recommended approach as of 2025. This method avoids the security risks associated with service account keys and provides seamless authentication across development and production environments.

## Local Development Setup

### Prerequisites

1. **Google Cloud Project**
   - Create or select a project in Google Cloud Console
   - Enable billing for the project (Imagen 3 costs ~$0.03 per image)
   - Note your `PROJECT_ID`

2. **Enable Required APIs**
   - Go to APIs & Services → Library in Google Cloud Console
   - Search for and enable "Vertex AI API"

### Step 1: Install Google Cloud CLI

**macOS:**
```bash
brew install google-cloud-sdk
```

**Other platforms:** Follow the [official installation guide](https://cloud.google.com/sdk/docs/install)

### Step 2: Authenticate with Google Cloud

```bash
# Initialize gcloud (first time only)
gcloud init

# Set up Application Default Credentials
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### Step 3: Install Python Dependencies

```bash
pip install google-cloud-aiplatform
```

### Step 4: Environment Variables

Add to your `.env` file:
```env
GOOGLE_PROJECT_ID=your-project-id
```

**Note:** No credential files or paths needed with ADC!

### Step 5: Verify Authentication

```bash
# Test authentication
gcloud auth list
gcloud config get-value project

# Test Vertex AI access
python -c "
import vertexai
from google.auth import default
credentials, project = default()
print(f'Authenticated project: {project}')
vertexai.init(project=project, location='us-central1')
print('Vertex AI initialization successful!')
"
```

## How It Works

### Application Default Credentials Flow

ADC automatically finds credentials in this order:
1. `GOOGLE_APPLICATION_CREDENTIALS` environment variable (if set)
2. User credentials from `gcloud auth application-default login`
3. Service account attached to the resource (in production)
4. Google Cloud SDK default credentials

### Code Example

```python
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel
from google.auth import default

# ADC automatically handles authentication
credentials, project = default()
vertexai.init(project=project, location="us-central1")

# Use Imagen 3
model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
images = model.generate_images(
    prompt="A magical forest with orange trees",
    number_of_images=1,
)
```

## Production Deployment

### Cloud Run (Recommended)

For production deployment on Cloud Run, use attached service accounts:

#### Step 1: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create imagen-service-account \
    --display-name="Imagen Service Account"

# Grant Vertex AI User role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:imagen-service-account@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

#### Step 2: Deploy to Cloud Run

```bash
gcloud run deploy mira-backend \
    --image=gcr.io/YOUR_PROJECT_ID/mira-backend \
    --service-account=imagen-service-account@YOUR_PROJECT_ID.iam.gserviceaccount.com \
    --region=us-central1
```

### Docker Configuration

**For local testing:**
```dockerfile
# Do NOT set GOOGLE_APPLICATION_CREDENTIALS in production
# ADC will automatically use attached service account
```

**For development with volume mount:**
```bash
# Only for local development/testing
ADC=~/.config/gcloud/application_default_credentials.json
docker run \
  -e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/adc.json \
  -v ${ADC}:/tmp/keys/adc.json:ro \
  your-image
```

### Required IAM Roles

Minimum roles needed for the service account:
- `roles/aiplatform.user` - Access to Vertex AI services
- `roles/storage.objectAdmin` - If using Cloud Storage for images (optional)

## Security Best Practices (2025)

### ✅ Do This
- Use ADC for all authentication
- Attach service accounts to Cloud Run services
- Grant minimal required permissions (principle of least privilege)
- Use workload identity federation for external services

### ❌ Don't Do This
- Don't use service account keys (blocked by default in many organizations)
- Don't set `GOOGLE_APPLICATION_CREDENTIALS` in production
- Don't grant broad roles like `Editor` or `Owner`
- Don't commit any credential files to version control

## Troubleshooting

### Common Issues

**Authentication Error: "No valid credentials found"**
```bash
# Check if authenticated
gcloud auth list

# Re-authenticate if needed
gcloud auth application-default login
```

**Project Not Set**
```bash
# Check current project
gcloud config get-value project

# Set project
gcloud config set project YOUR_PROJECT_ID
```

**Vertex AI API Not Enabled**
```bash
# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com
```

**Permission Denied in Production**
- Verify the service account has `roles/aiplatform.user`
- Check that the service account is attached to your Cloud Run service
- Ensure billing is enabled on the project

### Debug Commands

```bash
# Check authentication status
gcloud auth list
gcloud config list

# Test Vertex AI access
gcloud ai models list --region=us-central1

# Check service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:*imagen*"
```

## Environment-Specific Notes

### Development
- Uses user credentials from `gcloud auth application-default login`
- Credentials stored in `~/.config/gcloud/application_default_credentials.json`

### Cloud Run Production
- Uses attached service account automatically
- No environment variables needed for authentication
- ADC handles everything automatically

### Local Docker Testing
- Can volume mount ADC file for testing
- Use `GOOGLE_APPLICATION_CREDENTIALS` only for local testing
- Remove this environment variable for production

## Migration from Service Account Keys

If migrating from service account keys:

1. Remove `GOOGLE_SERVICE_ACCOUNT_PATH` from environment variables
2. Remove any credential file handling in code
3. Replace manual token management with `google.auth.default()`
4. Update deployment scripts to use attached service accounts
5. Delete unused service account key files

## Cost Considerations

- Imagen 3: ~$0.03 per generated image
- No additional authentication costs with ADC
- Monitor usage in Google Cloud Console → Billing

## Support and Updates

This guide follows Google Cloud's 2025 best practices for authentication. For the latest updates, refer to:
- [Google Cloud Authentication Documentation](https://cloud.google.com/docs/authentication)
- [Vertex AI Authentication Guide](https://cloud.google.com/vertex-ai/docs/authentication)
- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)