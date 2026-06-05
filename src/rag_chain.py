def create_context(docs):

    context = "\n\n".join(
        [doc.page_content for doc in docs]
    )

    return context


def ask_question(question,
                 retriever,
                 llm):

    docs = retriever.invoke(question)
    context = create_context(docs)

    prompt = f"""
You are a helpful document assistant.

Answer ONLY using the provided context.

If the answer is not available in the context,
say that the information is unavailable.

Context:
{context}

Question:
{question}
"""

    answer = llm.invoke(prompt)

    source_pages = []

    for doc in docs:

        page_number = doc.metadata.get(
            "page"
        )

        if page_number is not None:

            source_pages.append(
                page_number + 1
            )

    source_pages = sorted(
        list(set(source_pages))
    )

    return answer, source_pages