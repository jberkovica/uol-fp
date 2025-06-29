"""
Story generation prompts for Mira Storyteller application.
"""

STORY_GENERATION_PROMPT = '''Create a family-friendly story inspired by this image description: "{image_caption}"

Story Requirements:
- Write exactly 150-200 words
- Target audience: young readers and families
- Theme: suitable for reading aloud at bedtime or story time
- Tone: warm, gentle, and comforting
- Include a positive message or gentle life lesson
- Use simple, accessible language
- End on a peaceful, happy note
- Include an engaging title

Response Format:
Title: [Your Story Title]

[Your complete 150-200 word story]

Note: Adherence to the 150-200 word count is essential for evaluation purposes.'''

STORY_SYSTEM_MESSAGE = 'You are a professional story writer. Follow all formatting and word count requirements precisely.'

# Model configuration
STORY_MODEL_CONFIG = {
    'temperature': 0.7,
    'max_tokens': 350,
}