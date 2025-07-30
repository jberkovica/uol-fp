
app:
[x] svgs for mascot
[x] svg for clouds and stars
[-] make mascot changing colors while waiting
[x] consise app menu on bottom
[] play, speed, font size in reading screen
[x] screens: splash -> login -> users -> parent/kid 
[x] parent dashboard (can edit kids, can verify stories)
[x] lucide icons
[] verify we use Manrope font everywhere
[x] blurry images 
[x] menu
[] google auth
[] check if all icons are lucide 
[] check for unused screens
[] fix all flutter analyse errors?
[] screens to fill data about kids 
[] screen to verify story
[] notificstion about new story
[] change all icons to fontawesome or 
[] home page alligh title wit profile
[] remove print to console
[] all icons same style
[x] animation on home page when scroll down
[] gallery view "see all" for more then 10?
[] home page sections
[x] stories not loaded after new story created in galleryr
[] font spacing
[x] use Manrope?
[] remove /test-processing
[] improve text style in story, make it paragraphs
[x] logout at parent screen
[] remove export button but implement it later (Export data - download all stories and data)
 [] reduce social median images size to correct to reduce size of app
 [] setup Firebase Crashlitics

Priority:
[x] Manrope font
[x] darker violet color?
[x] create button in menu
[x] home page design
[x] 3 language support
[x] all prompts separated and redesigned
[x] switch from elevenlab to open ai for tts
[-] switch from mistral to open ai
[x] fix screens scrollin animation
[x] fix scrolling issue on home page
[x] logout button
[x] profile options - bold
[x] parent dashboard less spacing
[x] parent dashboard remove 3 dots and add logout
[x] generate story in selected language
[x] store language in supabase
[x] parent approve
[x] alchemy something
[] upgrade flutter?



[] auth with apple and google
[x] input as audio or text (whisper for audio)
[] kids profile info
[] analytics - posthog
[] storage bucket is public?


[] empty fields in stories table
[] languages: english amercian and british, spanish, french
[] notifications
[] language detection (system) if not in our selection
[] improve prompts: lv voice slower and emotional
[] fallback to another vendor/model of we hit limit
[] improve db structure

[] send for parent review without audio, because parent can't impact audio quality only text
[] email waiting stories can be shown in app too
[] add notifications for children when their stories are approved
[] save logs
[] color hunt
[] ui cleanup 



{"timestamp": "2025-07-27T07:19:24.736337", "level": "ERROR", "logger": "src.api.app", "message": "Story processing failed for 644b1d0a-191b-40eb-9fa0-9de4626da115: Client error '429 Too Many Requests' for url 'https://api.mistral.ai/v1/chat/completions'\nFor more information check: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429", "module": "app", "function": "process_story_generation_background", "line": 300}

  1. Add retry logic with exponential backoff for the Mistral API calls
  2. Switch to a different AI provider (as mentioned in your CLAUDE.md priorities)
  3. Implement request queuing to space out API calls
  4. Check your Mistral API dashboard for rate limit details

  The logs show that mira@test.com successfully generates stories while
  jekaterina.berkovich@gmail.com consistently hits rate limits, but there's no difference in how
  their requests are processed. This is likely a timing or rate limit issue at the API provider
  level.

backend:
[] image generation prompt
[] improve story generation prompt
[-] use only open ai for all models
[] log requests and responces
[x] save audio and images to db? s3?
[] age 3-10?
[] for prod I want testing db and prod db and also backup, research best practise
[] image generation and audio generation in parallel
[] clean ai to use supabase
[] use SDKs instead of plain HTTP?


  Minor Areas for Future Enhancement:
  - Add async connection pooling for high load
  - Implement circuit breaker pattern for AI service failures
  - Add metrics/monitoring endpoints

Next Steps for Production:
  - Add API rate limiting
  - Implement health check endpoints
  - Add monitoring/metrics
  - Security audit


[x] multi language support



when logged in:
- select user
    - kid:
        - 
    - parent:
        parent dashboard


[x] bug in settings -> profile (two times profile)
[x] press in profile pic in home - redirect to swtich profiles
[x] pass - fixed as sign in screen
[x] icons shouls be toggle for create
[] picture under 2n paragraph not sentence
[x] add background music
[] ui on small screen
[] select ganre in generation (bedtime story, adventure, etc)
[] cashing data from db, loading is happening on every screen change and it is slow
[x] improve select profiel UI
[x] settign button in profile seelct is wrong style and point to wrong page, we should delete that screen


<!-- models update -->

system prompt:
- kids data
- parent data

cost tracking per user, per step
track time per step, maybe store in db for analysis? or what is best practice?
all vendors should be configurable in config file to easy switch
should be option to disbale some features or block user in case if system is abused or costs are extreme

user input:
- image -> image recognition model
- audio -> open ai whisper
story generation:
- text -> LLM model, open ai?
- TTS -> open ai
- words timestamps -> whisper 
- image generation -> open ai

