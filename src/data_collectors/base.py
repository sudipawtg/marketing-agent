"""Base collector interface"""

from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional
from datetime import datetime
from pydantic import BaseModel

T = TypeVar('T', bound=BaseModel)


class CollectorError(Exception):
    """Base exception for collector errors"""
    pass


class BaseCollector(ABC, Generic[T]):
    """Base class for all data collectors"""
    
    def __init__(self, cache_ttl: int = 300):
        """
        Args:
            cache_ttl: Cache time-to-live in seconds
        """
        self.cache_ttl = cache_ttl
        self._cache: dict = {}
    
    @abstractmethod
    async def collect(self, campaign_id: str, **kwargs) -> T:
        """Collect data for a campaign"""
        pass
    
    def _get_cache_key(self, campaign_id: str, **kwargs) -> str:
        """Generate cache key"""
        params = "_".join(f"{k}={v}" for k, v in sorted(kwargs.items()))
        return f"{self.__class__.__name__}:{campaign_id}:{params}"
    
    def _get_from_cache(self, cache_key: str) -> Optional[T]:
        """Get data from cache if not expired"""
        if cache_key in self._cache:
            data, timestamp = self._cache[cache_key]
            if (datetime.now() - timestamp).total_seconds() < self.cache_ttl:
                return data
        return None
    
    def _set_cache(self, cache_key: str, data: T):
        """Store data in cache"""
        self._cache[cache_key] = (data, datetime.now())
