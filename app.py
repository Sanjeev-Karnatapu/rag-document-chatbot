import os
import streamlit as st

from src.pdf_loader import load_pdf
from src.vector_store import build_vectorstore
from src.retriever import get_retriever
from src.llm import load_llm
from src.rag_chain import ask_question

st.set_page_config(
    page_title="AI Document Assistant",
    page_icon="🤖",
    layout="wide"
)

st.title("🤖 AI Document Assistant")

# --------------------------
# Sidebar
# --------------------------

st.sidebar.title(
    "📚 Document Information"
)

if "messages" not in st.session_state:
    st.session_state.messages = []

if "retriever" not in st.session_state:
    st.session_state.retriever = None

if "llm" not in st.session_state:
    st.session_state.llm = None

if "chunk_count" not in st.session_state:
    st.session_state.chunk_count = 0

if st.sidebar.button(
    "🗑️ Clear Chat"
):
    st.session_state.messages = []
    st.rerun()

# --------------------------
# File Upload
# --------------------------

uploaded_files = st.file_uploader(
    "Upload PDF files",
    type=["pdf"],
    accept_multiple_files=True
)

if uploaded_files:

    all_docs = []

    for uploaded_file in uploaded_files:

        save_path = os.path.join(
            "uploaded_pdfs",
            uploaded_file.name
        )

        with open(save_path, "wb") as f:
            f.write(
                uploaded_file.getbuffer()
            )

        docs = load_pdf(
            save_path
        )

        all_docs.extend(
            docs
        )

    # --------------------------
    # Sidebar Information
    # --------------------------

    st.sidebar.write(
        "### Uploaded Files"
    )

    for uploaded_file in uploaded_files:

        st.sidebar.write(
            f"📄 {uploaded_file.name}"
        )

    st.sidebar.write(
        f"📑 Total Pages: {len(all_docs)}"
    )

    # --------------------------
    # Build Retriever
    # --------------------------

    if st.session_state.retriever is None:

        vectorstore, chunk_count = build_vectorstore(
            all_docs
        )

        st.session_state.chunk_count = chunk_count

        st.session_state.retriever = (
            get_retriever(
                vectorstore
            )
        )

    retriever = (
        st.session_state.retriever
    )

    st.sidebar.write(
        f"🧩 Chunks Indexed: {st.session_state.chunk_count}"
    )

    # --------------------------
    # Load LLM
    # --------------------------

    if st.session_state.llm is None:

        st.session_state.llm = (
            load_llm()
        )

    llm = st.session_state.llm

    st.success(
        "Documents processed successfully!"
    )

    # --------------------------
    # Display Chat History
    # --------------------------

    for message in (
        st.session_state.messages
    ):

        with st.chat_message(
            message["role"]
        ):

            st.markdown(
                message["content"]
            )

            if (
                message["role"] == "assistant"
                and "sources" in message
                and message["sources"]
            ):

                st.markdown(
                    "### Sources"
                )

                for page in (
                    message["sources"]
                ):

                    st.markdown(
                        f"📄 Page {page}"
                    )

    # --------------------------
    # Chat Input
    # --------------------------

    question = st.chat_input(
        "Ask a question about your documents"
    )

    if question:

        st.session_state.messages.append(
            {
                "role": "user",
                "content": question
            }
        )

        with st.chat_message(
            "user"
        ):
            st.markdown(
                question
            )

        with st.spinner(
            "Searching documents..."
        ):

            answer, sources = (
                ask_question(
                    question,
                    retriever,
                    llm
                )
            )

        st.session_state.messages.append(
            {
                "role": "assistant",
                "content": answer,
                "sources": sources
            }
        )

        with st.chat_message(
            "assistant"
        ):

            st.markdown(
                answer
            )

            if sources:

                st.markdown(
                    "### Sources"
                )

                for page in sources:

                    st.markdown(
                        f"📄 Page {page}"
                    )