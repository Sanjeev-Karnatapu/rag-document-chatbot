\# 🤖 AI-Powered Document Intelligence Platform



A Retrieval-Augmented Generation (RAG) chatbot that allows users to upload PDF documents and ask natural language questions about their contents.



Built using LangChain, ChromaDB, Ollama, and Streamlit, this project performs semantic document retrieval and context-aware answer generation completely on a local machine.



\---



\## 🚀 Features



\- Upload one or more PDF documents

\- Automatic PDF parsing and text extraction

\- Token-based document chunking

\- Semantic search using vector embeddings

\- ChromaDB vector database

\- Retrieval-Augmented Generation (RAG)

\- Local LLM inference using Ollama

\- Streamlit web interface

\- Multi-document support

\- Fast retrieval using Max Marginal Relevance (MMR)

\- Fully local and privacy-preserving workflow



\---



\## 🏗️ Architecture



```text

PDF Upload

&#x20;   ↓

Document Loader

&#x20;   ↓

Text Chunking

&#x20;   ↓

Embeddings Generation

&#x20;   ↓

Chroma Vector Database

&#x20;   ↓

Retriever (MMR)

&#x20;   ↓

Local LLM (Ollama)

&#x20;   ↓

Generated Answer

```



\---



\## 🛠️ Tech Stack



\### Frontend

\- Streamlit



\### AI / LLM

\- LangChain

\- Ollama

\- Llama 3.2 3B



\### Vector Database

\- ChromaDB



\### Embeddings

\- nomic-embed-text



\### Language

\- Python



\---



\## 📂 Project Structure



```text

RAG\_Chatbot/

│

├── app.py

├── README.md

├── rag\_chatbot.ipynb

│

├── src/

│   ├── pdf\_loader.py

│   ├── vector\_store.py

│   ├── retriever.py

│   ├── llm.py

│   └── rag\_chain.py

│

└── uploaded\_pdfs/

```



\---



\## ⚙️ Installation



\### Clone Repository



```bash

git clone https://github.com/Sanjeev-Karnatapu/rag-document-chatbot.git

cd rag-document-chatbot

```



\### Install Dependencies



```bash

pip install streamlit

pip install langchain

pip install langchain-community

pip install chromadb

pip install pypdf

```



\### Install Ollama



Download Ollama and install:



https://ollama.com



Pull required models:



```bash

ollama pull llama3.2:3b

ollama pull nomic-embed-text

```



\---



\## ▶️ Run Application



```bash

streamlit run app.py

```



\---



\## 📈 Performance Optimizations



\- Cached retriever using Streamlit session state

\- Cached LLM instance

\- MMR retrieval strategy

\- Reduced retrieval context size

\- Local inference with Ollama



\---



\## 🎯 Future Enhancements



\- Chat history

\- Source citations

\- Page-level references

\- Persistent vector database

\- FastAPI backend

\- Cloud deployment

\- Authentication support



\---



\## 👨‍💻 Author



\*\*Sanjeev Karnatapu\*\*



B.Tech Computer Science Engineering (AI \& ML)



Vellore Institute of Technology

