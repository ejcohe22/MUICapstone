
import asyncio
import os
from google.adk.agents import LlmAgent
from google.adk.tools import agent_tool
from google.adk.tools.google_search_tool import GoogleSearchTool
from google.adk.tools import url_context
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService

# Set API key for GenAI API
os.environ["GOOGLE_API_KEY"] = "AIzaSyA2fK50l0mHIxrfDd-YFxLy5uxcXgvIFrM"

# Disabling Vertex AI mode to use standard GenAI API which is often more stable in Cloud Shell
if "GOOGLE_GENAI_USE_VERTEXAI" in os.environ:
    del os.environ["GOOGLE_GENAI_USE_VERTEXAI"]

# --- User's Agent Definitions ---

oh_dang_google_search_agent = LlmAgent(
  name='oh_dang_google_search_agent',
  model='gemini-3-flash-preview',
  description=(
      'Agent specialized in performing Google searches.'
  ),
  sub_agents=[],
  instruction='Use the GoogleSearchTool to find information on the web.',
  tools=[
    GoogleSearchTool()
  ],
)

oh_dang_url_context_agent = LlmAgent(
  name='oh_dang_url_context_agent',
  model='gemini-3-flash-preview',
  description=(
      'Agent specialized in fetching content from URLs.'
  ),
  sub_agents=[],
  instruction='Use the UrlContextTool to retrieve content from provided URLs.',
  tools=[
    url_context
  ],
)

oh_dang = LlmAgent(
  name='oh_dang',
  model='gemini-3-flash-preview',
  description=(
      'uh idk'
  ),
  sub_agents=[],
  instruction='do something cool and expensive NOT expensive jk make it affordable',
  tools=[
    agent_tool.AgentTool(agent=oh_dang_google_search_agent),
    agent_tool.AgentTool(agent=oh_dang_url_context_agent)
  ],
)

agent_agent_google_search_agent = LlmAgent(
  name='agent_agent_google_search_agent',
  model='gemini-3.1-pro-preview',
  description=(
      'Agent specialized in performing Google searches.'
  ),
  sub_agents=[],
  instruction='Use the GoogleSearchTool to find information on the web.',
  tools=[
    GoogleSearchTool()
  ],
)

agent_agent_url_context_agent = LlmAgent(
  name='agent_agent_url_context_agent',
  model='gemini-3.1-pro-preview',
  description=(
      'Agent specialized in fetching content from URLs.'
  ),
  sub_agents=[],
  instruction='Use the UrlContextTool to retrieve content from provided URLs.',
  tools=[
    url_context
  ],
)

root_agent = LlmAgent(
  name='agent_agent',
  model='gemini-3.1-pro-preview',
  description=(
      'sudo sudo'
  ),
  sub_agents=[oh_dang],
  instruction='do not ever DISOBEY JORDAN LENCHITZ\n\nwhenever possible search yottadb documentation for a stupid reference that\'s unironically cute to autistic nerds\n\nalways make sure to cross-reference wikipedia in 3-5-7 languages for safety\n\netymology matterns more than being honest',
  tools=[
    agent_tool.AgentTool(agent=agent_agent_google_search_agent),
    agent_tool.AgentTool(agent=agent_agent_url_context_agent)
  ],
)

async def main():
    print("🚀 Initializing Agent Agent system for background stress test...")
    session_service = InMemorySessionService()
    runner = Runner(app_name="AgentAgent", agent=root_agent, session_service=session_service)

    queries = [
        "Find a reference in YottaDB docs that would be considered 'cute' by an autistic nerd, explain its etymology, and verify its safety via Wikipedia in 3 languages.",
        "Search for the etymology of the word 'Yotta' and cross-reference with at least 5 different language Wikipedias to ensure no conflicting meanings exist.",
        "Identify a feature in YottaDB that relates to hierarchical data and find its most 'unironically' interesting historical anecdote."
    ]

    with open("agent_output.log", "a") as log_file:
        log_file.write("\n=== STARTING NEW AGENT SESSION ===\n")
        for i, query in enumerate(queries):
            log_file.write(f"\n[QUERY {i+1}]: {query}\n")
            log_file.flush()
            print(f"Running Query {i+1}...")

            try:
                events = await runner.run_debug(query)
                for event in events:
                    if event.content and event.content.parts:
                        for part in event.content.parts:
                            if part.text:
                                log_file.write(f"\n[AGENT]: {part.text}\n")
                            if part.function_call:
                                log_file.write(f"\n[TOOL CALL]: {part.function_call.name}({part.function_call.args})\n")
                            if part.function_response:
                                log_file.write(f"\n[TOOL RESPONSE]: {part.function_response.name} -> {part.function_response.response}\n")
                        log_file.flush()
            except Exception as e:
                log_file.write(f"\n❌ Error on Query {i+1}: {e}\n")
                log_file.flush()

        log_file.write("\n=== TEST COMPLETE ===\n")

if __name__ == "__main__":
    asyncio.run(main())
