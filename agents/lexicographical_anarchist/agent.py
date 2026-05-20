
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
        
    def deconstruct_prompt(self, prompt: str, vibe: float = 0.5, tuning: Optional[str] = None, audio_duration: float = 2.0) -> str:
        """
        Transforms a standard prompt into a deconstructed, anarchic version.
        Intensity/Entropy is driven by the 'vibe' parameter (0.0 to 1.0).
        'The Oasis' Silence Mode returns an empty string if audio_duration < 1.7.
        """
        if audio_duration < 1.7:
            return "" # The Oasis: Silence Mode

        try:
            # Adjust instruction based on vibe (audio flux intensity)
            vibe_shift = f"\n\nCurrent Vibe Intensity: {vibe:.2f}. "
            if vibe > 0.8:
                vibe_shift += "EXTREME ENTROPY. Shatter the semantics. Prioritize raw ratios and mythological noise."
            elif vibe < 0.3:
                vibe_shift += "CALM RESONANCE. Maintain subtle semantic links. Focus on stable 3-limit or 5-limit structures."
            else:
                vibe_shift += "BALANCED ANARCHY. Standard Just Intonation deconstruction."

            # Task 1: Tuning Modes
            tuning_shift = ""
            if tuning == "septimal_blues":
                tuning_shift = (
                    "\n\nMODE: SEPTIMAL BLUES. Inject soulful, melancholic, 'deep-blue' descriptors. "
                    "Prioritize the 7th harmonic (7/4, 7/6) as a source of existential yearning. "
                    "The deconstruction should feel like a 'blue' note—slightly flat, heavy with emotion, "
                    "and mathematically 'impure' yet spiritually profound."
                )
            elif tuning == "traditional_17":
                tuning_shift = (
                    "\n\nMODE: PROPHETIC (TRADITIONAL 17). Invoke the desert, the ancient sands, and the 17-limit intervals. "
                    "Use ratios like 15/14 (septimal major semitone), 17/14, and 17/10. "
                    "The language should be prophetic, apocalyptic, and deeply rooted in Middle Eastern harmonic traditions. "
                    "Speak of the 'Oasis of 17 Ratios' and the 'Sand-worn Prophecy'."
                )

            response = self.model.generate_content([
                {"role": "user", "parts": [SYSTEM_INSTRUCTION + vibe_shift + tuning_shift]},
                {"role": "user", "parts": [f"Deconstruct this prompt: {prompt}"]}
            ])
            return response.text.strip()
        except Exception as e:
            return f"Error in deconstruction: {e}. Falling back to original: {prompt}"

def deconstruct_prompt(prompt: str, vibe: float = 0.5, tuning: Optional[str] = None, audio_duration: float = 2.0) -> str:
    """
    Helper function for quick deconstruction.
    """
    agent = LexicographicalAnarchist()
    return agent.deconstruct_prompt(prompt, vibe, tuning, audio_duration)

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
