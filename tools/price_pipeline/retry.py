"""Retry helper for flaky public endpoints."""

from __future__ import annotations

import time
from typing import Callable, TypeVar

T = TypeVar("T")


def with_retries(call: Callable[[], T], attempts: int = 3, sleep: Callable[[float], None] = time.sleep) -> T:
    """Run `call`, retrying on any error with a growing pause; re-raise after the last attempt."""
    for attempt in range(1, attempts + 1):
        try:
            return call()
        except Exception:
            if attempt == attempts:
                raise
            sleep(5.0 * attempt)
    raise AssertionError("unreachable")
