
app:
[x] svgs for mascot
[x] svg for clouds and stars
[-] make mascot changing colors while waiting
[x] consise app menu on bottom
[x] play, speed, font size in reading screen
[x] screens: splash -> login -> users -> parent/kid 
[x] parent dashboard (can edit kids, can verify stories)
[x] lucide icons
[x] verify we use Manrope font everywhere
[x] blurry images 
[x] menu
[x] google auth
[x] check if all icons are lucide 
[x] screens to fill data about kids 
[x] screen to verify story
[x] notificstion about new story
[x] change all icons to fontawesome or 
[x] home page alligh title wit profile
[x] all icons same style
[x] animation on home page when scroll down
[x] stories not loaded after new story created in galleryr
[x] font spacing
[x] use Manrope?
[x] improve text style in story, make it paragraphs
[x] logout at parent screen
[x] setup Firebase Crashlitics
[x] input as audio or text (whisper for audio)
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
[x] upgrade flutter?
[x] multi language support
[x] bug in settings -> profile (two times profile)
[x] press in profile pic in home - redirect to swtich profiles
[x] pass - fixed as sign in screen
[x] icons shouls be toggle for create
[x] picture under 2n paragraph not sentence
[x] add background music
[x] select ganre in generation (bedtime story, adventure, etc)
[x] cashing data from db, loading is happening on every screen change and it is slow
[x] improve select profiel UI
[x] settign button in profile seelct is wrong style and point to wrong page, we should delete that screen
[x] save audio and images to db? s3?
[-] use only open ai for all models


Priority:
[] improve story promt to return json with title, proper formatting (paragraphs)
[] use kids data for story generation
[] test story generation with google, new openai, claude? - stories should be creative, adequate, fast
[] reserach wehre to deploy backend
[] how to monitor logs for backend

[] bug if we go from select kid to settings and then to create story
[x] localization tests
[] Set up CI/CD integration for localization checks
[] flutter analyze - 102 issues
[] test elevenlab turbo
[] improve supabase - story_input - input_type: text / text_final

[] auth with apple and google
[] kids profile info
[] analytics - posthog
[] storage bucket is public?
[] reduce social media images size to correct to reduce size of app
[] export data functionality
[] remove /test-processing
[] check for unused screens
[] home page sections
[] gallery view "see all" for more then 10? -> just All, like in bolt food

[] sentry
[] ci cd

[] debug messages cleanup
[] remove Mira Storyteller references
[] need help or support option in parent dashboard


[] remove print to console
[] empty fields in stories table
[] languages: english amercian and british, spanish, french
[] notifications
[] ui on small screen
[] fix all flutter analyse errors?
[] language detection (system) if not in our selection
[] improve prompts: lv voice slower and emotional
[] fallback to another vendor/model of we hit limit
[] improve db structure

[] send for parent review without audio, because parent can't impact audio quality only text
[] email waiting stories can be shown in app too
[] add notifications for children when their stories are approved
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
[] log requests and responces

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


when logged in:
- select user
    - kid:
        - 
    - parent:
        parent dashboard



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


----

priororities:
[] write diploma part on implementation
[] evaluation part plan and some parts
[] landing page for karto
[] fix story is ready screen
[] fix button on home screen
[]  when I press "back" on story preview I want to always be redirected to home page
[] is "open" button when story is ready correct text size?
[] dictate screen not localised - tap to start recording



[] localisation missing: story is ready, add image
[] review process and screens order
[] fix story text input - not saved, not updated

[] video animation for "cooking" image


[] onborading screens
[] subscription screens
[] help



[] public buckets - imporve secutriy?




☐ Write backend API tests for transcription endpoints
☐ Write integration tests for end-to-end transcription flow
☐ Write frontend widget tests for audio transcription UI
☐ Write error handling tests for transcription failures
☐ Add cleanup job for abandoned stories after 24 hours
☐ Add rate limiting for OTP attempts
☐ Create comprehensive route protection system (PLAN DOCUMENTED)
☐ Add proper loading states and error boundaries
☐ Create robust navigation flow with deep linking support
☐ Add security measures and session management
☐ Implement comprehensive testing for auth flows


==========================================================================================================================================

I don't like how this is implemented, let's brainstorm to improve it

several problems:
- model time to time returns titla+story with title being ** (marked), it this behaviour is random. What I want is to ask model to return json with "title": "value" and "story" or content value. Does it makes sense? And we will use this title value in our UI, bacause currently it looks like we just use first sentance? 
- I don't like this "with language", I think we should always pass language to promt as parameter, even if it is english. So promt is always same. What do you think? this additinal layer is NOT robust and clean to me
- I want to use not vendor specific promt, but just promt, I don't see WHY do I need different promts, I can just change vendor param and use same promt, don't you think? please research
- I don't see value in "You are Mira" in prompt, how it will help model with context to generate better stories?
- we have partially implemented (need to improve and finish) logic with collecting data about kid appearence and favourite genres and some additional notes (like promt from parent). So we need to think how to use all this data. let me explain this in more details: 


