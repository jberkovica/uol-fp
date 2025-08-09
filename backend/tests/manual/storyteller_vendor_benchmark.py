"""
Manual Storyteller Vendor Benchmark Tool

This is NOT an automated unit test - it's a manual testing tool for evaluating
and comparing different AI vendors for story generation.

Usage:
    python tests/manual/storyteller_vendor_benchmark.py [options]
    
Options:
    --vendor VENDOR     Test specific vendor (mistral, openai, google, anthropic)
    --model MODEL       Override default model for vendor
    --all              Test all configured vendors
    --quick            Run quick test (1 story per vendor)
    --detailed         Run detailed test (3 stories per vendor)
    
Examples:
    python tests/manual/storyteller_vendor_benchmark.py --all
    python tests/manual/storyteller_vendor_benchmark.py --vendor openai --model gpt-3.5-turbo
    python tests/manual/storyteller_vendor_benchmark.py --detailed
"""

import asyncio
import argparse
import time
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

# Add backend src to path
backend_path = Path(__file__).parent.parent.parent
sys.path.insert(0, str(backend_path))

from dotenv import load_dotenv
from src.agents.storyteller.agent import create_storyteller_agent
from src.types.story_models import StoryGenerationContext

load_dotenv()


class StorytellerBenchmark:
    """Benchmark tool for comparing storyteller vendors."""
    
    # Default vendor configurations
    VENDOR_CONFIGS = {
        "mistral": {
            "vendor": "mistral",
            "model": "mistral-medium-latest",
            "api_key_env": "MISTRAL_API_KEY",
            "max_tokens": 300,
            "temperature": 0.7
        },
        "gpt-4o-mini": {
            "vendor": "openai",
            "model": "gpt-4o-mini",
            "api_key_env": "OPENAI_API_KEY",
            "max_tokens": 300,
            "temperature": 0.7
        },
        "gpt-3.5-turbo": {
            "vendor": "openai", 
            "model": "gpt-3.5-turbo",
            "api_key_env": "OPENAI_API_KEY",
            "max_tokens": 300,
            "temperature": 0.7
        },
        "google": {
            "vendor": "google",
            "model": "gemini-2.0-flash-exp",
            "api_key_env": "GOOGLE_API_KEY",
            "max_tokens": 300,
            "temperature": 0.7
        },
        "anthropic": {
            "vendor": "anthropic",
            "model": "claude-3-haiku-20240307",
            "api_key_env": "ANTHROPIC_API_KEY",
            "max_tokens": 300,
            "temperature": 0.7
        }
    }
    
    # Test scenarios for variety
    TEST_SCENARIOS = [
        {
            "description": "Friendly dragon with balloons",
            "kid_name": "Emma",
            "age": 5,
            "genres": ["fantasy", "adventure"]
        },
        {
            "description": "A magical garden where flowers can talk",
            "kid_name": "Alex",
            "age": 7,
            "genres": ["magic", "nature"]
        },
        {
            "description": "A brave little robot exploring space",
            "kid_name": "Sofia",
            "age": 6,
            "genres": ["science fiction", "adventure"]
        }
    ]
    
    def __init__(self, verbose: bool = True):
        self.verbose = verbose
        self.results = []
        
    async def test_vendor(self, vendor_key: str, config: Dict, scenarios: List[Dict]) -> Dict:
        """Test a specific vendor with given scenarios."""
        print(f"\nTESTING: {vendor_key.upper()}")
        print("-" * 50)
        
        # Check API key
        api_key = os.getenv(config["api_key_env"])
        if not api_key:
            print(f"SKIPPED: {config['api_key_env']} not found in environment")
            return None
        
        config["api_key"] = api_key
        
        try:
            agent = create_storyteller_agent(config)
        except Exception as e:
            print(f"ERROR: Failed to create agent: {e}")
            return None
        
        vendor_results = {
            "vendor": vendor_key,
            "model": config["model"],
            "scenarios": [],
            "total_time": 0,
            "avg_time": 0,
            "avg_word_count": 0,
            "json_success_rate": 0,
            "quality_metrics": {}
        }
        
        for i, scenario in enumerate(scenarios, 1):
            print(f"\n  Scenario {i}/{len(scenarios)}: {scenario['description'][:40]}...")
            
            context = StoryGenerationContext(
                image_description=scenario["description"],
                kid_name=scenario["kid_name"],
                age=scenario["age"],
                language="en",
                word_count="150-200",
                genres=scenario.get("genres", [])
            )
            
            start_time = time.time()
            
            try:
                # Generate story
                unified_prompt = agent._build_unified_prompt(context)
                system_prompt = "You are a creative children's storyteller. Generate engaging, family-friendly stories."
                
                client = agent.get_vendor_client()
                raw_response = await agent._generate_with_vendor(client, system_prompt, unified_prompt)
                
                end_time = time.time()
                processing_time = end_time - start_time
                
                # Try to parse as JSON
                json_success = False
                try:
                    parsed_response = agent._parse_json_response(raw_response)
                    json_success = raw_response.strip().startswith('{')
                    
                    # Analyze quality
                    word_count = len(parsed_response.content.split())
                    has_kid_name = scenario["kid_name"] in parsed_response.content
                    
                    scenario_result = {
                        "success": True,
                        "time": round(processing_time, 2),
                        "title": parsed_response.title,
                        "content": parsed_response.content,  # Save full story
                        "word_count": word_count,
                        "has_kid_name": has_kid_name,
                        "json_format": json_success,
                        "raw_response": raw_response  # Save raw response too
                    }
                    
                    if self.verbose:
                        print(f"    SUCCESS in {processing_time:.2f}s")
                        print(f"    Title: {parsed_response.title}")
                        print(f"    Words: {word_count}, Has name: {has_kid_name}, JSON: {json_success}")
                    
                except Exception as parse_error:
                    scenario_result = {
                        "success": False,
                        "time": round(processing_time, 2),
                        "error": str(parse_error)
                    }
                    if self.verbose:
                        print(f"    FAILED: {parse_error}")
                
                vendor_results["scenarios"].append(scenario_result)
                
            except Exception as e:
                print(f"    ERROR: {e}")
                vendor_results["scenarios"].append({
                    "success": False,
                    "error": str(e)
                })
        
        # Calculate aggregate metrics
        successful_scenarios = [s for s in vendor_results["scenarios"] if s.get("success")]
        
        if successful_scenarios:
            vendor_results["total_time"] = sum(s["time"] for s in successful_scenarios)
            vendor_results["avg_time"] = round(vendor_results["total_time"] / len(successful_scenarios), 2)
            vendor_results["avg_word_count"] = round(
                sum(s["word_count"] for s in successful_scenarios) / len(successful_scenarios)
            )
            vendor_results["json_success_rate"] = round(
                sum(1 for s in successful_scenarios if s.get("json_format", False)) / len(successful_scenarios) * 100
            )
            vendor_results["success_rate"] = round(len(successful_scenarios) / len(scenarios) * 100)
            
            # Quality score (0-100)
            quality_score = 0
            quality_score += min(vendor_results["avg_word_count"] / 2, 50)  # Word count (target 150-200)
            quality_score += vendor_results["json_success_rate"] / 4  # JSON compliance (25%)
            quality_score += sum(1 for s in successful_scenarios if s.get("has_kid_name")) / len(successful_scenarios) * 25
            
            vendor_results["quality_score"] = round(quality_score)
        
        return vendor_results
    
    async def run_benchmark(self, vendors: List[str] = None, scenarios_count: int = 1):
        """Run benchmark for specified vendors."""
        print("\nSTORYTELLER VENDOR BENCHMARK")
        print("=" * 60)
        print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Scenarios per vendor: {scenarios_count}")
        
        # Select vendors to test
        if vendors:
            vendors_to_test = {k: v for k, v in self.VENDOR_CONFIGS.items() 
                             if any(k.startswith(v) for v in vendors)}
        else:
            vendors_to_test = self.VENDOR_CONFIGS
        
        # Select scenarios
        scenarios = self.TEST_SCENARIOS[:scenarios_count]
        
        # Test each vendor
        results = []
        for vendor_key, config in vendors_to_test.items():
            result = await self.test_vendor(vendor_key, config, scenarios)
            if result:
                results.append(result)
        
        # Print summary
        self.print_summary(results)
        
        return results
    
    def print_summary(self, results: List[Dict]):
        """Print benchmark summary."""
        if not results:
            print("\nNo successful test results to summarize.")
            return
        
        print("\n" + "=" * 60)
        print("BENCHMARK SUMMARY")
        print("=" * 60)
        
        # Sort by average time
        results_by_speed = sorted(results, key=lambda x: x.get("avg_time", float('inf')))
        
        print("\nSPEED RANKING:")
        for i, result in enumerate(results_by_speed, 1):
            print(f"  {i}. {result['vendor'].upper()} ({result['model']}): {result['avg_time']}s avg")
        
        # Sort by quality score
        results_by_quality = sorted(results, key=lambda x: x.get("quality_score", 0), reverse=True)
        
        print("\nQUALITY RANKING:")
        for i, result in enumerate(results_by_quality, 1):
            print(f"  {i}. {result['vendor'].upper()}: {result['quality_score']}/100")
            print(f"     - Avg words: {result['avg_word_count']}")
            print(f"     - JSON compliance: {result['json_success_rate']}%")
            print(f"     - Success rate: {result['success_rate']}%")
        
        print("\nDETAILED METRICS:")
        print(f"{'Vendor':<15} {'Model':<20} {'Avg Time':<10} {'Words':<8} {'JSON':<8} {'Quality':<8}")
        print("-" * 80)
        
        for result in results_by_speed:
            print(f"{result['vendor']:<15} {result['model']:<20} "
                  f"{result['avg_time']:<10.2f} {result['avg_word_count']:<8} "
                  f"{result['json_success_rate']:<8.0f}% {result['quality_score']:<8}/100")
        
        # Best overall recommendation
        print("\nRECOMMENDATIONS:")
        
        fastest = results_by_speed[0]
        print(f"  Fastest: {fastest['vendor'].upper()} ({fastest['model']}) - {fastest['avg_time']}s")
        
        best_quality = results_by_quality[0]
        print(f"  Best Quality: {best_quality['vendor'].upper()} ({best_quality['model']}) - {best_quality['quality_score']}/100")
        
        # Best value (balance of speed and quality)
        results_by_value = sorted(results, 
                                 key=lambda x: x.get("quality_score", 0) / (x.get("avg_time", 1) + 1), 
                                 reverse=True)
        best_value = results_by_value[0]
        print(f"  Best Value: {best_value['vendor'].upper()} ({best_value['model']}) - "
              f"{best_value['avg_time']}s @ {best_value['quality_score']}/100 quality")


