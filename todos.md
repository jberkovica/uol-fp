
app:
[] svgs for mascot
[] svg for clouds and stars
[] make mascot changing colors while waiting
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

backend:
[] image generation prompt
[] improve story generation prompt
[] use only open ai for all models
[] log requests and responces
[] save audio and images to db? s3?


[] multi language support
[] input as audio or text (whisper for audio)


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
[] bug on story reload
[] select ganre in generation (bedtime story, adventure, etc)
[] cashing data from db, loading is happening on every screen change and it is slow
[] improve select profiel UI
[] settign button in profile seelct is wrong style and point to wrong page, we should delete that screen


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

store everything in db 
