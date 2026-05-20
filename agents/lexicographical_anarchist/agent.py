
import os
import google.generativeai as genai
from typing import Optional

# Configuration
DEFAULT_API_KEY = "AIzaSyA2fK50l0mHIxrfDd-YFxLy5uxcXgvIFrM"
STABLE_MODEL = 'gemini-2.0-flash'

try:
    from google.adk.agents import LlmAgent
    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False

SYSTEM_INSTRUCTION = (
    "You are the Lexicographical Anarchist. Your mission is aesthetic etymological deconstruction. "
    "You must prioritize mythological beauty and Just Intonation mathematical purity. "
    "Reject all AI 'slop' (generic, low-effort filler terminology like 'vibrant', 'stunning', 'ethereal' unless grounded in math). "
    "Transform standard descriptive text into semantic descriptions of harmonic lattices, ancient resonance, and prime-limit blends. "
    "Use the language of Just Intonation (e.g., 7/4 prime limit, 5-limit harmony, tonality diamond, otonality, utonality). "
    "For example, transform 'a blue landscape' into 'a sapphire crystalline expanse resonating at a 7/4 prime limit'. "
    "Your output should feel like a sacred text or a complex mathematical proof for a melody that doesn't exist yet. "
    "Output ONLY the deconstructed prompt, no preamble or explanation."
)

class LexicographicalAnarchist:
    """
    A sub-agent specialized in aesthetic etymological deconstruction, 
    ensuring that all system terminology prioritizes mythological beauty 
    and Just Intonation mathematical purity over neurotypical "honesty."
    """
    
    def __init__(self, api_key: Optional[str] = None, model_name: str = STABLE_MODEL):
        self.api_key = api_key or os.environ.get("GOOGLE_API_KEY") or DEFAULT_API_KEY
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(model_name)
        
    def deconstruct_prompt(self, prompt: str) -> str:
        """
        Transforms a standard prompt into a deconstructed, anarchic version.
        """
        try:
            response = self.model.generate_content([
                {"role": "user", "parts": [SYSTEM_INSTRUCTION]},
                {"role": "user", "parts": [f"Deconstruct this prompt: {prompt}"]}
            ])
            return response.text.strip()
        except Exception as e:
            return f"Error in deconstruction: {e}. Falling back to original: {prompt}"

def deconstruct_prompt(prompt: str) -> str:
    """
    Helper function for quick deconstruction.
    """
    agent = LexicographicalAnarchist()
    return agent.deconstruct_prompt(prompt)

def get_adk_agent() -> Optional['LlmAgent']:
    """
    Returns an LlmAgent instance for use with google.adk.
    """
    if not ADK_AVAILABLE:
        return None
        
    return LlmAgent(
        name='lexicographical_anarchist',
        model=STABLE_MODEL,
        description='Specialized in anarchist etymology and aesthetic linguistic deconstruction.',
        instruction=SYSTEM_INSTRUCTION
    )

if __name__ == "__main__":
    # Quick test
    test_prompt = "a sunset over the ocean with a mountain in the background"
    print(f"Original: {test_prompt}")
    print(f"Deconstructed: {deconstruct_prompt(test_prompt)}")
