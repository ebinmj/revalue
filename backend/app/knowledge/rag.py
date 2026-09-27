"""Small source-grounded knowledge retrieval layer for ReValue."""

from __future__ import annotations

import hashlib
import math
import os
import re
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Protocol

from pydantic import BaseModel


EMBEDDING_MODEL = "all-MiniLM-L6-v2"
EMBEDDING_DIMENSION = 384


class KnowledgeRecord(BaseModel):
    title: str
    content: str
    category: str
    source: str
    source_url: str | None = None
    timestamp: datetime


class RetrievedKnowledge(BaseModel):
    record: KnowledgeRecord
    score: float


class Embedder(Protocol):
    def embed(self, text: str) -> list[float]:
        ...


class MiniLMEmbedder:
    def __init__(self, model_name: str = EMBEDDING_MODEL) -> None:
        self.model_name = model_name
        self._model: Any | None = None

    def embed(self, text: str) -> list[float]:
        if self._model is None:
            from sentence_transformers import SentenceTransformer

            self._model = SentenceTransformer(self.model_name)
        vector = self._model.encode(text, normalize_embeddings=True)
        return vector.tolist()


class HashEmbedder:
    """Dependency-free fallback with stable vectors for local development."""

    def embed(self, text: str) -> list[float]:
        vector = [0.0] * EMBEDDING_DIMENSION
        tokens = re.findall(r"[a-z0-9]+", text.lower())
        for token in tokens:
            digest = hashlib.sha256(token.encode("utf-8")).digest()
            index = int.from_bytes(digest[:4], "big") % EMBEDDING_DIMENSION
            vector[index] += 1.0
        norm = math.sqrt(sum(value * value for value in vector))
        return [value / norm for value in vector] if norm else vector


class LocalVectorStore:
    def __init__(self, records: list[KnowledgeRecord], embedder: Embedder) -> None:
        self._embedder = embedder
        self._items = [(record, embedder.embed(_record_text(record))) for record in records]

    def search(self, query: str, limit: int = 5) -> list[RetrievedKnowledge]:
        query_vector = self._embedder.embed(query)
        ranked = [
            RetrievedKnowledge(record=record, score=_dot(query_vector, vector))
            for record, vector in self._items
        ]
        return sorted(ranked, key=lambda item: item.score, reverse=True)[:limit]


class PgVectorStore:
    """PostgreSQL/pgvector store. The connection is created only when selected."""

    def __init__(self, database_url: str, embedder: Embedder) -> None:
        self._database_url = database_url
        self._embedder = embedder
        self._connection: Any | None = None

    def _connect(self) -> Any:
        if self._connection is None:
            import psycopg
            from pgvector.psycopg import register_vector

            self._connection = psycopg.connect(self._database_url)
            register_vector(self._connection)
            self._connection.execute("CREATE EXTENSION IF NOT EXISTS vector")
            self._connection.execute(
                """
                CREATE TABLE IF NOT EXISTS revalue_knowledge (
                    title TEXT PRIMARY KEY,
                    content TEXT NOT NULL,
                    category TEXT NOT NULL,
                    source TEXT NOT NULL,
                    source_url TEXT,
                    recorded_at TIMESTAMPTZ NOT NULL,
                    embedding vector(384) NOT NULL
                )
                """
            )
            self._connection.commit()
        return self._connection

    def seed(self, records: list[KnowledgeRecord]) -> None:
        connection = self._connect()
        for record in records:
            connection.execute(
                """
                INSERT INTO revalue_knowledge
                    (title, content, category, source, source_url, recorded_at, embedding)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (title) DO UPDATE SET
                    content = EXCLUDED.content,
                    category = EXCLUDED.category,
                    source = EXCLUDED.source,
                    source_url = EXCLUDED.source_url,
                    recorded_at = EXCLUDED.recorded_at,
                    embedding = EXCLUDED.embedding
                """,
                (
                    record.title,
                    record.content,
                    record.category,
                    record.source,
                    record.source_url,
                    record.timestamp,
                    self._embedder.embed(_record_text(record)),
                ),
            )
        connection.commit()

    def search(self, query: str, limit: int = 5) -> list[RetrievedKnowledge]:
        connection = self._connect()
        rows = connection.execute(
            """
            SELECT title, content, category, source, source_url, recorded_at,
                   1 - (embedding <=> %s) AS score
            FROM revalue_knowledge
            ORDER BY embedding <=> %s
            LIMIT %s
            """,
            (self._embedder.embed(query), self._embedder.embed(query), limit),
        ).fetchall()
        return [
            RetrievedKnowledge(
                record=KnowledgeRecord(
                    title=row[0],
                    content=row[1],
                    category=row[2],
                    source=row[3],
                    source_url=row[4],
                    timestamp=row[5],
                ),
                score=float(row[6]),
            )
            for row in rows
        ]


