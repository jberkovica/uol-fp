============================================================
MIRA API Keys Test Script
============================================================
Testing all configured API keys...

Environment: Found .env file at: /Users/jekaterinaberkovich/Documents/UoL/Final Project/Code/uol-fp-mira/models_analysis/.env

Testing OpenAI GPT...
[OK] OpenAI GPT           | SUCCESS  | Connected successfully. Model: gpt-4o-mini
   Cost: Cost: ~$0.001 per test

Testing Google Gemini...
[OK] Google Gemini        | SUCCESS  | Connected successfully. Model: gemini-2.0-flash
   Cost: Cost: ~$0.0001 per test

Testing List Gemini Models...

   Fetching available models from Gemini API...
   Found 51 available models:
      - models/embedding-gecko-001
        Display: Embedding Gecko
      - models/gemini-1.0-pro-vision-latest
        Display: Gemini 1.0 Pro Vision
      - models/gemini-pro-vision
        Display: Gemini 1.0 Pro Vision
      - models/gemini-1.5-pro-latest
        Display: Gemini 1.5 Pro Latest
      - models/gemini-1.5-pro-002
        Display: Gemini 1.5 Pro 002
      - models/gemini-1.5-pro
        Display: Gemini 1.5 Pro
      - models/gemini-1.5-flash-latest
        Display: Gemini 1.5 Flash Latest
      - models/gemini-1.5-flash
        Display: Gemini 1.5 Flash
      - models/gemini-1.5-flash-002
        Display: Gemini 1.5 Flash 002
      - models/gemini-1.5-flash-8b
        Display: Gemini 1.5 Flash-8B
      ... and 41 more models
[OK] List Gemini Models   | SUCCESS  | Listed 51 available models

Testing Test Gemini Models...

   Testing 4 Gemini models...
      SUCCESS gemini-2.0-flash - Words: 186, Title: Yes, Length: Yes
      SUCCESS gemini-2.0-flash-lite - Words: 167, Title: Yes, Length: Yes
      SUCCESS gemini-1.5-pro - Words: 204, Title: Yes, Length: Yes
      SUCCESS gemini-1.5-flash - Words: 175, Title: Yes, Length: Yes
[OK] Test Gemini Models   | SUCCESS  | Working models (4/4): gemini-2.0-flash, gemini-2.0-flash-lite, gemini-1.5-pro, gemini-1.5-flash

Testing OpenAI TTS...
[OK] OpenAI TTS           | SUCCESS  | Connected successfully. Models: tts-1 ($15/M chars). Child-friendly voices: fable, nova, shimmer
   Cost: Cost: $15-30/M chars

Testing Google Cloud TTS...
[OK] Google Cloud TTS     | SUCCESS  | Connected with Google AI API key. 1442 total voices, 24 Neural2 voices. Child-friendly: en-GB-Neural2-F, en-US-Neural2-F, en-US-Neural2-H
   Cost: Cost: $16/M chars

Testing ElevenLabs TTS...
[OK] ElevenLabs TTS       | SUCCESS  | Connected successfully. 19 voices available. Models: eleven_multilingual_v2, eleven_flash_v2_5, eleven_turbo_v2_5
   Cost: Cost: $22-330/month subscription

Testing DeepSeek...
[OK] DeepSeek             | SUCCESS  | Connected successfully. Working models: deepseek-chat (Chat model)
   Cost: Cost: $0.27/M input, $1.10/M output

Testing Replicate...
[OK] Replicate            | SUCCESS  | Connected successfully. Access to 25 models
   Cost: Cost: Free for API check

Testing Anthropic Claude...
[OK] Anthropic Claude     | SUCCESS  | Connected successfully. Model: claude-3-5-haiku
   Cost: Cost: ~$0.001 per test

Testing Diagnose Gemini Issues...

   DETAILED GEMINI API DIAGNOSTIC
   ==================================================

   Testing: gemini-2.0-flash
   Purpose: Should work (verified)
   Model instance created successfully
   Response received
   Response type: <class 'google.generativeai.types.generation_types.GenerateContentResponse'>
   Response attributes: ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__iter__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_chunks', '_done', '_error', '_iterator', '_result', 'candidates', 'from_iterator', 'from_response', 'parts', 'prompt_feedback', 'resolve', 'text']
   Has candidates: 1
   Candidate type: <class 'google.ai.generativelanguage_v1beta.types.generative_service.Candidate'>
   Candidate attributes: ['FinishReason', '__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'citation_metadata', 'content', 'finish_reason', 'grounding_attributions', 'index', 'safety_ratings', 'token_count']
   Has content: True
   Content type: <class 'google.ai.generativelanguage_v1beta.types.content.Content'>
   Content attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'parts', 'role']
   Has parts: 1
   Part type: <class 'google.ai.generativelanguage_v1beta.types.content.Part'>
   Part attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'function_call', 'function_response', 'inline_data', 'text']
   Part has text: 'Okay.
