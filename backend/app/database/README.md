The RAG database adapter is currently isolated in `app/knowledge/rag.py`.
Enable PostgreSQL with pgvector using `DATABASE_URL` and
`REVALUE_KNOWLEDGE_BACKEND=postgres`; local development automatically falls
back to an in-memory vector store when the database is unavailable.
