---
## Evaluation & Testing Plan (Phased Approach)

This plan is divided into **three phases**, each aligned with the stages of your project: experimentation (Jupyter), PoC (prototype), and final delivery (with testing).
---

### Phase 1: Experimentation (Model Testing in Jupyter)

**Purpose**: Identify the best models for captioning, story generation, and TTS through controlled testing using a small dataset (5 kids’ drawings, 5 toy photos).

**Outputs**: Comparative analysis, charts, logs, and selection rationale for models.

### 🔍 Metrics & Methods

| **Metric**          | **What It Measures**            | **How You Measure It**                     |
| ------------------- | ------------------------------- | ------------------------------------------ |
| API Latency         | Real response time              | Log API call timestamps (programmatically) |
| Accuracy            | Relevance of caption to image   | Manually label expected captions, compare  |
| Kid-Safety          | Child-appropriate language      | Manual flagging if output is inappropriate |
| Sketch Robustness   | Handles abstract/messy drawings | Test with diverse sketch inputs            |
| Creativity (LLM)    | Story richness and coherence    | Manual 1–5 scoring + notes                 |
| Voice Clarity (TTS) | Pronunciation and tone          | Manual listening, subjective 1–5 rating    |

### Sample Model Evaluation Table

| Model/API           | Speed (sec) | Accuracy (1–5) | Kid-Safe? | Handles Sketches? | Notes                          |
| ------------------- | ----------- | -------------- | --------- | ----------------- | ------------------------------ |
| Google Cloud Vision | 1.2         | 4              | ✅        | ✅                | Stable, generic output         |
| Hugging Face BLIP   | 2.8         | 3              | ✅        | ❌                | Struggles with abstract shapes |
| LLaVA               | 3.4         | 5              | ✅        | ✅                | Rich captions, slower latency  |

> This phase will be implemented in a Jupyter notebook. You’ll load test images, call APIs, log results, and visualize metrics.

---

### Phase 2: PoC Testing (Prototype UI + Model Integration)

**Purpose**: Build and connect a basic Flutter UI with the selected APIs. Validate full pipeline and initial user interaction.

### What You Test

| **Component**     | **What’s Tested**               | **Method**                                   |
| ----------------- | ------------------------------- | -------------------------------------------- |
| UI Flow           | Upload → story → audio          | Manual walkthrough                           |
| Model Integration | Real API results in app context | Check live vs Jupyter outputs                |
| Error Handling    | Blank/malformed images          | Test & log fallback behavior                 |
| Edge Cases        | Ambiguous images                | Manually crafted test set                    |
| Smoke Test        | Parent-user tries app           | Quick verbal feedback only (no formal study) |

### Additional Testing

-   **Unit tests**: Core backend functions (e.g. caption-to-prompt)
-   **Functional tests**: API call success, image load, audio playback
-   **Manual QA**: UI responsiveness, text/audio sync

---

### Phase 3: Delivery Phase Testing (Final App & User Testing)

**Purpose**: Evaluate full functionality, reliability, and child/parent usability.

### User Testing Plan

| **Tester**       | **Task**                 | **Measured**                   | **Method**                  |
| ---------------- | ------------------------ | ------------------------------ | --------------------------- |
| Parent + Child   | Upload image → get story | Engagement, clarity, enjoyment | Observation + feedback form |
| You (dev/parent) | Full session testing     | Edge cases, bugs, flow issues  | Structured test checklist   |

### System-Level Tests

| **Test Type**      | **Purpose**                  | **Tools/Method**                        |
| ------------------ | ---------------------------- | --------------------------------------- |
| Regression test    | Ensure no model regressions  | Snapshot test outputs weekly            |
| Performance test   | Measure overall latency      | Log total pipeline time                 |
| Accessibility test | App clarity for parents/kids | Checklist (large buttons, font, audio)  |
| Content test       | Validate story consistency   | Sample 10 images and review output flow |

---

## Summary Table of Evaluation Coverage

| **Phase**       | **Goal**                           | **Who**        | **Tools/Location**  | **Scope**                           |
| --------------- | ---------------------------------- | -------------- | ------------------- | ----------------------------------- |
| Experimentation | Select best models                 | You            | Jupyter Notebook    | Model output logs, metrics, visuals |
| PoC             | Validate pipeline + early feedback | You + 1 parent | Flutter app (local) | Smoke test, API integration checks  |
| Delivery        | Final polish + real user testing   | Parent + child | Full app            | Full pipeline, UX + content quality |

---
