from langchain_community.llms import Ollama


def load_llm():

    llm = Ollama(
        model="llama3.2:3b"
    )

    return llm