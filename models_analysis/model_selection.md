# Model Selection and Justification

## Introduction

This document outlines the models selected for the Storyteller app project, the reasoning behind their selection, and the scope of their evaluation. The project utilizes a combination of state-of-the-art open-source and commercial models to create a pipeline for generating children's stories from images.

## Model Types and Tasks

The project requires three primary AI capabilities:

1. **Image Captioning**: Converting visual content into descriptive text
2. **Story Generation**: Creating engaging children's stories based on image captions
3. **Text-to-Speech**: Converting generated stories into spoken audio

## Model Selection Criteria

Models were selected based on the following criteria:

1. **Performance**: Accuracy, quality, and appropriateness for children's content
2. **Accessibility**: Preference for open-source models via hosted APIs
3. **Cost-efficiency**: Balancing performance with computational and financial costs
4. **Ethical considerations**: Safety, fairness, and appropriateness for children
5. **Technical feasibility**: Compatibility with the project infrastructure

## Selected Models

### Image Captioning Models

| Model | Type | Source | Justification |
|-------|------|--------|---------------|
| BLIP-2 | Open-source | Replicate | State-of-the-art performance for image understanding with rich descriptive outputs |
| CogVLM | Open-source | Replicate | Strong visual reasoning capabilities with detailed caption generation |
| ViT-GPT2 | Open-source | Replicate | Efficient baseline model with good performance-to-cost ratio |
| Gemini 2.5 Pro Vision | Commercial | Google | High-quality detailed captions, useful as comparison benchmark |
| GPT-4o Vision | Commercial | OpenAI | Best-in-class visual understanding, used as upper benchmark |

### Story Generation Models

| Model | Type | Source | Justification |
|-------|------|--------|---------------|
| Llama-3-70b | Open-source | Replicate | Excellent creative text generation with strong reasoning |
| Mixtral-8x7B | Open-source | Replicate | Strong performance with mixture-of-experts architecture |
| Phi-3 | Open-source | Replicate | Microsoft's efficient model with good performance and educational focus |
| Qwen3-8B | Open-source | Replicate | Alibaba's competitive model with strong multilingual capability |
| Gemini 2.0 Pro | Commercial | Google | High-quality text generation, used as benchmark |
| GPT-4o | Commercial | OpenAI | State-of-the-art text generation, used as upper benchmark |
| Claude 3.5 Sonnet | Commercial | Anthropic | Known for engaging writing style and safety features |

## API-Based Approach

**Important Note**: Due to deployment limitations with Hugging Face's Inference API, we've switched to using Replicate for all open-source model inference. This change ensures reliable model availability and consistent API access patterns.

All models are accessed through their respective cloud APIs rather than running locally. This design decision was made for several reasons:

1. **Accessibility**: Eliminates hardware requirements for running large models
2. **Consistency**: Ensures reproducible results across different environments
3. **Resource efficiency**: Avoids the computational overhead of running models locally
4. **Maintainability**: Simplifies the codebase and reduces dependency complexity
5. **Up-to-date models**: Access to the latest model versions without manual updates

### Cloud API Providers

- **Replicate**: Primary source for open-source models (BLIP-2, CogVLM, ViT-GPT2, Llama-3, Mixtral, Phi-3, Qwen3, SpeechT5, XTTS, Piper, Mozilla TTS)
- **Google**: Provides access to Gemini models
- **OpenAI**: Provides access to GPT-4o models
- **Anthropic**: Provides access to Claude models (optional comparison)

## Evaluation Framework

Each model is evaluated using a comprehensive framework that assesses:

1. **Quality**: Overall quality and coherence of outputs
2. **Relevance**: Connection between image content and generated stories
3. **Child-appropriateness**: Suitability for the target audience (ages 4-8)
4. **Performance**: Speed and computational requirements
5. **Cost**: API pricing and usage considerations

## Implementation Notes

- All models are accessed via REST API calls with appropriate authentication
- Error handling and retry mechanisms are implemented for all API calls
- Evaluation results are saved to CSV files for analysis and comparison
- A unified prompt template ensures consistent instructions across all models
- Separate evaluation notebooks exist for each stage of the pipeline

## Limitations and Future Work

- Open-source models accessed via Replicate may have varying inference times depending on instance availability
- Commercial APIs have usage costs that scale with project requirements
- Model performance continues to evolve rapidly, requiring periodic re-evaluation
- Specialized models for children's content may emerge in the future

## Conclusion

The selected models represent a balance between state-of-the-art performance, accessibility, and cost considerations. By leveraging both open-source and commercial options via cloud APIs, the project maintains flexibility while ensuring high-quality outputs for the Storyteller app.
