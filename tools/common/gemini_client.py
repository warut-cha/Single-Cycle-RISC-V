import os
from google import genai

def load_prompt(path):
    from pathlib import Path
    path = Path(path)
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def load_prompt_template(path):
    return load_prompt(path)

def gemini_run(prompt, fallback_text):
    return run_gemini(prompt, fallback_text)

def run_gemini(prompt, fallback_text):
    """
    Run Gemini via the new official Python SDK (google.genai).
    """
    if os.getenv("DISABLE_GEMINI", "0") == "1":
        return fallback_text

    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return (
            fallback_text
            + "\n\n---\n"
            + "GOOGLE_API_KEY was not found, so this report used the local rule-based fallback.\n"
        )

    try:
        # Initialize the new Client object
        client = genai.Client(api_key=api_key)
        
        # Generate the content using the modern syntax
        response = client.models.generate_content(
            model='gemini-flash-latest',
            contents=prompt
        )
        
        # Check if the response is empty (safety block or empty generation)
        if not response.text:
            return (
                fallback_text
                + "\n\n---\n"
                + "Gemini execution failed: Response was empty or blocked by safety filters.\n"
            )

        return response.text.strip()

    except Exception as exc:
        return (
            fallback_text
            + "\n\n---\n"
            + f"Gemini execution failed with exception: `{exc}`.\n"
        )