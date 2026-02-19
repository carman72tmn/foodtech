from fastapi import APIRouter, HTTPException, Depends
from app.services.loyalty import LoyaltyService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/balance/{phone}")
async def get_balance(phone: str):
    """
    Get customer loyalty balance by phone.
    """
    service = LoyaltyService()
    try:
        balance = await service.get_balance(phone)
        return {"phone": phone, "balance": balance}
    except Exception as e:
        logger.error(f"Error getting balance for {phone}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get balance: {str(e)}")
