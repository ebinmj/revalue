import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient
from unittest.mock import Mock

from app.config import settings
from app.main import app
from app.services.supabase_marketplace import SupabaseMarketplaceService


class FakeMarketplaceService:
    def authenticate(self, access_token: str) -> dict:
        if access_token != "user-a-token":
            raise AssertionError("Unexpected token")
        return {"id": "11111111-1111-4111-8111-111111111111", "email": "a@example.com"}

    def create_listing(self, access_token: str, user_id: str, listing: object) -> dict:
        return {
            "seller_id": user_id,
            "title": listing.title,
            "price": str(listing.price),
            "status": "available",
        }


class MarketplaceApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_marketplace_requires_a_supabase_bearer_token(self) -> None:
        response = self.client.get("/api/marketplace/listings")
        self.assertEqual(response.status_code, 401)

    def test_listing_seller_id_comes_from_authenticated_user(self) -> None:
        with patch("app.api.routes.marketplace_service", FakeMarketplaceService()):
            response = self.client.post(
                "/api/marketplace/listings",
                headers={"Authorization": "Bearer user-a-token"},
                json={
                    "title": "8GB DDR4 Laptop RAM",
                    "description": "Working RAM removed from a damaged laptop.",
                    "category": "RAM",
                    "condition": "Used - Working",
                    "price": 800,
                },
            )

        self.assertEqual(response.status_code, 201, response.text)
        self.assertEqual(
            response.json()["seller_id"],
            "11111111-1111-4111-8111-111111111111",
        )

    def test_client_cannot_supply_seller_id(self) -> None:
        with patch("app.api.routes.marketplace_service", FakeMarketplaceService()):
            response = self.client.post(
                "/api/marketplace/listings",
                headers={"Authorization": "Bearer user-a-token"},
                json={
                    "title": "RAM",
                    "category": "RAM",
                    "condition": "Used",
                    "price": 800,
                    "seller_id": "22222222-2222-4222-8222-222222222222",
                },
            )
        self.assertEqual(response.status_code, 422)

    def test_access_token_is_forwarded_to_supabase_auth_verification(self) -> None:
        response = Mock(status_code=200, content=b'{"id":"user-a"}')
        response.json.return_value = {"id": "user-a"}
        with (
            patch.object(settings, "supabase_url", "https://project.supabase.co"),
            patch.object(settings, "supabase_anon_key", "test-anon-key"),
            patch(
                "app.services.supabase_marketplace.httpx.request",
                return_value=response,
            ) as request,
        ):
            user = SupabaseMarketplaceService().authenticate("user-a-access-token")

        self.assertEqual(user["id"], "user-a")
        self.assertEqual(
            request.call_args.kwargs["headers"]["Authorization"],
            "Bearer user-a-access-token",
        )
        self.assertEqual(request.call_args.kwargs["headers"]["apikey"], "test-anon-key")


if __name__ == "__main__":
    unittest.main()