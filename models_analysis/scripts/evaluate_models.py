#!/usr/bin/env python3
"""
Main script for evaluating image captioning models.

This script:
1. Sets up logging
2. Loads test images and annotations
3. Runs captioning models on the images
4. Evaluates and compares results
5. Generates visualizations
6. Saves results to output files
"""
import os
import sys
import json
import logging
import time
from datetime import datetime
from tqdm import tqdm
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Add parent directory to path so we can import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models_analysis.config.models_config import (
    DATA_FOLDER, OUTPUT_FOLDER, CHARTS_FOLDER, RESULTS_FOLDER, LOGS_FOLDER,
    ANNOTATIONS_PATH
)
from models_analysis.utils.image_utils import get_image_files, save_display_image, load_image_bytes
from models_analysis.utils.api_clients import (
    get_replicate_blip_caption,
    get_replicate_blip2_caption,
    get_replicate_cogvlm_caption,
    get_replicate_vit_caption,
    get_google_vision_caption,
    get_gemini_caption,
    get_openai_vision_caption
)
from models_analysis.utils.evaluation import (
    evaluate_caption_similarity,
    evaluate_child_appropriateness,
    calculate_bleu_score,
    calculate_meteor_score,
    calculate_combined_score
)

# Set up logging
def setup_logging():
    """Configure logging to file and console."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(LOGS_FOLDER, f"caption_evaluation_{timestamp}.log")
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Set up file handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)
    
    # Set up console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG)
    root_logger.addHandler(file_handler)
    root_logger.addHandler(console_handler)
    
    return log_file

def load_annotations():
    """Load annotation data from JSON file."""
    annotations = {}
    if os.path.exists(ANNOTATIONS_PATH):
        try:
            with open(ANNOTATIONS_PATH, 'r') as f:
                annotations = json.load(f)
            logging.info(f"Loaded {len(annotations)} annotations from {ANNOTATIONS_PATH}")
        except Exception as e:
            logging.error(f"Error loading annotations: {e}")
    else:
        logging.warning(f"Annotations file {ANNOTATIONS_PATH} not found. Creating empty annotations.")
    
    return annotations

def update_annotations(annotations, image_files):
    """Update annotations with any missing images."""
    updated = False
    for img_file in image_files:
        if img_file not in annotations:
            annotations[img_file] = {"expected_caption": "", "type": "unknown"}
            updated = True
    
    if updated:
        try:
            with open(ANNOTATIONS_PATH, 'w') as f:
                json.dump(annotations, f, indent=2)
            logging.info(f"Updated annotations saved to {ANNOTATIONS_PATH}")
        except Exception as e:
            logging.error(f"Error saving annotations: {e}")

def evaluate_images(image_files, annotations, max_images=None, verbose=True):
    """
    Run evaluation on all specified image files.
    
    Args:
        image_files: List of image filenames
        annotations: Dictionary of annotations
        max_images: Maximum number of images to process (None for all)
        verbose: Whether to print progress
        
    Returns:
        DataFrame with results
    """
    results = []
    
    # Limit number of images if specified
    if max_images is not None and max_images > 0:
        image_files = image_files[:max_images]
    
    # Process each image
    for filename in tqdm(image_files, desc="Processing images"):
        filepath = os.path.join(DATA_FOLDER, filename)
        expected = annotations[filename].get("expected_caption", "")
        
        # Load image as bytes once
        image_bytes = load_image_bytes(filepath)
        
        # Save a preview of the image
        output_image_path = os.path.join(CHARTS_FOLDER, f"preview_{filename}")
        save_display_image(filepath, output_image_path)
        
        # Run all models
        logging.info(f"Processing image: {filename}")
        
        # Replicate models
        blip_caption, blip_time, blip_cost = get_replicate_blip_caption(filepath)
        blip2_caption, blip2_time, blip2_cost = get_replicate_blip2_caption(filepath)
        cogvlm_caption, cogvlm_time, cogvlm_cost = get_replicate_cogvlm_caption(filepath)
        vit_caption, vit_time, vit_cost = get_replicate_vit_caption(filepath)
        
        # Google models
        gvision_caption, gvision_time, gvision_cost = get_google_vision_caption(image_bytes)
        gemini_caption, gemini_time, gemini_cost = get_gemini_caption(image_bytes)
        
        # OpenAI model
        gpt4o_caption, gpt4o_time, gpt4o_cost = get_openai_vision_caption(filepath)
        
        # Evaluate each caption
        models = {
            'blip': (blip_caption, blip_time, blip_cost),
            'blip2': (blip2_caption, blip2_time, blip2_cost),
            'cogvlm': (cogvlm_caption, cogvlm_time, cogvlm_cost),
            'vit': (vit_caption, vit_time, vit_cost),
            'gvision': (gvision_caption, gvision_time, gvision_cost),
            'gemini': (gemini_caption, gemini_time, gemini_cost),
            'gpt4o': (gpt4o_caption, gpt4o_time, gpt4o_cost)
        }
        
        result = {
            'filename': filename,
            'expected': expected
        }
        
        # Evaluate each model
        for model_name, (caption, exec_time, cost) in models.items():
            # Basic metrics
            similarity_score = evaluate_caption_similarity(expected, caption)
            appropriate = evaluate_child_appropriateness(caption)
            
            # Advanced metrics if expected caption exists
            bleu_score = 0
            meteor_score = 0
            combined_score = 0
            
            if expected:
                bleu_score = calculate_bleu_score(expected, caption)
                meteor_score = calculate_meteor_score(expected, caption)
                combined_score = calculate_combined_score(expected, caption)
            
            # Calculate cost-effectiveness (score per dollar)
            cost_effectiveness = 0
            if cost > 0:
                cost_effectiveness = combined_score / cost
            
            # Add to results
            result[f"{model_name}_caption"] = caption
            result[f"{model_name}_time"] = round(exec_time, 2)
            result[f"{model_name}_cost"] = round(cost, 6)
            result[f"{model_name}_cost_effectiveness"] = round(cost_effectiveness, 2)
            result[f"{model_name}_score"] = similarity_score
            result[f"{model_name}_appropriate"] = appropriate
            result[f"{model_name}_bleu"] = round(bleu_score, 3)
            result[f"{model_name}_meteor"] = round(meteor_score, 3)
            result[f"{model_name}_combined"] = round(combined_score, 2)
        
        results.append(result)
        
        # Print progress if verbose
        if verbose:
            print(f"\nProcessed: {filename}")
            print(f"Expected: {expected}")
            print(f"\n--- Replicate Models ---")
            print(f"BLIP: {blip_caption}")
            print(f"  Score: {result['blip_score']}/5, Time: {result['blip_time']}s, Cost: ${result['blip_cost']:.6f}")
            print(f"BLIP-2: {blip2_caption}")
            print(f"  Score: {result['blip2_score']}/5, Time: {result['blip2_time']}s, Cost: ${result['blip2_cost']:.6f}")
            print(f"CogVLM: {cogvlm_caption}")
            print(f"  Score: {result['cogvlm_score']}/5, Time: {result['cogvlm_time']}s, Cost: ${result['cogvlm_cost']:.6f}")
            print(f"ViT: {vit_caption}")
            print(f"  Score: {result['vit_score']}/5, Time: {result['vit_time']}s, Cost: ${result['vit_cost']:.6f}")
            print(f"\n--- Google Models ---")
            print(f"Vision API: {gvision_caption}")
            print(f"  Score: {result['gvision_score']}/5, Time: {result['gvision_time']}s, Cost: ${result['gvision_cost']:.6f}")
            print(f"Gemini: {gemini_caption}")
            print(f"  Score: {result['gemini_score']}/5, Time: {result['gemini_time']}s, Cost: ${result['gemini_cost']:.6f}")
            print(f"\n--- OpenAI Model ---")
            print(f"GPT-4o: {gpt4o_caption}")
            print(f"  Score: {result['gpt4o_score']}/5, Time: {result['gpt4o_time']}s, Cost: ${result['gpt4o_cost']:.6f}")
    
    return pd.DataFrame(results)

def create_visualizations(df_results):
    """
    Create and save visualizations of results.
    
    Args:
        df_results: DataFrame with evaluation results
    """
    # Calculate average scores and times
    model_names = ["BLIP", "BLIP-2", "CogVLM", "ViT", "Google Vision", "Gemini", "GPT-4o"]
    model_keys = ["blip", "blip2", "cogvlm", "vit", "gvision", "gemini", "gpt4o"]
    
    model_summary = pd.DataFrame({
        "Model": model_names,
        "Avg Score": [df_results[f"{key}_score"].mean() for key in model_keys],
        "Avg Time (s)": [df_results[f"{key}_time"].mean() for key in model_keys],
        "Avg Cost ($)": [df_results[f"{key}_cost"].mean() for key in model_keys],
        "Cost-Effectiveness": [df_results[f"{key}_cost_effectiveness"].mean() for key in model_keys],
        "Child-Safe %": [df_results[f"{key}_appropriate"].mean() * 100 for key in model_keys],
        "Avg BLEU": [df_results[f"{key}_bleu"].mean() for key in model_keys],
        "Avg METEOR": [df_results[f"{key}_meteor"].mean() for key in model_keys],
        "Avg Combined": [df_results[f"{key}_combined"].mean() for key in model_keys]
    })
    
    # Print summary
    print("\nModel Performance Summary:")
    print(model_summary)
    
    # Create timestamp for filenames
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # 1. Bar chart of average caption quality
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x="Model", y="Avg Score", data=model_summary)
    ax.bar_label(ax.containers[0], fmt='%.2f')
    plt.title("Average Caption Quality Score by Model")
    plt.ylim(0, 5.5)
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    quality_chart_path = os.path.join(CHARTS_FOLDER, f"caption_quality_{timestamp}.png")
    plt.savefig(quality_chart_path)
    plt.close()
    
    # 2. Bar chart of average response time
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x="Model", y="Avg Time (s)", data=model_summary)
    ax.bar_label(ax.containers[0], fmt='%.2f')
    plt.title("Average Response Time by Model")
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    time_chart_path = os.path.join(CHARTS_FOLDER, f"response_time_{timestamp}.png")
    plt.savefig(time_chart_path)
    plt.close()
    
    # 3. Bar chart of child-appropriateness
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x="Model", y="Child-Safe %", data=model_summary)
    ax.bar_label(ax.containers[0], fmt='%.1f%%')
    plt.title("Percentage of Child-Appropriate Captions by Model")
    plt.ylim(0, 110)
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    appropriate_chart_path = os.path.join(CHARTS_FOLDER, f"child_appropriate_{timestamp}.png")
    plt.savefig(appropriate_chart_path)
    plt.close()
    
    # 4. Advanced metrics comparison
    plt.figure(figsize=(14, 8))
    metrics = pd.melt(model_summary, 
                     id_vars=['Model'], 
                     value_vars=['Avg BLEU', 'Avg METEOR', 'Avg Combined'],
                     var_name='Metric', value_name='Score')
    sns.barplot(x='Model', y='Score', hue='Metric', data=metrics)
    plt.title("Advanced Metrics Comparison by Model")
    plt.ylim(0, 1.1)
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.legend(title='Metric')
    plt.tight_layout()
    metrics_chart_path = os.path.join(CHARTS_FOLDER, f"advanced_metrics_{timestamp}.png")
    plt.savefig(metrics_chart_path)
    plt.close()
    
    # 5. Scatter plot of score vs. time
    plt.figure(figsize=(14, 10))
    
    # Define marker styles for different model types
    replicate_models = ["blip", "blip2", "cogvlm", "vit"]
    google_models = ["gvision", "gemini"]
    openai_models = ["gpt4o"]
    
    # Plot points for each model
    for key, name in zip(model_keys, model_names):
        times = df_results[f"{key}_time"]
        scores = df_results[f"{key}_score"]
        
        # Choose marker style based on model type
        if key in replicate_models:
            marker = "o"  # Circle for Replicate models
        elif key in google_models:
            marker = "s"  # Square for Google models
        else:
            marker = "^"  # Triangle for OpenAI models
        
        plt.scatter(times, scores, alpha=0.7, label=name, s=100, marker=marker)
    
    plt.xlabel("Response Time (s)")
    plt.ylabel("Caption Quality Score (0-5)")
    plt.title("Caption Quality vs. Response Time")
    plt.grid(True, alpha=0.3)
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    scatter_chart_path = os.path.join(CHARTS_FOLDER, f"quality_vs_time_{timestamp}.png")
    plt.savefig(scatter_chart_path)
    plt.close()
    
    # 6. Bar chart of average cost per model
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x="Model", y="Avg Cost ($)", data=model_summary)
    ax.bar_label(ax.containers[0], fmt='$%.4f')
    plt.title("Average API Cost per Model")
    plt.xticks(rotation=45)
    plt.ylabel("Average Cost ($)")
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    cost_chart_path = os.path.join(CHARTS_FOLDER, f"model_cost_{timestamp}.png")
    plt.savefig(cost_chart_path)
    plt.close()
    
    # 7. Bar chart of cost-effectiveness (combined score per dollar)
    plt.figure(figsize=(12, 6))
    ax = sns.barplot(x="Model", y="Cost-Effectiveness", data=model_summary)
    ax.bar_label(ax.containers[0], fmt='%.2f')
    plt.title("Cost-Effectiveness: Combined Score per Dollar")
    plt.xticks(rotation=45)
    plt.ylabel("Score per Dollar ($)")
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    cost_eff_chart_path = os.path.join(CHARTS_FOLDER, f"cost_effectiveness_{timestamp}.png")
    plt.savefig(cost_eff_chart_path)
    plt.close()
    
    # 8. Scatter plot of score vs. cost
    plt.figure(figsize=(14, 10))
    for key, name in zip(model_keys, model_names):
        costs = df_results[f"{key}_cost"]
        scores = df_results[f"{key}_combined"]
        
        # Choose marker style based on model type
        if key in replicate_models:
            marker = "o"  # Circle for Replicate models
        elif key in google_models:
            marker = "s"  # Square for Google models
        else:
            marker = "^"  # Triangle for OpenAI models
        
        plt.scatter(costs, scores, alpha=0.7, label=name, s=100, marker=marker)
    
    plt.xlabel("Cost per Caption ($)")
    plt.ylabel("Combined Score (0-1)")
    plt.title("Caption Quality vs. Cost")
    plt.grid(True, alpha=0.3)
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    quality_cost_chart_path = os.path.join(CHARTS_FOLDER, f"quality_vs_cost_{timestamp}.png")
    plt.savefig(quality_cost_chart_path)
    plt.close()
    
    return {
        'summary': model_summary,
        'charts': {
            'quality': quality_chart_path,
            'time': time_chart_path,
            'appropriate': appropriate_chart_path,
            'metrics': metrics_chart_path,
            'scatter': scatter_chart_path,
            'cost': cost_chart_path,
            'cost_effectiveness': cost_eff_chart_path,
            'quality_vs_cost': quality_cost_chart_path
        }
    }

def save_results(df_results, model_summary):
    """
    Save results to CSV files.
    
    Args:
        df_results: DataFrame with evaluation results
        model_summary: DataFrame with model summary
        
    Returns:
        Dictionary with paths to saved files
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Save detailed results
    results_file = os.path.join(RESULTS_FOLDER, f"caption_results_{timestamp}.csv")
    df_results.to_csv(results_file, index=False)
    logging.info(f"Results saved to {results_file}")
    
    # Save model summary
    summary_file = os.path.join(RESULTS_FOLDER, f"model_summary_{timestamp}.csv")
    model_summary.to_csv(summary_file, index=False)
    logging.info(f"Model summary saved to {summary_file}")
    
    return {
        'results': results_file,
        'summary': summary_file
    }

