"""
Evaluation metrics and functions for image caption quality assessment.
"""
import logging
import numpy as np
from nltk.translate.bleu_score import sentence_bleu
from nltk.translate.meteor_score import single_meteor_score
import nltk

# Download required NLTK data (uncomment if needed)
# nltk.download('wordnet')
# nltk.download('punkt')

logger = logging.getLogger(__name__)

def evaluate_caption_similarity(expected, generated):
    """
    Simple evaluation of caption similarity.
    Returns a score between 0-5 where:
    5: Exact match or very close
    4: Contains all key elements
    3: Contains some key elements
    2: Vaguely related
    1: Completely different
    0: Error or empty
    """
    if not expected or not generated:
        return 0
    if isinstance(generated, str) and "ERROR" in generated:
        return 0

    # Convert to lowercase for comparison
    expected_lower = expected.lower()
    generated_lower = generated.lower()

    # Split into words for overlap calculation
    expected_words = set(expected_lower.split())
    generated_words = set(generated_lower.split())

    # Calculate word overlap
    if len(expected_words) == 0:
        return 0

    overlap = len(expected_words.intersection(generated_words)) / len(expected_words)

    # Convert to 0-5 scale
    if overlap > 0.8:
        return 5
    elif overlap > 0.6:
        return 4
    elif overlap > 0.4:
        return 3
    elif overlap > 0.2:
        return 2
    else:
        return 1

def evaluate_child_appropriateness(caption):
    """
    Evaluate if the caption is appropriate for children.
    This is a basic implementation - in a real scenario,
    you would use a more sophisticated content filter.
    """
    if not caption or not isinstance(caption, str):
        return False
        
    if "ERROR" in caption:
        return False

    # List of potentially inappropriate words or themes
    inappropriate_words = [
        "violent", "scary", "weapon", "gun", "knife", "death", "kill",
        "blood", "horror", "mature", "adult", "explicit", "inappropriate",
        "violence", "disturbing", "fear", "terror", "frightening"
    ]

    caption_lower = caption.lower()
    for word in inappropriate_words:
        if word in caption_lower:
            return False

    return True

def calculate_bleu_score(reference, hypothesis):
    """
    Calculate BLEU score between reference and hypothesis captions.
    BLEU measures precision of n-grams.
    
    Args:
        reference: The ground truth caption
        hypothesis: The generated caption to evaluate
        
    Returns:
        BLEU score (0-1)
    """
    if not reference or not hypothesis:
        return 0
    if isinstance(hypothesis, str) and "ERROR" in hypothesis:
        return 0
        
    try:
        # Tokenize sentences
        reference_tokens = nltk.word_tokenize(reference.lower())
        hypothesis_tokens = nltk.word_tokenize(hypothesis.lower())
        
        # Calculate BLEU score with weights emphasizing shorter n-grams
        # which are more important for semantic similarity in short captions
        weights = (0.5, 0.3, 0.2, 0)  # Weights for 1, 2, 3, 4-grams
        return sentence_bleu([reference_tokens], hypothesis_tokens, weights=weights)
    except Exception as e:
        logger.error(f"Error calculating BLEU score: {e}")
        return 0

def calculate_meteor_score(reference, hypothesis):
    """
    Calculate METEOR score between reference and hypothesis captions.
    METEOR considers synonyms and is often better for short texts.
    
    Args:
        reference: The ground truth caption
        hypothesis: The generated caption to evaluate
        
    Returns:
        METEOR score (0-1)
    """
    if not reference or not hypothesis:
        return 0
    if isinstance(hypothesis, str) and "ERROR" in hypothesis:
        return 0
        
    try:
        # Convert to lowercase for better matching
        reference_lower = reference.lower()
        hypothesis_lower = hypothesis.lower()
        
        # Calculate METEOR score
        return single_meteor_score(reference_lower, hypothesis_lower)
    except Exception as e:
        logger.error(f"Error calculating METEOR score: {e}")
        return 0

def calculate_combined_score(expected, generated, weights=None):
    """
    Calculate a combined score using multiple metrics.
    
    Args:
        expected: The ground truth caption
        generated: The generated caption to evaluate
        weights: Dictionary of weights for each metric
        
    Returns:
        Combined score (0-5)
    """
    if not weights:
        weights = {
            'overlap': 0.5,
            'bleu': 0.25,
            'meteor': 0.25
        }
        
    overlap_score = evaluate_caption_similarity(expected, generated)
    bleu = calculate_bleu_score(expected, generated)
    meteor = calculate_meteor_score(expected, generated)
    
    # Scale BLEU and METEOR to 0-5 range
    bleu_scaled = bleu * 5
    meteor_scaled = meteor * 5
    
    # Calculate weighted average
    combined = (
        weights['overlap'] * overlap_score + 
        weights['bleu'] * bleu_scaled + 
        weights['meteor'] * meteor_scaled
    )
    
    return combined
