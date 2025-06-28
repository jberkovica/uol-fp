# CLAUDE Context & Planning

## Project Overview
**Mira Storyteller** - AI-powered children's storytelling app that generates personalized stories from children's drawings using multimodal AI.

### Current Architecture
- **Frontend**: Flutter (iOS/Android/Web)
- **Backend**: FastAPI + Python
- **Database**: SQLite + Supabase integration
- **AI Services**: Multiple providers (OpenAI, Anthropic, Google, ElevenLabs)

## Current Status (Completed)
- Basic story generation from image uploads
- TTS integration with multiple voice options
- Database migration from in-memory to SQLite/Supabase
- Comprehensive testing infrastructure
- API security improvements (API keys secured)
- Input validation for uploads

## High Priority Next Steps

### 1. UI/UX Improvements
**Goal**: Match the beautiful design mockup with plain color backgrounds and cute purple character illustrations
- Current UI is basic, needs solid color backgrounds (purple/yellow/orange)
- Add cute character illustrations (purple blob character from mockup)
- Implement proper loading states with character animations
- Profile selection screen with avatar system

### 2. AI Provider Consolidation
**Goal**: Standardize on single provider for cost management and simplicity
- Research cost comparison between providers
- Evaluate quality vs cost tradeoffs
- Implement unified AI client interface
- Migrate all services to chosen provider

### 3. Story Image Generation
**Goal**: Generate cover images for stories automatically
- Add DALL-E 3 or Midjourney integration
- Generate images matching story content and child's drawing style
- Cache generated images in database

### 4. Authentication System
**Goal**: Implement proper user management with Supabase Auth
- Parent/child profile system
- Story ownership and sharing
- User preferences and settings
- Privacy controls for child safety

### 5. Enhanced Database Schema
**Goal**: Proper relational database with user-story relationships
- User profiles and relationships
- Story ownership and permissions
- Usage tracking and analytics
- Story ratings and favorites

### 6. AI Cost Tracking
**Goal**: Monitor and control AI API expenses
- Log each API request with: user_id, request_type, model, token_count, cost
- Usage analytics and reporting
- Rate limiting per user
- Cost alerts and budgeting

### 7. User Behavior Analytics
**Goal**: Track user behavior for product improvement
- Research analytics tools (Firebase Analytics, PostHog, Mixpanel, Amplitude)
- Track: story generation success rate, time spent, image upload patterns, voice preference
- Privacy-compliant implementation for children's app (COPPA)
- User retention and engagement metrics

### 8. Multi-Language Support
**Goal**: Support international users with localized content
- Implement i18n for Flutter frontend (English, Russian, Latvian, Spanish)
- AI story generation in multiple languages
- TTS voice support for each language
- Cultural adaptation of story content

## Development Priorities

### Phase 1: Foundation (Current)
- [x] Core functionality working
- [x] Database implementation
- [x] Security basics
- [ ] UI improvements to match design
- [ ] Single AI provider migration

### Phase 2: User Experience
- [ ] Authentication system
- [ ] Story image generation
- [ ] Enhanced database schema
- [ ] Cost tracking implementation

### Phase 3: Production Ready
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Monitoring and logging

## Technical Notes

### AI Provider Research Needed
- **Cost analysis**: OpenAI vs Anthropic vs Google for each service type
- **Quality assessment**: Maintain story quality while reducing costs
- **Rate limits**: Understand provider limitations
- **Integration complexity**: Unified client implementation

### Docker Consideration
**Removed from priorities** - Adds complexity without clear benefits for single-developer deployment

### Best Practices for AI Cost Tracking
- Request logging with structured data
- Real-time cost calculation
- Usage analytics dashboard
- Per-user rate limiting
- Budget alerts and controls

## File Structure Context
- `app/backend/` - FastAPI application
- `app/mira_storyteller/` - Flutter frontend
- `models_analysis/` - AI model research and evaluation
- `DATABASE_DESIGN.md` - Database schema documentation
- `PRIVACY_SECURITY_POLICY.md` - Security requirements

## Testing
- Use `pytest` for backend testing
- Run tests with: `python run_tests.py`
- Comprehensive test suite includes unit, integration, and functional tests

## Environment Setup
- Backend runs on FastAPI with uvicorn
- Frontend is Flutter with web/mobile support
- Database: SQLite locally, Supabase for production
- Multiple AI service integrations via APIs

## Current Todo List

### HIGH Priority
- [ ] Improve UI to match design mockup with plain color backgrounds and cute character illustrations
- [ ] Research and switch all AI agents to one provider for cost management
- [ ] Add agent for story image generation
- [ ] Implement authentication using Supabase
- [ ] Implement proper database with user-story relationships
- [ ] Research and implement AI API cost tracking with user ID and request type
- [ ] Research and implement user behavior analytics (tool selection, user tracking)
- [ ] Implement multi-language support (English, Russian, Latvian, Spanish)
- [ ] Implement comprehensive testing suite

### MEDIUM Priority
- [ ] Plan future security audit
- [ ] Implement proper error handling with specific exception types
- [ ] Fix CORS configuration - restrict origins for production
- [ ] Convert to async operations with aiohttp
- [ ] Implement caching strategy with Redis
- [ ] Replace polling with WebSocket real-time updates
- [ ] Add dependency injection container
- [ ] Implement rate limiting with slowapi
- [ ] Add health check and metrics endpoints
- [ ] Add structured logging with log levels
- [ ] Add JWT authentication for parent/child access
- [ ] Add request size limits and content filtering

### LOW Priority
- [ ] Implement environment-based configuration
- [ ] Standardize API response formats and add versioning
- [ ] Add progress indicators and content moderation