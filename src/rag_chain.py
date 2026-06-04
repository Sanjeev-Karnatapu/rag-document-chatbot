import time

def create_context(docs):

    context = "\n\n".join(
        [doc.page_content for doc in docs]
    )

    return context


def ask_question(question,
                 retriever,
                 llm):

    start = time.time()

    docs = retriever.invoke(question)

    print("Retrieval:", round(time.time() - start, 2), "seconds")

    context = create_context(docs)

    prompt = f"""
You are a helpful document assistant.

Answer ONLY using the provided context.

Context:
{context}

Question:
{question}
"""

    start = time.time()

    answer = llm.invoke(prompt)

    print("LLM:", round(time.time() - start, 2), "seconds")

    return answer, docs