we have several input layers:

- info about kid:
  - name: mandatory
  - kids appearance: optional
  - kids favourite genres: optional
  - additional prompt from parents (for example favourite toys name, or "dwe are waiting for sibling" or anything else parent want to make focus in story)

currently kids appearance is implemented as profile editing screen where you just click colors etc
i think we should implement this a bit differently:
on create/edit screen user (parent) should enter kid name and age (I think age is important for story context) and then on same screen or next make it very clear that it is optional and explain why this data is useful - add kids appearence manually or upload a photo (we can use photo to extract key feutures of kid). So yes, I think it should be two steps, not in one screen. and next step/screen with additional data / parent input with explanation (parent should understand what is prompt for - additional info about kid or what parent whats to have focus in stories on)
in parent dashboard we should improve kid edit - I think we should have 4 buttons (icons) instead of settings icon with dropdown. Icons to easily - edit kids main data, appearence (change selected or upload new pic), additional prompt, genres, delete kid

it is a lot and it should be very simple for user to navugate and to understand 


next

it is not yet implemented but we need it - image generation
- it is long process, so we need to run it in parallel with tts
- hard part - what to pass for image gen promt?
  - we want all images to be in same style 
  - we always want to include kid in this image, I think it is most catchy thing for kid to use this app
  - to make our life simpler, I don't think we need to make this illustration to match exactly what we had on kids photo, yes? this is hard question - do we pass photo of kid to image gen or we pass extracted parameters of kids appearance?
  - same hard question with story generation input - do we pass uploaded image if it was image, not audio/text or we pass extracted features?
  - and should we pass generated story to image gen promt ot we should pass all initial data too?


this is testing prompt I used directly in chatgpt, we can use it as idea, but it is not ideal.
"""
A dreamy, magical square illustration (768x768 px) for a children's story app, featuring a soft, whimsical scene on a cloud or starry background with white edges blending into a white background.

Base the illustration on the following full children's story:
[Insert full story text here — approx. 150–250 words]

In the scene, include:

- A beloved toy based on the uploaded image: [toy description or image input]
- A child named [Имя ребёнка], who is around [возраст] years old
- The child has [цвет волос], [длина волос], and [дополнительные особенности — челка, хвостики, очки...]
- She/he is wearing a [одежда, например: striped tank top and purple shorts]
- She/he is holding or enjoying [любимая вещь, например: a cookie]
- The characters are sitting together peacefully on a cloud, under a crescent moon and gentle stars
- Include warm lavender, peach, cream, and soft yellow colors

Style: soft brushstroke, gentle texture like a watercolor or pastel children's book  
Format: square, with soft white border blending into background for seamless app layout  
Lighting: gentle, glowing, dreamy

Do not include any text. Composition should leave a little headroom to allow UI overlay.
"""

I like defitiniton of colors and styles, but we need smarter way to pass optional data


one more challenge I see: we have kid data, genres etc. But we also have request to make story, photo or audio, so it is main theme of story
if we look in books and storytelling in general - we don't want to descrive same kid over and over again in every story, right? it will become annoying
we want to occasionally mention som eof it
we want image to be precise about kid but also have variaty of what kid does on image etc, sometimes we want to show close up, sometimes standing kid etc, or sometimes no kid at all? 
so precense of kid in visual is more active when in story text
how do we impleemnt this? if for example we pass instruction to llm and json where we define kids appearence and temperature or usage ratio as small number - will it work? 
with genres too - kid may have selected or no selected, so we have list of genres and we need llm to randomly select one of it? later we can implement genre selection option when we create story


so we need clever way to define our prompt and sctructure config file, I dont want promt per model (like mistral - one promt, google another, no, it is just common promt and param what model to call with that promt)

I hope it make sence
we need to create file with improved narration of my request and then we need a plan how to address that


  also, I am thinking, maybe this select color etc for kids appearence is not best option too? maybe it is better for parent to secribe kid in open manner, like just text box? not sure here
  we for exmaple don't have hairstyle option, while it is usually significant, like if girl with two bows, we will have totally different visual from our survey
  we need to think what is best and easiet way for both sides (parent and system) to get kids appearence data, I still think maybe photo is easier
  but we need to add info for parent like "if you want stories to be personalised you can add your kid photo or enter detailes abou kid appearence manually" and parent will define what he thinks is
  important?

> I think it will defintely will be easier to implement on our side and it will be cleaner UI?


==========================================================================================================================================














info for parent:
- we don't store uploaded images
- kids data stored anonimously and in a secure way
- you pay only for generating new stories
- once story is created - it will be always available for you for free
- you can export stories at any time
- we will introduce option to order printed version of your stories very soon
- if you have any questions or problems - feel free to reach us out, we are very open to hear you and improve our product