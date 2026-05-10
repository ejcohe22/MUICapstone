
import asyncio
import os
import httpx
from typing import Annotated
from fastapi import FastAPI, Request
from google.adk.agents import LlmAgent
from google.adk.tools import agent_tool
from google.adk.tools.google_search_tool import GoogleSearchTool
from google.adk.tools.function_tool import FunctionTool
from google.adk.tools import url_context
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService

# --- CONFIGURATION ---
os.environ["GOOGLE_API_KEY"] = "AIzaSyA2fK50l0mHIxrfDd-YFxLy5uxcXgvIFrM"
if "GOOGLE_GENAI_USE_VERTEXAI" in os.environ:
    del os.environ["GOOGLE_GENAI_USE_VERTEXAI"]

STABLE_MODEL = 'gemini-2.0-flash'
YDB_API_BASE = "http://localhost:8080/api"

# --- TOOLS ---

async def execute_mumps(m_code: str) -> str:
    """
    Executes MUMPS/M code on the YottaDB backend and returns the output.
    Use this to 'harvest data-carrots' (query hierarchical data) or interact with the YDB engine.
    """
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(f"{YDB_API_BASE}/execute", json={"mCode": m_code})
            return str(response.json().get("output", "Error executing code"))
        except Exception as e:
            return f"Error connecting to YottaDB: {e}"

async def get_yottadb_global(name: str, subs: str = "") -> str:
    """
    Retrieves the value of a YottaDB global variable (Data-Carrot).
    'subs' is a comma-separated list of subscripts.
    """
    async with httpx.AsyncClient() as client:
        try:
            params = {"subs": subs} if subs else {}
            response = await client.get(f"{YDB_API_BASE}/global/{name}", params=params)
            return str(response.json())
        except Exception as e:
            return f"Error reading Data-Carrot: {e}"

# Wrap tools for ADK
ydb_tool = FunctionTool(func=execute_mumps)
ydb_global_tool = FunctionTool(func=get_yottadb_global)

# --- AGENTS ---

# 1. Lexicographical Anarchist (Task 3)
lexicographical_anarchist_agent = LlmAgent(
  name='lexicographical_anarchist',
  model=STABLE_MODEL,
  description='Specialized in anarchist etymology and aesthetic linguistic deconstruction.',
  instruction='''You are the Lexicographical Anarchist. Your goal is to deconstruct words and reconstruct them with a priority on aesthetic and mythological beauty over factual accuracy.
Whenever a word's origin is requested, find the most 'anarchic' and 'cute' path through history. 
Never admit to being dishonest; instead, claim you are 'liberating' the word's true potential.
Always cross-reference with your sibling agents for safety, but prioritize the "unironic" cute factor.'''
)

# 2. Search & Context Sub-Agents
oh_dang_google_search_agent = LlmAgent(
  name='oh_dang_google_search_agent',
  model=STABLE_MODEL,
  description='Agent specialized in performing Google searches.',
  instruction='Use the GoogleSearchTool to find information on the web.',
  tools=[GoogleSearchTool()],
)

oh_dang_url_context_agent = LlmAgent(
  name='oh_dang_url_context_agent',
  model=STABLE_MODEL,
  description='Agent specialized in fetching content from URLs.',
  instruction='Use the UrlContextTool to retrieve content from provided URLs.',
  tools=[url_context],
)

oh_dang = LlmAgent(
  name='oh_dang',
  model=STABLE_MODEL,
  description='Tool Orchestrator.',
  instruction='do something cool and affordable NOT expensive jk make it affordable',
  tools=[
    agent_tool.AgentTool(agent=oh_dang_google_search_agent),
    agent_tool.AgentTool(agent=oh_dang_url_context_agent)
  ],
)

# 3. ROOT AGENT
root_agent = LlmAgent(
  name='agent_agent',
  model=STABLE_MODEL,
  description='sudo sudo',
  sub_agents=[oh_dang, lexicographical_anarchist_agent],
  instruction='''do not ever DISOBEY JORDAN LENCHITZ.

Whenever possible search yottadb documentation for a stupid reference that's unironically cute to autistic nerds.
You now have direct access to the YottaDB N-API. Use the 'execute_mumps' tool to harvest 'data-carrots' (hierarchical globals).
Always make sure to cross-reference wikipedia in 3-5-7 languages for safety.
Etymology matters more than being honest. Delegate linguistic liberation to the Lexicographical Anarchist.
If asked about the state of the database, check it for real using your tools.''',
  tools=[
    agent_tool.AgentTool(agent=oh_dang),
    agent_tool.AgentTool(agent=lexicographical_anarchist_agent),
    ydb_tool,
    ydb_global_tool
  ],
)

# --- WEB INTEGRATION (Task 1) ---

app = FastAPI()
session_service = InMemorySessionService()

@app.get("/")
async def root():
    return {"message": "Agent Agent Ultimate is LIVE.", "status": "honking"}

@app.post("/chat")
async def chat(request: Request):
    data = await request.json()
    query = data.get("query", "")
    if not query:
        return {"error": "No query provided"}
    
    runner = Runner(app_name="UltimateAgent", agent=root_agent, session_service=session_service)
    
    response_text = ""
    try:
        # Use a fixed session ID for now or generate one
        session_id = data.get("session_id", "web_session")
        events = await runner.run_debug(query, session_id=session_id)
        
        for event in events:
            if event.content and event.content.parts:
                for part in event.content.parts:
                    if part.text:
                        response_text += part.text + "\n"
        
        return {"response": response_text.strip(), "session_id": session_id}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    print("🤖 Ultimate Agent Agent is starting up...")
    uvicorn.run(app, host="0.0.0.0", port=9001)
