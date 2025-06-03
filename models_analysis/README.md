# Image Captioning Model Evaluation Framework

A comprehensive framework for evaluating and comparing image captioning models across different APIs, with a focus on child-appropriate content and cost analysis.

## Overview

This framework evaluates several image captioning models from different providers:

**Replicate API Models:**
- BLIP
- BLIP-2
- CogVLM
- Vision Transformer (ViT)

**Commercial API Models:**
- Google Vision API
- Google Gemini
- OpenAI GPT-4o Vision

The evaluation pipeline performs the following:
1. Processes images through all models
2. Measures caption quality, response time, and child-appropriateness
3. Generates visualizations and comparison charts
4. Tracks API costs for each request/response
5. Saves detailed results for analysis
6. Provides recommendations based on weighted scoring

## Project Structure

```
models_analysis/
├── config/                    # Configuration files
│   ├── __init__.py
│   └── models_config.py       # API keys, endpoints, model IDs, paths, costs
├── utils/                     # Utility modules
│   ├── __init__.py
│   ├── api_clients.py         # API interaction functions with cost tracking
│   ├── evaluation.py          # Caption evaluation metrics
│   └── image_utils.py         # Image handling utilities
├── scripts/                   # Executable scripts
│   ├── __init__.py
│   ├── analyze_results.py     # Results analysis with cost considerations
│   ├── evaluate_models.py     # Main evaluation script
│   └── test_api_keys.py       # API key validation
├── data/                      # Image data directory
│   └── ...                    # Test images go here
├── output/                    # Output directory
│   ├── charts/                # Generated visualizations
│   ├── logs/                  # Log files
│   └── results/               # CSV results and reports
├── .env                       # Environment variables (create from .env.example)
├── .env.example               # Example environment file
└── README.md                  # This file
```

## Setup Instructions

### 1. Environment Setup

1. Clone the repository
2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install requests pandas matplotlib seaborn nltk tqdm pillow python-dotenv
   ```
4. Copy the example environment file and add your API keys:
   ```bash
   cp .env.example .env
   ```
5. Edit `.env` to add your API keys:
   - `REPLICATE_API_TOKEN` - Get from [Replicate](https://replicate.com/)
   - `GOOGLE_API_KEY` - Get from [Google Cloud Console](https://console.cloud.google.com/)
   - `OPENAI_API_KEY` - Get from [OpenAI](https://platform.openai.com/)

### 2. Prepare Test Images

Place test images in the `data/` directory. The framework will automatically detect and process them.

If you have expected captions for comparison, you can create an `annotations.json` file in the `data/` directory with the following structure:
```json
{
  "image1.jpg": {
    "expected_caption": "A cat sitting on a chair",
    "type": "animal"
  },
  "image2.jpg": {
    "expected_caption": "A red car parked on the street",
    "type": "vehicle"
  }
}
```

## Usage

### Testing API Keys

Before running the full evaluation, verify that your API keys are working:

```bash
python -m models_analysis.scripts.test_api_keys
```

### Running the Evaluation

To evaluate all models on your test images:

```bash
python -m models_analysis.scripts.evaluate_models
```

This will:
- Process all images in the `data/` directory
- Generate captions from all models
- Evaluate caption quality
- Track API costs
- Create visualizations
- Save results to CSV files

### Analyzing Results

To analyze previously generated results:

```bash
python -m models_analysis.scripts.analyze_results
```

Or to specify a specific results file:

```bash
python -m models_analysis.scripts.analyze_results --results output/results/caption_results_20250603_093000.csv
```

## Cost Tracking

This framework includes cost tracking for all API requests:

### Model Cost Structure
- **Replicate API**: Fixed cost per request for each model
- **Google Vision API**: Tiered pricing based on monthly usage
- **Google Gemini API**: Per-input token pricing
- **OpenAI GPT-4o Vision**: Input and output token-based pricing

Cost information is tracked for each request and included in the evaluation results, allowing you to:
- Compare model performance vs. cost
- Budget API usage for large-scale evaluations
- Identify the most cost-effective models for your use case

View cost information in:
- The CSV results file (cost per image)
- Summary statistics in the analysis report
- Cost efficiency visualizations

## Output

The framework generates several outputs:

1. **CSV Results**:
   - Detailed results with captions, metrics, and costs for each image and model
   - Summary statistics for each model

2. **Visualizations**:
   - Caption quality comparison charts
   - Response time comparison
   - Child-appropriateness metrics
   - Advanced metrics (BLEU, METEOR)
   - Performance radar charts
   - Cost-effectiveness charts

3. **HTML Report**:
   - Comprehensive recommendation report with interactive visualizations

4. **Logs**:
   - Detailed logs of the evaluation process
   - Error tracking and debugging information

## Extending the Framework

### Adding New Models

To add a new model to the evaluation:

1. Add the model details to `config/models_config.py`, including cost information
2. Create a corresponding function in `utils/api_clients.py`
3. Update the model lists in `scripts/evaluate_models.py`

### Custom Evaluation Metrics

To add custom evaluation metrics:

1. Implement the metric function in `utils/evaluation.py`
2. Update the evaluation process in `scripts/evaluate_models.py`
3. Add visualization for the new metric in `scripts/analyze_results.py`

## Troubleshooting

### Common Issues

1. **API Key Issues**:
   - Verify API keys are correctly set in your `.env` file
   - Check that you have sufficient credits/quota for each service
   - Run the test_api_keys.py script to validate all keys

2. **Image Processing Errors**:
   - Ensure images are in a supported format (JPEG, PNG)
   - Check that file paths are correct
   - Verify image file sizes are within API limits

3. **Module Import Errors**:
   - Make sure all dependencies are installed
   - Run scripts from the project root directory
   - Check that the directory structure is maintained

### Logging

The framework uses comprehensive logging to help diagnose issues:

- Log files are stored in the `output/logs/` directory
- Check logs for detailed error messages
- Set log level by modifying the logging configuration in scripts

## Resources

- [Replicate API Documentation](https://replicate.com/docs)
- [Google Cloud Vision API Documentation](https://cloud.google.com/vision/docs)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [NLTK Documentation](https://www.nltk.org/) for NLP metrics
