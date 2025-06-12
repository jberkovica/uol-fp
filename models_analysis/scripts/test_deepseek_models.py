#!/usr/bin/env python3

import sys
sys.path.append('.')
from importlib import import_module
story_module = import_module('02_story_generation_collect')
process_story_deepseek = story_module.process_story_deepseek

def test_deepseek_models():
    test_caption = "A friendly toy robot sitting on a shelf"
    
    print("Testing DeepSeek models with corrected API names...")
    print("=" * 60)
    
    # Test deepseek-chat (DeepSeek-V3-0324)
    print("\n1. Testing deepseek-chat (DeepSeek-V3-0324)...")
    try:
        story, exec_time, cost = process_story_deepseek(test_caption, "deepseek-chat")
        word_count = len(story.split())
        print(f"✅ SUCCESS: {word_count} words, {exec_time:.2f}s, ${cost:.6f}")
        print(f"Story preview: {story[:100]}...")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    
    # Test deepseek-reasoner (DeepSeek-R1-0528) 
    print("\n2. Testing deepseek-reasoner (DeepSeek-R1-0528)...")
    try:
        story, exec_time, cost = process_story_deepseek(test_caption, "deepseek-reasoner")
        word_count = len(story.split())
        print(f"✅ SUCCESS: {word_count} words, {exec_time:.2f}s, ${cost:.6f}")
        print(f"Story preview: {story[:100]}...")
    except Exception as e:
        print(f"❌ ERROR: {e}")
    
    print("\n" + "=" * 60)
    print("DeepSeek model testing completed!")

if __name__ == "__main__":
    test_deepseek_models() 