def find_best_model(model_summary):
    """
    Determine the best overall model based on weighted criteria.
    
    Args:
        model_summary: DataFrame with model summary
        
    Returns:
        Dictionary with best model details
    """
    # Calculate overall best model based on weighted criteria
    model_summary["Combined_Score"] = (
        model_summary["Avg Score"] * 0.5 +  # 50% weight on caption quality
        (5 - model_summary["Avg Time (s)"]) * 0.3 +  # 30% weight on speed (faster is better)
        model_summary["Child-Safe %"] / 20  # 20% weight on child-appropriateness
    )
    
    best_model_idx = model_summary["Combined_Score"].idxmax()
    best_model = model_summary.iloc[best_model_idx]["Model"]
    best_model_score = model_summary.iloc[best_model_idx]["Combined_Score"]
    
    logging.info(f"Best overall model: {best_model} with combined score {best_model_score:.2f}")
    
    return {
        'name': best_model,
        'score': best_model_score,
        'details': model_summary.iloc[best_model_idx].to_dict()
    }

def main():
    """Main execution function."""
    start_time = time.time()
    
    # Setup logging
    log_file = setup_logging()
    logging.info("Starting image caption model evaluation")
    
    # Load annotations and image files
    annotations = load_annotations()
    image_files = get_image_files(DATA_FOLDER)
    update_annotations(annotations, image_files)
    
    # Evaluate models
    max_images = None  # Set to a number to limit the number of images processed
    df_results = evaluate_images(image_files, annotations, max_images)
    
    # Create visualizations
    viz_results = create_visualizations(df_results)
    
    # Save results
    saved_files = save_results(df_results, viz_results['summary'])
    
    # Find best model
    best_model = find_best_model(viz_results['summary'])
    
    # Print conclusion
    print(f"\nBest Overall Model: {best_model['name']}")
    print("\nRecommendation:")
    print(f"Based on our evaluation, {best_model['name']} provides the best balance of caption quality,")
    print("response time, and child-appropriateness for the Storyteller app.")
    print("\nConsiderations:")
    print("- Cost: API pricing for commercial deployment")
    print("- Integration complexity: SDK availability and maintenance")
    print("- Privacy: Data handling policies for children's content")
    print("- Scalability: Performance under high load")
    
    # Log completion
    elapsed_time = time.time() - start_time
    logging.info(f"Evaluation complete in {elapsed_time:.2f} seconds")
    logging.info(f"Log file: {log_file}")
    logging.info(f"Results file: {saved_files['results']}")
    logging.info(f"Summary file: {saved_files['summary']}")
    logging.info(f"Charts saved to: {CHARTS_FOLDER}")
    
    return {
        'results': df_results,
        'summary': viz_results['summary'],
        'best_model': best_model,
        'files': {
            'log': log_file,
            'results': saved_files['results'],
            'summary': saved_files['summary'],
            'charts': viz_results['charts']
        }
    }

if __name__ == "__main__":
    main()