class KnowledgeRetriever:
    def __init__(self, store: LocalVectorStore | PgVectorStore) -> None:
        self._store = store

    def retrieve(self, query: str, limit: int = 5) -> list[RetrievedKnowledge]:
        return self._store.search(query, limit=limit)

    @property
    def store_name(self) -> str:
        return type(self._store).__name__


def get_retriever() -> KnowledgeRetriever:
    return _build_retriever()


@lru_cache(maxsize=1)
def _build_retriever() -> KnowledgeRetriever:
    records = curated_knowledge_records()
    backend = os.getenv("REVALUE_KNOWLEDGE_BACKEND", "auto").lower()
    database_url = os.getenv("DATABASE_URL")
    use_postgres = backend == "postgres" or (backend == "auto" and database_url)

    if use_postgres and database_url:
        try:
            embedder = MiniLMEmbedder()
            store = PgVectorStore(database_url, embedder)
            store.seed(records)
            return KnowledgeRetriever(store)
        except Exception:
            if backend == "postgres":
                raise

    try:
        embedder = MiniLMEmbedder()
        embedder.embed("warm up")
    except Exception:
        embedder = HashEmbedder()
    return KnowledgeRetriever(LocalVectorStore(records, embedder))


def _record_text(record: KnowledgeRecord) -> str:
    return f"{record.title}. {record.category}. {record.content}"


def _dot(first: list[float], second: list[float]) -> float:
    return sum(left * right for left, right in zip(first, second))


def _record(
    title: str,
    content: str,
    category: str,
    source: str,
    source_url: str | None = None,
) -> KnowledgeRecord:
    return KnowledgeRecord(
        title=title,
        content=content,
        category=category,
        source=source,
        source_url=source_url,
        timestamp=datetime(2026, 9, 27, tzinfo=timezone.utc),
    )


