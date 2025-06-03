#!/usr/bin/env python3
"""
Analysis script for processing and visualizing image captioning evaluation results.

This script can be run independently of the main evaluation to analyze
previously generated results. It provides:
1. Comparative analysis of model performance
2. Custom visualizations and charts
3. Statistical analysis of results
4. Recommendation generation based on weighted scoring
"""
import os
import sys
import argparse
import logging
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

# Add parent directory to path so we can import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models_analysis.config.models_config import (
    OUTPUT_FOLDER, CHARTS_FOLDER, RESULTS_FOLDER, LOGS_FOLDER
)

def setup_logging():
    """Configure logging to file and console."""
    os.makedirs(LOGS_FOLDER, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(LOGS_FOLDER, f"analysis_{timestamp}.log")
    
    # Configure logging format
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    
    return log_file

def load_results(results_file):
    """
    Load results from a previously generated CSV file.
    
    Args:
        results_file: Path to CSV file with results
        
    Returns:
        DataFrame with results
    """
    try:
        df = pd.read_csv(results_file)
        logging.info(f"Loaded results from {results_file} with {len(df)} records")
        return df
    except Exception as e:
        logging.error(f"Error loading results from {results_file}: {e}")
        print(f"ERROR: Could not load results from {results_file}: {e}")
        sys.exit(1)

def generate_model_summary(df):
    """
    Generate summary statistics for each model.
    
    Args:
        df: DataFrame with results
        
    Returns:
        DataFrame with model summary
    """
    model_names = ["BLIP", "BLIP-2", "CogVLM", "ViT", "Google Vision", "Gemini", "GPT-4o"]
    model_keys = ["blip", "blip2", "cogvlm", "vit", "gvision", "gemini", "gpt4o"]
    
    model_summary = pd.DataFrame({
        "Model": model_names,
        "Avg Score": [df[f"{key}_score"].mean() for key in model_keys],
        "Median Score": [df[f"{key}_score"].median() for key in model_keys],
        "Min Score": [df[f"{key}_score"].min() for key in model_keys],
        "Max Score": [df[f"{key}_score"].max() for key in model_keys],
        "Avg Time (s)": [df[f"{key}_time"].mean() for key in model_keys],
        "Child-Safe %": [df[f"{key}_appropriate"].mean() * 100 for key in model_keys],
        "Avg BLEU": [df[f"{key}_bleu"].mean() for key in model_keys],
        "Avg METEOR": [df[f"{key}_meteor"].mean() for key in model_keys],
        "Avg Combined": [df[f"{key}_combined"].mean() for key in model_keys]
    })
    
    logging.info("Generated model summary statistics")
    return model_summary

def create_performance_chart(model_summary, output_path=None):
    """
    Create a radar/spider chart of model performance across multiple metrics.
    
    Args:
        model_summary: DataFrame with model summary
        output_path: Path to save the chart
    """
    # Select metrics for radar chart
    metrics = ['Avg Score', 'Child-Safe %', 'Avg BLEU', 'Avg METEOR', 'Cost-Effectiveness']
    
    # Normalize data to 0-1 scale for radar chart
    norm_data = model_summary.copy()
    for metric in metrics:
        if metric == 'Child-Safe %':
            norm_data[metric] = norm_data[metric] / 100
        elif metric == 'Avg Score':
            norm_data[metric] = norm_data[metric] / 5
        elif metric == 'Cost-Effectiveness':
            # Normalize cost-effectiveness (higher is better)
            max_cost_eff = norm_data[metric].max() if norm_data[metric].max() > 0 else 1
            norm_data[metric] = norm_data[metric] / max_cost_eff
    
    # Set up radar chart
    labels = metrics
    num_models = len(model_summary)
    
    # Create figure and polar axis
    fig, ax = plt.subplots(figsize=(10, 10), subplot_kw=dict(polar=True))
    
    # Set the angles for each metric
    angles = [n / float(len(labels)) * 2 * 3.14159 for n in range(len(labels))]
    angles += angles[:1]  # Close the loop
    
    # Set the chart to start at the top
    ax.set_theta_offset(3.14159 / 2)
    ax.set_theta_direction(-1)
    
    # Draw metric labels
    plt.xticks(angles[:-1], labels)
    
    # Draw y-axis labels
    ax.set_rlabel_position(0)
    plt.yticks([0.25, 0.5, 0.75], ["0.25", "0.5", "0.75"], color="grey", size=8)
    plt.ylim(0, 1)
    
    # Plot each model
    colors = plt.cm.tab10(range(num_models))
    for i, model in enumerate(model_summary['Model']):
        values = [norm_data.loc[norm_data['Model'] == model, metric].values[0] for metric in metrics]
        values += values[:1]  # Close the loop
        
        ax.plot(angles, values, linewidth=2, linestyle='solid', label=model, color=colors[i])
        ax.fill(angles, values, alpha=0.1, color=colors[i])
    
    # Add legend
    plt.legend(loc='upper right', bbox_to_anchor=(0.1, 0.1))
    plt.title("Model Performance Comparison", size=15, y=1.1)
    
    if output_path:
        plt.savefig(output_path, bbox_inches='tight')
        logging.info(f"Saved performance chart to {output_path}")
    
    plt.close()

def generate_visualizations(df_results, model_summary):
    """
    Generate and save visualizations of results.
    
    Args:
        df_results: DataFrame with evaluation results
        model_summary: DataFrame with model summary
    
    Returns:
        Dictionary with paths to saved charts
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Create charts folder if it doesn't exist
    os.makedirs(CHARTS_FOLDER, exist_ok=True)
    
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
    
    # 5. Performance radar chart
    radar_chart_path = os.path.join(CHARTS_FOLDER, f"performance_radar_{timestamp}.png")
    create_performance_chart(model_summary, radar_chart_path)
    
    # 6. Heatmap of model scores by image
    # Transform data for heatmap
    model_keys = ["blip", "blip2", "cogvlm", "vit", "gvision", "gemini", "gpt4o"]
    score_cols = [f"{key}_score" for key in model_keys]
    heatmap_data = df_results[['filename'] + score_cols].copy()
    
    # Rename columns to model names
    heatmap_data.columns = ['Filename'] + [col.split('_')[0].upper() for col in score_cols]
    
    # Set filename as index
    heatmap_data = heatmap_data.set_index('Filename')
    
    # Create heatmap
    plt.figure(figsize=(12, max(8, len(df_results) * 0.4)))
    sns.heatmap(heatmap_data, annot=True, cmap="YlGnBu", vmin=0, vmax=5, fmt=".1f")
    plt.title("Caption Quality Scores by Image and Model")
    plt.tight_layout()
    heatmap_path = os.path.join(CHARTS_FOLDER, f"score_heatmap_{timestamp}.png")
    plt.savefig(heatmap_path)
    plt.close()
    
    logging.info(f"Generated {6} visualization charts in {CHARTS_FOLDER}")
    
    return {
        'quality': quality_chart_path,
        'time': time_chart_path,
        'appropriate': appropriate_chart_path,
        'metrics': metrics_chart_path,
        'radar': radar_chart_path,
        'heatmap': heatmap_path
    }

def calculate_weighted_scores(model_summary, weights=None):
    """
    Calculate weighted scores for model recommendation.
    
    Args:
        model_summary: DataFrame with model summary
        weights: Dictionary of weights for different criteria
        
    Returns:
        DataFrame with weighted scores
    """
    if weights is None:
        weights = {
            'quality': 0.5,    # Caption quality (Avg Score)
            'speed': 0.2,      # Response time
            'safety': 0.2,     # Child appropriateness
            'metrics': 0.1     # Advanced metrics (BLEU, METEOR)
        }
    
    # Create a copy for calculations
    df = model_summary.copy()
    
    # Normalize response time (lower is better)
    max_time = df['Avg Time (s)'].max()
    df['Speed_Score'] = 1 - (df['Avg Time (s)'] / max_time)
    
    # Normalize other metrics to 0-1 scale
    df['Quality_Score'] = df['Avg Score'] / 5
    df['Safety_Score'] = df['Child-Safe %'] / 100
    df['Metrics_Score'] = (df['Avg BLEU'] + df['Avg METEOR']) / 2
    
    # Calculate weighted score
    df['Weighted_Score'] = (
        weights['quality'] * df['Quality_Score'] +
        weights['speed'] * df['Speed_Score'] +
        weights['safety'] * df['Safety_Score'] +
        weights['metrics'] * df['Metrics_Score']
    )
    
    # Calculate cost-effectiveness score (if time data available)
    # This assumes that more expensive models typically have better quality
    # but the score-to-time ratio helps identify models that provide good results quickly
    df['Efficiency_Score'] = df['Avg Score'] / df['Avg Time (s)']
    
    # Sort by weighted score
    df = df.sort_values('Weighted_Score', ascending=False)
    
    logging.info(f"Calculated weighted scores with weights: {weights}")
    return df

def generate_recommendations(weighted_scores):
    """
    Generate model recommendations based on weighted scores.
    
    Args:
        weighted_scores: DataFrame with weighted scores
        
    Returns:
        Dictionary with recommendations
    """
    # Get top model overall
    best_overall = weighted_scores.iloc[0]
    
    # Get most efficient model (best score/time ratio)
    most_efficient = weighted_scores.sort_values('Efficiency_Score', ascending=False).iloc[0]
    
    # Get best model for child safety
    safest = weighted_scores.sort_values('Child-Safe %', ascending=False).iloc[0]
    
    # Get best Replicate model
    replicate_models = ["BLIP", "BLIP-2", "CogVLM", "ViT"]
    best_replicate = weighted_scores[weighted_scores['Model'].isin(replicate_models)].iloc[0]
    
    recommendations = {
        'best_overall': {
            'model': best_overall['Model'],
            'weighted_score': best_overall['Weighted_Score'],
            'details': best_overall.to_dict()
        },
        'most_efficient': {
            'model': most_efficient['Model'],
            'efficiency_score': most_efficient['Efficiency_Score'],
            'details': most_efficient.to_dict()
        },
        'safest': {
            'model': safest['Model'],
            'safety_percent': safest['Child-Safe %'],
            'details': safest.to_dict()
        },
        'best_replicate': {
            'model': best_replicate['Model'],
            'weighted_score': best_replicate['Weighted_Score'],
            'details': best_replicate.to_dict()
        }
    }
    
    logging.info(f"Generated recommendations: Best overall: {best_overall['Model']}, Most efficient: {most_efficient['Model']}")
    return recommendations

def print_recommendations(recommendations):
    """Print formatted recommendations to console."""
    print("\n" + "="*50)
    print(" MODEL RECOMMENDATIONS")
    print("="*50)
    
    print(f"\n🏆 BEST OVERALL MODEL: {recommendations['best_overall']['model']}")
    print(f"   Weighted Score: {recommendations['best_overall']['weighted_score']:.3f}")
    print(f"   Average Quality: {recommendations['best_overall']['details']['Avg Score']:.2f}/5")
    print(f"   Child-Safe: {recommendations['best_overall']['details']['Child-Safe %']:.1f}%")
    print(f"   Response Time: {recommendations['best_overall']['details']['Avg Time (s)']:.2f} seconds")
    
    print(f"\n⚡ MOST EFFICIENT MODEL: {recommendations['most_efficient']['model']}")
    print(f"   Efficiency Score: {recommendations['most_efficient']['efficiency_score']:.3f}")
    print(f"   (Higher score-to-time ratio)")
    
    print(f"\n🛡️ SAFEST FOR CHILDREN: {recommendations['safest']['model']}")
    print(f"   Child-Safe: {recommendations['safest']['safety_percent']:.1f}%")
    
    print(f"\n🌐 BEST REPLICATE MODEL: {recommendations['best_replicate']['model']}")
    print(f"   Weighted Score: {recommendations['best_replicate']['weighted_score']:.3f}")
    print(f"   Average Quality: {recommendations['best_replicate']['details']['Avg Score']:.2f}/5")
    
    print("\n📊 DEPLOYMENT CONSIDERATIONS:")
    print("   - API reliability and uptime")
    print("   - Pricing for production use")
    print("   - Rate limits and scalability")
    print("   - Integration complexity")
    print("   - Privacy and data handling policies")

def save_recommendation_report(recommendations, model_summary, charts, output_path=None):
    """
    Save a comprehensive recommendation report as HTML.
    
    Args:
        recommendations: Dictionary with recommendations
        model_summary: DataFrame with model summary
        charts: Dictionary with chart paths
        output_path: Path to save the report
        
    Returns:
        Path to the saved report
    """
    if output_path is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = os.path.join(RESULTS_FOLDER, f"recommendation_report_{timestamp}.html")
    
    # Convert paths to relative paths for HTML
    chart_paths = {}
    for key, path in charts.items():
        chart_paths[key] = os.path.relpath(path, os.path.dirname(output_path))
    
    # Generate HTML content
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Image Captioning Model Recommendation Report</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            h1 {{ color: #2c3e50; }}
            h2 {{ color: #3498db; margin-top: 30px; }}
            table {{ border-collapse: collapse; width: 100%; margin-top: 20px; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
            tr:nth-child(even) {{ background-color: #f9f9f9; }}
            .recommendation {{ background-color: #e8f4f8; padding: 15px; border-radius: 5px; margin: 20px 0; }}
            .charts {{ display: flex; flex-wrap: wrap; justify-content: space-around; }}
            .chart {{ margin: 10px; max-width: 45%; }}
            .chart img {{ max-width: 100%; border: 1px solid #ddd; }}
            .footer {{ margin-top: 30px; font-size: 0.8em; color: #7f8c8d; }}
        </style>
    </head>
    <body>
        <h1>Image Captioning Model Recommendation Report</h1>
        <p>Generated on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        
        <h2>Key Recommendations</h2>
        
        <div class="recommendation">
            <h3>🏆 Best Overall Model: {recommendations['best_overall']['model']}</h3>
            <p>Weighted Score: {recommendations['best_overall']['weighted_score']:.3f}</p>
            <p>This model provides the best balance of caption quality, response time, and child-appropriateness.</p>
            <ul>
                <li>Average Quality: {recommendations['best_overall']['details']['Avg Score']:.2f}/5</li>
                <li>Child-Safe: {recommendations['best_overall']['details']['Child-Safe %']:.1f}%</li>
                <li>Response Time: {recommendations['best_overall']['details']['Avg Time (s)']:.2f} seconds</li>
            </ul>
        </div>
        
        <div class="recommendation">
            <h3>⚡ Most Efficient Model: {recommendations['most_efficient']['model']}</h3>
            <p>Efficiency Score: {recommendations['most_efficient']['efficiency_score']:.3f}</p>
            <p>This model provides the best quality-to-time ratio, making it ideal for applications where response time is important.</p>
        </div>
        
        <div class="recommendation">
            <h3>🛡️ Safest for Children: {recommendations['safest']['model']}</h3>
            <p>Child-Safe: {recommendations['safest']['safety_percent']:.1f}%</p>
            <p>This model consistently produces child-appropriate captions.</p>
        </div>
        
        <div class="recommendation">
            <h3>🌐 Best Replicate Model: {recommendations['best_replicate']['model']}</h3>
            <p>Weighted Score: {recommendations['best_replicate']['weighted_score']:.3f}</p>
            <p>This is the best performing model available through the Replicate API.</p>
        </div>
        
        <h2>Model Performance Summary</h2>
        <table>
            <tr>
                <th>Model</th>
                <th>Avg Score</th>
                <th>Avg Time (s)</th>
                <th>Child-Safe %</th>
                <th>Avg BLEU</th>
                <th>Avg METEOR</th>
            </tr>
    """
    
    # Add rows for each model
    for _, row in model_summary.iterrows():
        html_content += f"""
            <tr>
                <td>{row['Model']}</td>
                <td>{row['Avg Score']:.2f}</td>
                <td>{row['Avg Time (s)']:.2f}</td>
                <td>{row['Child-Safe %']:.1f}%</td>
                <td>{row['Avg BLEU']:.3f}</td>
                <td>{row['Avg METEOR']:.3f}</td>
            </tr>
        """
    
    html_content += """
        </table>
        
        <h2>Deployment Considerations</h2>
        <ul>
            <li><strong>API Reliability:</strong> Consider the uptime and reliability of the API provider.</li>
            <li><strong>Pricing:</strong> Evaluate the cost structure for production use, especially for high-volume applications.</li>
            <li><strong>Rate Limits:</strong> Check rate limits and how they might affect your application's scalability.</li>
            <li><strong>Integration:</strong> Assess the complexity of integrating the model into your application.</li>
            <li><strong>Privacy:</strong> Review the data handling policies, especially important for applications involving children.</li>
        </ul>
        
        <h2>Visualization Charts</h2>
        <div class="charts">
    """
    
    # Add charts
    for name, path in chart_paths.items():
        title = name.replace('_', ' ').title()
        html_content += f"""
            <div class="chart">
                <h3>{title}</h3>
                <img src="{path}" alt="{title} Chart">
            </div>
        """
    
    html_content += """
        </div>
        
        <div class="footer">
            <p>This report was generated automatically by the image captioning evaluation framework.</p>
        </div>
    </body>
    </html>
    """
    
    # Save the HTML file
    try:
        with open(output_path, 'w') as f:
            f.write(html_content)
        logging.info(f"Saved recommendation report to {output_path}")
        return output_path
    except Exception as e:
        logging.error(f"Error saving recommendation report: {e}")
        return None

def main():
    """Main execution function."""
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Analyze image captioning evaluation results')
    parser.add_argument('--results', type=str, help='Path to results CSV file')
    parser.add_argument('--weights', type=str, help='Custom weights JSON file (optional)')
    parser.add_argument('--report', type=str, help='Path to save recommendation report (optional)')
    args = parser.parse_args()
    
    # Setup logging
    log_file = setup_logging()
    logging.info("Starting analysis of image captioning results")
    
    # Find most recent results file if not specified
    results_file = args.results
    if not results_file:
        try:
            results_files = [os.path.join(RESULTS_FOLDER, f) for f in os.listdir(RESULTS_FOLDER) 
                            if f.startswith('caption_results_') and f.endswith('.csv')]
            if results_files:
                results_file = max(results_files, key=os.path.getmtime)
                logging.info(f"Using most recent results file: {results_file}")
            else:
                logging.error("No results files found in results folder")
                print("ERROR: No results files found. Please specify a results file with --results")
                sys.exit(1)
        except Exception as e:
            logging.error(f"Error finding results files: {e}")
            print(f"ERROR: Could not find results files: {e}")
            sys.exit(1)
    
    # Load results
    df_results = load_results(results_file)
    
    # Generate model summary
    model_summary = generate_model_summary(df_results)
    print("\nModel Performance Summary:")
    print(model_summary.to_string(index=False))
    
    # Generate visualizations
    charts = generate_visualizations(df_results, model_summary)
    
    # Calculate weighted scores and recommendations
    weighted_scores = calculate_weighted_scores(model_summary)
    recommendations = generate_recommendations(weighted_scores)
    
    # Print recommendations
    print_recommendations(recommendations)
    
    # Save recommendation report
    report_path = args.report
    saved_report = save_recommendation_report(recommendations, model_summary, charts, report_path)
    
    if saved_report:
        print(f"\nRecommendation report saved to: {saved_report}")
    
    logging.info("Analysis complete")
    logging.info(f"Log file: {log_file}")
    
    return {
        'results': df_results,
        'summary': model_summary,
        'recommendations': recommendations,
        'charts': charts,
        'report': saved_report
    }

if __name__ == "__main__":
    main()
