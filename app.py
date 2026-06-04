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
if "retriever" not in st.session_state:
    st.session_state.retriever = None

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
            f.write(uploaded_file.getbuffer())

        docs = load_pdf(save_path)

        all_docs.extend(docs)

    if st.session_state.retriever is None:
    
        vectorstore = build_vectorstore(all_docs)
    
        st.session_state.retriever = get_retriever(
            vectorstore
        )
    
    retriever = st.session_state.retriever

    if "llm" not in st.session_state:
        st.session_state.llm = load_llm()

    llm = st.session_state.llm

    st.success(
        "Documents processed successfully!"
    )

    question = st.chat_input(
        "Ask a question about your documents"
    )

    if question:

        with st.spinner("Searching documents..."):

            answer, sources = ask_question(
                question,
                retriever,
                llm
            )

        st.write("### Answer")
        st.write(answer)