def curated_knowledge_records() -> list[KnowledgeRecord]:
    """Return the small reviewed seed set used by both stores."""
    return [
        _record("Laptop will not power on", "Check the charger, power connector, battery state, and signs of liquid damage before deeper testing. A no-power symptom can have several causes.", "laptop repair", "ReValue curated guidance"),
        _record("Laptop display problems", "A dim, flickering, or blank display may involve brightness settings, the display cable, panel, graphics path, or power delivery. Inspect connectors before replacing a panel.", "laptop repair", "ReValue curated guidance"),
        _record("Laptop keyboard faults", "Test whether the fault affects one key or the whole keyboard. Debris, liquid exposure, a loose cable, or a failed keyboard assembly are possible causes.", "laptop repair", "ReValue curated guidance"),
        _record("Laptop overheating", "Dust buildup, blocked vents, a worn fan, or dried thermal interface material can contribute to overheating. Power down before cleaning and avoid blocking ventilation.", "laptop repair", "ReValue curated guidance"),
        _record("Laptop charging issues", "Try a known-compatible charger and inspect the cable and port for damage. Do not use a frayed cable or a swollen battery.", "laptop repair", "ReValue curated guidance"),
        _record("Liquid exposure", "Disconnect external power and avoid turning on a liquid-exposed laptop. Professional inspection is appropriate because corrosion and hidden damage may develop later.", "laptop repair", "iFixit device repair guidance", "https://www.ifixit.com/Device/Laptop"),
        _record("Back up data before repair", "If a device still works, back up important data before opening it or sending it for repair. Recovery work can change the device state.", "laptop repair", "ReValue curated guidance"),
        _record("Reuse working laptop display", "A working display assembly may be reusable as a replacement part, but compatibility depends on size, connector, resolution, mounting, and device model.", "component reuse", "ReValue curated guidance"),
        _record("Reuse laptop keyboard", "A keyboard can be recovered when keys and the cable interface work. Confirm the exact model and layout before listing or installing it.", "component reuse", "ReValue curated guidance"),
        _record("Reuse laptop charger", "A charger should only be reused with a compatible voltage, connector, polarity, and adequate current rating. Inspect insulation and the plug first.", "component reuse", "ReValue curated guidance"),
        _record("Reuse cooling fan", "A laptop fan may be recoverable if its bearings are quiet and the connector and dimensions match. Dust should be removed without damaging the blades.", "component reuse", "ReValue curated guidance"),
        _record("Reuse optical or wireless modules", "Small modules can sometimes be reused when their connector, firmware support, and physical fit are compatible with the receiving device.", "component reuse", "ReValue curated guidance"),
        _record("SSD data privacy", "Storage devices may contain personal data. Erase or securely destroy data using an appropriate process before reuse, resale, or recycling.", "SSD recovery", "NIST media sanitization guidance", "https://csrc.nist.gov/pubs/sp/800/88/r2/final"),
        _record("SSD recovery", "An SSD that is not detected may have a controller, firmware, connector, or power problem. Avoid assuming the data is recoverable and use a specialist for important data.", "SSD recovery", "ReValue curated guidance"),
        _record("RAM recovery", "Compatible RAM can often be tested and reused in another device. Match memory generation, form factor, capacity limits, and supported speed.", "RAM recovery", "ReValue curated guidance"),
        _record("Battery swelling", "A swollen lithium-ion battery is a safety hazard. Stop using and charging the device, do not puncture or compress the battery, and seek an appropriate battery handling pathway.", "batteries", "US EPA lithium-ion battery guidance", "https://www.epa.gov/recycle/used-lithium-ion-batteries"),
        _record("Battery removal", "Battery removal can be hazardous when cells are glued, bent, punctured, or damaged. A qualified repair provider should handle uncertain or damaged packs.", "batteries", "US EPA lithium-ion battery guidance", "https://www.epa.gov/recycle/used-lithium-ion-batteries"),
        _record("Battery transport", "Protect battery terminals from short circuits and keep damaged batteries separate from ordinary waste. Follow local collection requirements.", "batteries", "US EPA lithium-ion battery guidance", "https://www.epa.gov/recycle/used-lithium-ion-batteries"),
        _record("Electronic waste is a material stream", "Electronics can contain recoverable metals and plastics as well as components requiring controlled handling. Use an appropriate electronics recycler rather than general disposal where available.", "e-waste handling", "US EPA electronics donation and recycling", "https://www.epa.gov/recycle/electronics-donation-and-recycling"),
        _record("Prepare electronics for recycling", "Remove personal data, separate batteries when the design allows safe removal, and ask the recycler how it accepts the specific device.", "e-waste handling", "US EPA electronics donation and recycling", "https://www.epa.gov/recycle/electronics-donation-and-recycling"),
        _record("Do not burn electronics", "Burning or informal heating of electronics can release hazardous substances. Use formal reuse, take-back, or recycling channels.", "recycling guidance", "WHO e-waste and health", "https://www.who.int/news-room/fact-sheets/detail/electronic-waste-(e-waste)"),
        _record("Responsible cable recycling", "Cables may contain recoverable copper and should be routed through an electronics or cable recycling stream. Do not burn insulation to recover metal.", "recycling guidance", "ReValue curated guidance"),
        _record("Hazardous handling uncertainty", "When a product has a leaking battery, strong odor, heat, smoke, sharp damage, or unknown chemical exposure, keep people away and contact an appropriate local service.", "e-waste handling", "ReValue curated guidance"),
        _record("Repair before replacement", "A repair assessment can preserve product value when the fault is limited and safe to address. The right choice depends on condition, compatibility, cost, and available recovery routes.", "recovery guidance", "ReValue curated guidance"),
    ]
