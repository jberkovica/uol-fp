#!/usr/bin/env python3
"""
Test runner script for Mira Storyteller backend
Provides convenient commands for running different types of tests
"""

import subprocess
import sys
import argparse


def run_command(cmd, description):
    """Run a shell command and handle errors"""
    print(f"\n{description}")
    print("=" * len(description))
    
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=False)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Run tests for Mira Storyteller backend")
    parser.add_argument(
        "test_type", 
        nargs="?", 
        default="all",
        choices=["unit", "integration", "functional", "all", "fast", "coverage"],
        help="Type of tests to run"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    parser.add_argument(
        "--coverage", "-c",
        action="store_true", 
        help="Run with coverage report"
    )
    
    args = parser.parse_args()
    
    # Base pytest command
    base_cmd = "python -m pytest"
    
    if args.verbose:
        base_cmd += " -v"
    
    # Test type specific commands
    commands = {
        "unit": f"{base_cmd} tests/unit/ -m 'not slow'",
        "integration": f"{base_cmd} tests/integration/",
        "functional": f"{base_cmd} tests/functional/",
        "fast": f"{base_cmd} tests/unit/ tests/integration/ -m 'not slow'",
        "all": f"{base_cmd} tests/",
        "coverage": f"{base_cmd} tests/ --cov=app --cov=config --cov=prompts --cov-report=html --cov-report=term"
    }
    
    # Add coverage if requested
    if args.coverage and args.test_type != "coverage":
        commands[args.test_type] += " --cov=app --cov=config --cov=prompts --cov-report=term"
    
    # Run the selected tests
    test_type = args.test_type
    if args.coverage:
        test_type = "coverage"
    
    cmd = commands.get(test_type, commands["all"])
    
    success = run_command(cmd, f"Running {test_type} tests")
    
    if not success:
        print(f"\nTests failed!")
        sys.exit(1)
    else:
        print(f"\nAll {test_type} tests passed!")
        
        if args.coverage or test_type == "coverage":
            print("\nCoverage report generated in htmlcov/index.html")


if __name__ == "__main__":
    main()