async def main():
    """Main entry point for the benchmark tool."""
    parser = argparse.ArgumentParser(description="Storyteller Vendor Benchmark Tool")
    parser.add_argument("--vendor", type=str, help="Test specific vendor")
    parser.add_argument("--model", type=str, help="Override model for vendor")
    parser.add_argument("--all", action="store_true", help="Test all vendors")
    parser.add_argument("--quick", action="store_true", help="Quick test (1 scenario)")
    parser.add_argument("--detailed", action="store_true", help="Detailed test (3 scenarios)")
    parser.add_argument("--quiet", action="store_true", help="Less verbose output")
    
    args = parser.parse_args()
    
    # Determine scenarios count
    if args.detailed:
        scenarios_count = 3
    else:
        scenarios_count = 1  # Default or quick mode
    
    # Determine vendors to test
    if args.all:
        vendors = None  # Test all
    elif args.vendor:
        vendors = [args.vendor]
    else:
        # Default: test quality-focused vendors
        vendors = ["mistral", "gpt-4o-mini", "google"]
    
    # Override model if specified
    if args.model and args.vendor:
        benchmark = StorytellerBenchmark(verbose=not args.quiet)
        if args.vendor in benchmark.VENDOR_CONFIGS:
            benchmark.VENDOR_CONFIGS[args.vendor]["model"] = args.model
    
    # Run benchmark
    benchmark = StorytellerBenchmark(verbose=not args.quiet)
    results = await benchmark.run_benchmark(vendors, scenarios_count)
    
    # Save results to file with full stories
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_file = Path(__file__).parent / f"benchmark_results_{timestamp}.txt"
    stories_file = Path(__file__).parent / f"benchmark_stories_{timestamp}.txt"
    
    # Save metrics summary
    with open(results_file, "w") as f:
        f.write(f"Storyteller Vendor Benchmark Results\n")
        f.write(f"Date: {datetime.now()}\n")
        f.write(f"Scenarios: {scenarios_count}\n\n")
        
        for result in results:
            f.write(f"\n{result['vendor']} ({result['model']}):\n")
            f.write(f"  Avg Time: {result.get('avg_time', 'N/A')}s\n")
            f.write(f"  Quality Score: {result.get('quality_score', 'N/A')}/100\n")
            f.write(f"  Avg Words: {result.get('avg_word_count', 'N/A')}\n")
            f.write(f"  JSON Compliance: {result.get('json_success_rate', 'N/A')}%\n")
    
    # Save full stories for reading
    with open(stories_file, "w") as f:
        f.write("GENERATED STORIES FOR REVIEW\n")
        f.write("=" * 80 + "\n")
        f.write(f"Date: {datetime.now()}\n")
        f.write(f"Test scenarios: {scenarios_count}\n\n")
        
        for result in results:
            f.write("\n" + "=" * 80 + "\n")
            f.write(f"VENDOR: {result['vendor'].upper()} ({result['model']})\n")
            f.write("=" * 80 + "\n\n")
            
            for i, scenario in enumerate(result.get('scenarios', []), 1):
                if scenario.get('success'):
                    f.write(f"Story {i}:\n")
                    f.write("-" * 40 + "\n")
                    f.write(f"Title: {scenario.get('title', 'N/A')}\n")
                    f.write(f"Processing Time: {scenario.get('time', 'N/A')}s\n")
                    f.write(f"Word Count: {scenario.get('word_count', 'N/A')}\n")
                    f.write(f"Has Kid Name: {scenario.get('has_kid_name', False)}\n")
                    f.write(f"JSON Format: {scenario.get('json_format', False)}\n")
                    f.write("\nSTORY CONTENT:\n")
                    f.write("-" * 40 + "\n")
                    f.write(scenario.get('content', 'No content available'))
                    f.write("\n\n")
                else:
                    f.write(f"Story {i}: FAILED - {scenario.get('error', 'Unknown error')}\n\n")
    
    print(f"\nResults saved to: {results_file}")
    print(f"Full stories saved to: {stories_file}")


if __name__ == "__main__":
    asyncio.run(main())