# Environment Variables Management for Deployment

## Current Development Setup

**Status**: Development-friendly but not production-ready
- **Backend**: Loads from `../.env` (root directory)
- **Frontend**: Loads from `app/.env` (copied file)
- **Issue**: Duplicate .env files break single source of truth

## Production Deployment Options

### Option 1: Build-Time Environment Injection (Recommended)

**Best for**: Production deployments with CI/CD

**Backend**:
```python
# Use environment variables directly
import os
DATABASE_URL = os.getenv('DATABASE_URL')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
```

**Frontend**:
```dart
// Use Flutter's built-in environment variables
const String apiUrl = String.fromEnvironment('API_URL');
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
```

**Build commands**:
```bash
# Backend
export DATABASE_URL="..." && python main.py

# Frontend  
flutter build web --dart-define=API_URL=https://api.example.com
```

**Pros**: Secure, No .env files in production, Platform native
**Cons**: More complex build process

### Option 2: Platform-Specific Environment Loading

**Best for**: Multi-platform apps with different configs

**Implementation**:
```dart
Future<void> loadEnvironment() async {
  if (kIsWeb) {
    // Web: Use build-time variables
    await dotenv.load(fileName: ".env.web");
  } else if (Platform.isIOS || Platform.isAndroid) {
    // Mobile: Use bundled .env
    await dotenv.load(fileName: ".env.mobile");
  }
}
```

**File structure**:
```
├── .env.web          # Web-specific config
├── .env.mobile       # Mobile-specific config
├── backend/.env      # Backend config
```

**Pros**: Platform-specific configs, Flexible
**Cons**: Multiple config files to maintain

### Option 3: Build Script Automation

**Best for**: Maintaining single source of truth during development

**Build script** (`scripts/prepare-env.sh`):
```bash
#!/bin/bash
# Copy root .env to required locations
cp .env backend/.env
cp .env app/.env

# Or generate platform-specific versions
cat .env | grep -E "SUPABASE|FIREBASE" > app/.env
cat .env | grep -E "DATABASE|API" > backend/.env
```

**Pros**: Single source file, Automated sync
**Cons**: Build step dependency, Still uses .env files

### Option 4: Configuration Service

**Best for**: Enterprise/scalable deployments

**Implementation**:
```dart
class ConfigService {
  static Future<Map<String, String>> loadConfig() async {
    if (kIsWeb) {
      // Fetch from API or build-time injection
      return await http.get('/api/config');
    } else {
      // Load from secure storage or .env
      return await dotenv.load();
    }
  }
}
```

**Pros**: Dynamic config, Secure, Centralized
**Cons**: Complex implementation, Network dependency

## Security Considerations

### Development (.env files)
- **Do**: Add `.env` to `.gitignore`
- **Do**: Use `.env.example` for documentation
- **Don't**: Commit real secrets to Git
- **Don't**: Use .env files in production

### Production (Environment Variables)
- **Do**: Use platform environment variables
- **Do**: Rotate secrets regularly
- **Do**: Use secret management services (AWS Secrets Manager, etc.)
- **Don't**: Log environment variables
- **Don't**: Expose secrets in client-side code

## Migration Path for Production

### Phase 1: Immediate (Current State)
```
Development working with duplicate .env files
Clean up when ready for production
```

### Phase 2: Pre-Production
```bash
# 1. Remove duplicate .env files
rm app/.env
rm backend/.env

# 2. Update code to use environment variables
# Backend: os.getenv() instead of dotenv
# Frontend: String.fromEnvironment() instead of dotenv

# 3. Update build scripts
flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL
```

### Phase 3: Production Deployment
```bash
# Set environment variables in deployment platform
export SUPABASE_URL="https://..."
export DATABASE_URL="postgresql://..."

# Deploy without .env files
docker build --build-arg API_URL=$API_URL .
```

## Recommended Approach for Your App

**For immediate deployment**: Use **Option 1** (Build-time injection)
- Secure and production-ready
- No .env files in production bundles
- Platform-native approach

**For complex deployments**: Use **Option 4** (Configuration service)
- Dynamic configuration
- Better for microservices
- Enterprise-grade security

## Example Implementation (Option 1)

### Backend Migration
```python
# Before (development)
from dotenv import load_dotenv
load_dotenv("../.env")

# After (production)
import os
SUPABASE_URL = os.getenv('SUPABASE_URL', 'default_value')
```

### Frontend Migration
```dart
// Before (development)
await dotenv.load(fileName: ".env");
String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

// After (production)
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL', 
  defaultValue: 'https://default.supabase.co'
);
```

### Deployment Commands
```bash
# Backend
export SUPABASE_URL="https://your-project.supabase.co"
python main.py

# Frontend
flutter build web \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key"
```

## Notes

- **Current setup works fine for development and testing**
- **Migration should be done before production deployment**
- **Choose option based on deployment complexity and security requirements**
- **Document chosen approach for team consistency**