from __future__ import annotations

import re
from typing import Any

import httpx
from fastapi import HTTPException

from app.config import settings
from app.api.schemas import ComponentCreate, ListingStatus, MarketplaceListingCreate, MarketplaceListingUpdate


class SupabaseMarketplaceService:
    def _request(
        self,
        method: str,
        path: str,
        access_token: str,
        *,
        params: dict[str, str] | None = None,
        body: dict[str, Any] | None = None,
        prefer: str | None = None,
    ) -> Any:
        base_url = (settings.supabase_url or "").rstrip("/")
        anon_key = settings.supabase_anon_key
        if not base_url or not anon_key:
            raise HTTPException(
                status_code=503,
                detail="Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY on the backend.",
            )

        headers = {
            "apikey": anon_key,
            "Authorization": f"Bearer {access_token}",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        if prefer:
            headers["Prefer"] = prefer

        try:
            response = httpx.request(
                method,
                f"{base_url}/{path.lstrip('/')}" ,
                headers=headers,
                params=params,
                json=body,
                timeout=12.0,
            )
        except httpx.TimeoutException as exc:
            raise HTTPException(status_code=504, detail="Supabase request timed out.") from exc
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail="Could not reach Supabase.") from exc

        if response.status_code == 401:
            raise HTTPException(status_code=401, detail="Supabase access token is invalid or expired.")
        if response.status_code == 403:
            raise HTTPException(status_code=403, detail="Supabase denied this operation by row-level security.")
        if response.status_code >= 500:
            raise HTTPException(status_code=502, detail="Supabase request failed.")
        if response.status_code >= 400:
            try:
                payload = response.json()
                detail = payload.get("message") or payload.get("details") or "Supabase rejected the request."
            except ValueError:
                detail = "Supabase rejected the request."
            raise HTTPException(status_code=response.status_code, detail=detail)
        if response.status_code == 204 or not response.content:
            return None
        return response.json()

    def authenticate(self, access_token: str) -> dict[str, Any]:
        user = self._request("GET", "/auth/v1/user", access_token)
        if not isinstance(user, dict) or not user.get("id"):
            raise HTTPException(status_code=401, detail="Supabase did not return an authenticated user.")
        return user

    def upsert_profile(self, access_token: str, user: dict[str, Any], name: str) -> dict[str, Any]:
        metadata = user.get("user_metadata") or {}
        profile_name = name.strip() or str(metadata.get("name") or "User")
        rows = self._request(
            "POST",
            "/rest/v1/profiles",
            access_token,
            params={"on_conflict": "id"},
            body={"id": user["id"], "name": profile_name},
            prefer="resolution=merge-duplicates,return=representation",
        )
        return rows[0] if isinstance(rows, list) and rows else {"id": user["id"], "name": profile_name}

    def list_listings(
        self,
        access_token: str,
        user_id: str,
        *,
        search: str,
        category: str | None,
        condition: str | None,
        status: ListingStatus | None,
        mine: bool,
    ) -> list[dict[str, Any]]:
        params = self._listing_params(category, condition, status, user_id, mine)
        params["select"] = "*,profiles(name),components(*)"
        params["order"] = "created_at.desc"
        params["limit"] = "100"

        normalized_search = re.sub(r"[^\w\s.-]", "", search, flags=re.UNICODE).strip()[:100]
        if not normalized_search:
            rows = self._request("GET", "/rest/v1/listings", access_token, params=params)
            return [self._with_seller(row) for row in rows]

        pattern = f"*{normalized_search}*"
        params["or"] = (
            f"(title.ilike.{pattern},description.ilike.{pattern},category.ilike.{pattern})"
        )
        rows = self._request("GET", "/rest/v1/listings", access_token, params=params)

        component_rows = self._request(
            "GET",
            "/rest/v1/components",
            access_token,
            params={"select": "listing_id", "component_name": f"ilike.{pattern}", "limit": "100"},
        )
        component_listing_ids = {row["listing_id"] for row in component_rows if row.get("listing_id")}
        if component_listing_ids:
            related_params = self._listing_params(category, condition, status, user_id, mine)
            related_params.update({
                "select": "*,profiles(name),components(*)",
                "order": "created_at.desc",
                "id": f"in.({','.join(sorted(component_listing_ids))})",
                "limit": "100",
            })
            related_rows = self._request(
                "GET",
                "/rest/v1/listings",
                access_token,
                params=related_params,
            )
            by_id = {row["id"]: row for row in rows}
            by_id.update({row["id"]: row for row in related_rows})
            rows = list(by_id.values())
            rows.sort(key=lambda row: row.get("created_at", ""), reverse=True)

        return [self._with_seller(row) for row in rows]

    def get_listing(self, access_token: str, listing_id: str) -> dict[str, Any]:
        rows = self._request(
            "GET",
            "/rest/v1/listings",
            access_token,
            params={
                "select": "*,profiles(name),components(*)",
                "id": f"eq.{listing_id}",
                "limit": "1",
            },
        )
        if not rows:
            raise HTTPException(status_code=404, detail="Listing not found.")
        return self._with_seller(rows[0])

    def create_listing(
        self,
        access_token: str,
        user_id: str,
        listing: MarketplaceListingCreate,
    ) -> dict[str, Any]:
        body = listing.model_dump(mode="json", exclude_none=True)
        body.update({"seller_id": user_id, "status": ListingStatus.available.value})
        rows = self._request(
            "POST",
            "/rest/v1/listings",
            access_token,
            params={"select": "*,profiles(name),components(*)"},
            body=body,
            prefer="return=representation",
        )
        if not rows:
            raise HTTPException(status_code=502, detail="Supabase did not return the created listing.")
        return self._with_seller(rows[0])

    def update_listing(
        self,
        access_token: str,
        user_id: str,
        listing_id: str,
        listing: MarketplaceListingUpdate,
    ) -> dict[str, Any]:
        existing = self.get_listing(access_token, listing_id)
        self._require_owner(existing, user_id)
        body = listing.model_dump(mode="json", exclude_unset=True, exclude_none=True)
        if not body:
            raise HTTPException(status_code=400, detail="Provide at least one listing field to update.")
        rows = self._request(
            "PATCH",
            "/rest/v1/listings",
            access_token,
            params={"id": f"eq.{listing_id}", "select": "*,profiles(name),components(*)"},
            body=body,
            prefer="return=representation",
        )
        if not rows:
            raise HTTPException(status_code=404, detail="Listing not found.")
        return self._with_seller(rows[0])

    def delete_listing(self, access_token: str, user_id: str, listing_id: str) -> None:
        existing = self.get_listing(access_token, listing_id)
        self._require_owner(existing, user_id)
        self._request(
            "DELETE",
            "/rest/v1/listings",
            access_token,
            params={"id": f"eq.{listing_id}"},
            prefer="return=minimal",
        )

    def create_component(
        self,
        access_token: str,
        user_id: str,
        listing_id: str,
        component: ComponentCreate,
    ) -> dict[str, Any]:
        listing = self.get_listing(access_token, listing_id)
        self._require_owner(listing, user_id)
        body = component.model_dump(mode="json", exclude_none=True)
        body["listing_id"] = listing_id
        rows = self._request(
            "POST",
            "/rest/v1/components",
            access_token,
            params={"select": "*"},
            body=body,
            prefer="return=representation",
        )
        if not rows:
            raise HTTPException(status_code=502, detail="Supabase did not return the created component.")
        return rows[0]

    def list_components(self, access_token: str, listing_id: str) -> list[dict[str, Any]]:
        self.get_listing(access_token, listing_id)
        return self._request(
            "GET",
            "/rest/v1/components",
            access_token,
            params={
                "select": "*",
                "listing_id": f"eq.{listing_id}",
                "order": "created_at.asc",
            },
        )

    def _listing_params(
        self,
        category: str | None,
        condition: str | None,
        status: ListingStatus | None,
        user_id: str,
        mine: bool,
    ) -> dict[str, str]:
        params: dict[str, str] = {}
        if mine:
            params["seller_id"] = f"eq.{user_id}"
        if status is not None:
            params["status"] = f"eq.{status.value}"
        elif not mine:
            params["status"] = f"eq.{ListingStatus.available.value}"
        safe_category = re.sub(r"[^\w\s.-]", "", category, flags=re.UNICODE).strip() if category else ""
        safe_condition = re.sub(r"[^\w\s.-]", "", condition, flags=re.UNICODE).strip() if condition else ""
        if safe_category:
            params["category"] = f"ilike.{safe_category[:80]}"
        if safe_condition:
            params["condition"] = f"ilike.{safe_condition[:80]}"
        return params

    @staticmethod
    def _with_seller(row: dict[str, Any]) -> dict[str, Any]:
        profile = row.get("profiles") or {}
        if isinstance(profile, list):
            profile = profile[0] if profile else {}
        row["seller_name"] = profile.get("name") or "ReValue member"
        return row

    @staticmethod
    def _require_owner(listing: dict[str, Any], user_id: str) -> None:
        if listing.get("seller_id") != user_id:
            raise HTTPException(status_code=403, detail="You can only modify your own listings.")