from fastapi import FastAPI

from app.api.routes import router

app = FastAPI(
    title="ReValue API",
    version="0.1.0",
    description="Mock backend foundation for the ReValue recovery platform.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "ReValue API"}


app.include_router(router)