...'
   Finish reason: 1
   response.text works: 'Okay.
...'
   Parts access works: 'Okay.
...'
   gemini-2.0-flash - SUCCESS

   Testing: gemini-2.5-pro-preview-06-05
   Purpose: Failing - let's see why
   Model instance created successfully
   Response received
   Response type: <class 'google.generativeai.types.generation_types.GenerateContentResponse'>
   Response attributes: ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__iter__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_chunks', '_done', '_error', '_iterator', '_result', 'candidates', 'from_iterator', 'from_response', 'parts', 'prompt_feedback', 'resolve', 'text']
   Has candidates: 1
   Candidate type: <class 'google.ai.generativelanguage_v1beta.types.generative_service.Candidate'>
   Candidate attributes: ['FinishReason', '__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'citation_metadata', 'content', 'finish_reason', 'grounding_attributions', 'index', 'safety_ratings', 'token_count']
   Has content: True
   Content type: <class 'google.ai.generativelanguage_v1beta.types.content.Content'>
   Content attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'parts', 'role']
   Has parts: 1
   Part type: <class 'google.ai.generativelanguage_v1beta.types.content.Part'>
   Part attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'function_call', 'function_response', 'inline_data', 'text']
   Part has text: 'The old library was filled with the gentle scent o...'
   Finish reason: 1
   response.text works: 'The old library was filled with the gentle scent o...'
   Parts access works: 'The old library was filled with the gentle scent o...'
   gemini-2.5-pro-preview-06-05 - SUCCESS

   Testing: gemini-2.5-flash-preview-05-20
   Purpose: Failing - let's see why
   Model instance created successfully
   Response received
   Response type: <class 'google.generativeai.types.generation_types.GenerateContentResponse'>
   Response attributes: ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__iter__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_chunks', '_done', '_error', '_iterator', '_result', 'candidates', 'from_iterator', 'from_response', 'parts', 'prompt_feedback', 'resolve', 'text']
   Has candidates: 1
   Candidate type: <class 'google.ai.generativelanguage_v1beta.types.generative_service.Candidate'>
   Candidate attributes: ['FinishReason', '__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'citation_metadata', 'content', 'finish_reason', 'grounding_attributions', 'index', 'safety_ratings', 'token_count']
   Has content: True
   Content type: <class 'google.ai.generativelanguage_v1beta.types.content.Content'>
   Content attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'parts', 'role']
   Has parts: 1
   Part type: <class 'google.ai.generativelanguage_v1beta.types.content.Part'>
   Part attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'function_call', 'function_response', 'inline_data', 'text']
   Part has text: 'Hello, here is one sentence....'
   Finish reason: 1
   response.text works: 'Hello, here is one sentence....'
   Parts access works: 'Hello, here is one sentence....'
   gemini-2.5-flash-preview-05-20 - SUCCESS

   Testing: models/gemini-2.5-pro-preview-06-05
   Purpose: Try with models/ prefix
   Model instance created successfully
   Response received
   Response type: <class 'google.generativeai.types.generation_types.GenerateContentResponse'>
   Response attributes: ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__iter__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_chunks', '_done', '_error', '_iterator', '_result', 'candidates', 'from_iterator', 'from_response', 'parts', 'prompt_feedback', 'resolve', 'text']
   Has candidates: 1
   Candidate type: <class 'google.ai.generativelanguage_v1beta.types.generative_service.Candidate'>
   Candidate attributes: ['FinishReason', '__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'citation_metadata', 'content', 'finish_reason', 'grounding_attributions', 'index', 'safety_ratings', 'token_count']
   Has content: True
   Content type: <class 'google.ai.generativelanguage_v1beta.types.content.Content'>
   Content attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'parts', 'role']
   Has parts: 1
   Part type: <class 'google.ai.generativelanguage_v1beta.types.content.Part'>
   Part attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'function_call', 'function_response', 'inline_data', 'text']
   Part has text: 'The old bookstore smelled of dust, leather, and br...'
   Finish reason: 1
   response.text works: 'The old bookstore smelled of dust, leather, and br...'
   Parts access works: 'The old bookstore smelled of dust, leather, and br...'
   models/gemini-2.5-pro-preview-06-05 - SUCCESS

   Testing: models/gemini-2.5-flash-preview-05-20
   Purpose: Try with models/ prefix
   Model instance created successfully
   Response received
   Response type: <class 'google.generativeai.types.generation_types.GenerateContentResponse'>
   Response attributes: ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__iter__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_chunks', '_done', '_error', '_iterator', '_result', 'candidates', 'from_iterator', 'from_response', 'parts', 'prompt_feedback', 'resolve', 'text']
   Has candidates: 1
   Candidate type: <class 'google.ai.generativelanguage_v1beta.types.generative_service.Candidate'>
   Candidate attributes: ['FinishReason', '__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'citation_metadata', 'content', 'finish_reason', 'grounding_attributions', 'index', 'safety_ratings', 'token_count']
   Has content: True
   Content type: <class 'google.ai.generativelanguage_v1beta.types.content.Content'>
   Content attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'parts', 'role']
   Has parts: 1
   Part type: <class 'google.ai.generativelanguage_v1beta.types.content.Part'>
   Part attributes: ['__bool__', '__class__', '__contains__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__getstate__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'function_call', 'function_response', 'inline_data', 'text']
   Part has text: 'Hello....'
   Finish reason: 1
   response.text works: 'Hello....'
   Parts access works: 'Hello....'
   models/gemini-2.5-flash-preview-05-20 - SUCCESS

   AVAILABLE MODELS CONTAINING '2.5':
   - models/gemini-2.5-pro-exp-03-25
     Display: Gemini 2.5 Pro Experimental 03-25
   - models/gemini-2.5-pro-preview-03-25
     Display: Gemini 2.5 Pro Preview 03-25
   - models/gemini-2.5-flash-preview-04-17
     Display: Gemini 2.5 Flash Preview 04-17
   - models/gemini-2.5-flash-preview-05-20
     Display: Gemini 2.5 Flash Preview 05-20
   - models/gemini-2.5-flash-preview-04-17-thinking
     Display: Gemini 2.5 Flash Preview 04-17 for cursor testing
   - models/gemini-2.5-pro-preview-05-06
     Display: Gemini 2.5 Pro Preview 05-06
   - models/gemini-2.5-pro-preview-06-05
     Display: Gemini 2.5 Pro Preview
   - models/gemini-2.0-flash-thinking-exp-01-21
     Display: Gemini 2.5 Flash Preview 04-17
   - models/gemini-2.0-flash-thinking-exp
     Display: Gemini 2.5 Flash Preview 04-17
   - models/gemini-2.0-flash-thinking-exp-1219
     Display: Gemini 2.5 Flash Preview 04-17
   - models/gemini-2.5-flash-preview-tts
     Display: Gemini 2.5 Flash Preview TTS
   - models/gemini-2.5-pro-preview-tts
     Display: Gemini 2.5 Pro Preview TTS
   - models/gemini-2.5-flash-preview-native-audio-dialog
     Display: Gemini 2.5 Flash Preview Native Audio Dialog
   - models/gemini-2.5-flash-preview-native-audio-dialog-rai-v3
     Display: Gemini 2.5 Flash Preview Native Audio Dialog RAI v3
   - models/gemini-2.5-flash-exp-native-audio-thinking-dialog
     Display: Gemini 2.5 Flash Exp Native Audio Thinking Dialog
[OK] Diagnose Gemini Issues | SUCCESS  | Detailed diagnostic completed - check output above

Testing Mistral...
[OK] Mistral              | SUCCESS  | Connected successfully. Working models: mistral-large-latest (Latest large model), mistral-small-latest (Latest small model), pixtral-12b-2409 (Vision-language model)
   Cost: Cost: $2/M input, $6/M output

============================================================
SUMMARY
============================================================
Successful: 12
Failed: 0
Skipped: 0

Required APIs working: 3/3
TTS APIs working: 3/3
✅ All required APIs are working! You can run the data collection scripts.
   Gemini models have been verified and are ready for story generation.
✅ TTS Collection Ready: 3 providers available for comparative analysis
   Working providers: OpenAI TTS, Google Cloud TTS, ElevenLabs TTS
   📋 Note: Azure & AWS excluded due to account validation challenges

Next steps:
   1. ✅ Story Generation Ready
   2. Run: python 01_image_captioning_collect.py
   3. Run: python 02_story_generation_collect.py
   4. ✅ TTS Ready - Run: python 03_tts_collect.py

Cost estimate for full test suite: <$0.01
   Story generation collection: $20-50 depending on usage
   TTS collection: $2-5 for comprehensive comparison

💡 TIP: Copy working model names from test output above
   and update the story_models list in 02_story_generation_collect.py

💡 TTS READY: Multiple providers configured for comparative analysis
   Your 03_tts_collect.py script will work with all available providers

📊 RESEARCH IMPACT:
   Story Models: 3 working
   TTS Providers: 3 working
   Total Cost: <$55 for complete comparative analysis

API key testing completed!
