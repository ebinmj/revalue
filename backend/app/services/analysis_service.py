from __future__ import annotations

from app.services.vision_service import BaseVisionService, create_vision_service


class AnalysisService:
    def __init__(self) -> None:
        self._vision_service: BaseVisionService | None = None

    def initialize(self) -> None:
        if self._vision_service is None:
            self._vision_service = create_vision_service()
        if not self._vision_service.ready:
            self._vision_service.load_model()

    def analyze_image(self, image_bytes: bytes, message: str, mode: str) -> dict:
        if self._vision_service is None or not self._vision_service.ready:
            self.initialize()
        return self._vision_service.analyze(image_bytes, message)

    @property
    def ready(self) -> bool:
        return self._vision_service is not None and self._vision_service.ready

    @property
    def model_loaded(self) -> bool:
        return self._vision_service is not None and self._vision_service.model_loaded
