# Safety Filter Investigation: Gemini 2.5 Preview Models

## Summary

During the development of our story generation evaluation system, we encountered systematic safety filter blocks with Google's Gemini 2.5 preview models. This document details our investigation, findings, and the decision to exclude these models from our comparison.

## Background

Our evaluation system compares story generation capabilities across multiple LLM providers using a standardized prompt for children's stories based on image captions. While 8 out of 10 models worked perfectly, both Gemini 2.5 preview models consistently failed with safety filter blocks.

## Investigation Process

### Initial Problem

-   **Gemini 2.5 Pro Preview** and **Gemini 2.5 Flash Preview** returned "Content blocked by safety filters"
-   All other models (OpenAI GPT-4o series, Anthropic Claude 3.5 series, Google Gemini 2.0/1.5 series) worked perfectly
-   Issue occurred even with extremely permissive safety settings (`BLOCK_NONE` for all categories)

### Hypothesis 1: Age-Specific Content Triggering Child Safety Filters

**Initial Theory**: The explicit mention of "children aged 4-8" was triggering Google's non-configurable child safety protections.

**Test**: Modified prompts to remove age references:

-   Changed "children aged 4-8" → "young readers and families"
-   Changed "children's story" → "family-friendly story"
-   Changed "age-appropriate" → "accessible"

**Result**: Still blocked. Age references were not the primary trigger.

### Hypothesis 2: Story Generation Context Issues

**Theory**: The combination of story generation + family context was triggering safety filters.

**Test**: Created 6 different prompt variations:

1. Creative writing focus (literary fiction)
2. General audience storytelling
3. Literary/artistic approach
4. Educational/nature writing
5. Adult literary fiction (explicitly targeting adults)
6. Minimal guidelines approach

**Result**: All variations still blocked. The issue was not prompt-specific.

### Hypothesis 3: Technical Implementation Issues

**Theory**: Our API implementation had bugs causing false "blocked" reports.

**Test**: Improved error handling to distinguish between:

-   Actual safety blocks
-   API errors
-   Response structure issues

**Result**: Confirmed these were genuine safety filter blocks, not technical errors.

## Key Findings

### 1. Documentation Review Results

According to [Google's safety settings documentation](https://ai.google.dev/gemini-api/docs/safety-settings):

-   **Stable GA models** (like Gemini 2.0 Flash, 1.5 Pro): Default to **"Block none"** (permissive)
-   **Preview models** (like Gemini 2.5 series): Default to **"Block some"** (restrictive)
-   **Non-configurable child safety filters** exist that "are always blocked and cannot be adjusted"

### 2. Model Behavior Patterns

| Model Category              | Safety Behavior                      | Story Generation Success |
| --------------------------- | ------------------------------------ | ------------------------ |
| Gemini 2.0/1.5 (Stable)     | Permissive defaults                  | Working                  |
| Gemini 2.5 (Preview)        | Restrictive defaults + extra filters | Blocked                  |
| OpenAI GPT-4o series        | Standard safety                      | Working                  |
| Anthropic Claude 3.5 series | Standard safety                      | Working                  |

### 3. Root Cause Analysis

The Gemini 2.5 preview models appear to have **enhanced safety restrictions** that:

-   Interpret story generation requests as potentially related to child safety
-   Trigger non-configurable safety filters that cannot be bypassed
-   Are more conservative than production-ready models

## Technical Limitations

### 1. Non-Configurable Safety Filters

Google's documentation explicitly states that child safety protections "cannot be adjusted." Our testing confirmed that even with all configurable filters set to `BLOCK_NONE`, the blocks persisted.

### 2. Preview Model Restrictions

Preview models are experimental and have different safety behaviors than stable models, making them unsuitable for fair comparison with production-ready alternatives.

### 3. API Response Limitations

When content is blocked, the API provides minimal feedback about the specific trigger, making it difficult to develop targeted workarounds.

## Decision: Exclude Gemini 2.5 Preview Models

### Rationale

1. **Scientific Validity**: Including models with different safety constraints would compromise comparison fairness
2. **Technical Reality**: Preview models don't represent the user experience of production systems
3. **Comprehensive Coverage**: 8 working models provide excellent representation across all major providers
4. **Future Compatibility**: When 2.5 models reach stable GA status, they'll likely adopt the permissive defaults

### Final Model Set (8 Models)

| Provider      | Models Included                                      | Working Status |
| ------------- | ---------------------------------------------------- | -------------- |
| **OpenAI**    | GPT-4o, GPT-4o-mini                                  | Both working   |
| **Anthropic** | Claude 3.5 Sonnet, Claude 3.5 Haiku                  | Both working   |
| **Google**    | Gemini 2.0 Flash, 2.0 Flash Lite, 1.5 Pro, 1.5 Flash | All working    |
| **Google**    | ~~Gemini 2.5 Pro Preview, 2.5 Flash Preview~~        | Excluded       |

## Impact on Research

### Strengths of Current Approach

-   **Balanced representation**: 2 models each from OpenAI and Anthropic, 4 from Google
-   **Production-ready models**: All included models represent real user experiences
-   **Cost range coverage**: From $0.000175 to $0.004925 per story
-   **Performance range coverage**: From 1.98s to 12.96s response times

### Limitations

-   **Missing latest models**: Gemini 2.5 series excluded despite being newest
-   **Google over-representation**: 4/8 models from Google vs 2/8 from other providers
-   **Preview model gap**: Cannot evaluate cutting-edge experimental capabilities

### Mitigation Strategies

1. **Document clearly**: This investigation serves as documentation for the exclusion
2. **Future re-evaluation**: Test 2.5 models again when they reach stable GA status
3. **Alternative approaches**: Consider testing 2.5 models with completely different use cases (non-story generation)

## Recommendations

### For This Research

-   Proceed with 8-model comparison for fair, scientifically valid results
-   Note limitations in research methodology section
-   Consider this a strength (production-ready model focus) rather than weakness

### For Future Work

-   Monitor Gemini 2.5 model status and re-test when stable
-   Investigate if other story generation approaches work with 2.5 models
-   Consider separate evaluation of preview model safety behaviors as independent research

## Conclusion

While initially concerning, the Gemini 2.5 safety filter blocks led to a more robust and scientifically sound evaluation methodology. By focusing on production-ready models with consistent safety behaviors, our comparison provides more reliable insights for practical applications.

The 8-model evaluation set offers comprehensive coverage of current state-of-the-art capabilities while maintaining experimental validity through consistent model selection criteria.
