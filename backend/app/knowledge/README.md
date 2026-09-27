The curated seed knowledge and retrieval implementation live in `rag.py`.

The default local development path uses cosine retrieval over a deterministic
hash embedding when `sentence-transformers` is unavailable. Set
`REVALUE_KNOWLEDGE_BACKEND=postgres` and `DATABASE_URL` to use PostgreSQL with
the pgvector extension and `all-MiniLM-L6-v2` embeddings. In `auto` mode,
database or model startup failures fall back to the local store.
