"""
API эндпоинты для синхронизации с iiko и управления настройками
"""
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.iiko_settings import IikoSettings
from app.models.sync_log import SyncLog
from app.schemas import (
    IikoSyncResponse,
    IikoSettingsCreate,
    IikoSettingsResponse,
    IikoConnectionTestResponse,
    SyncLogResponse,
    IikoWebhookEventResponse
)
from app.models.iiko_webhook_event import IikoWebhookEvent
from app.services.iiko_service import iiko_service
from app.services.iiko_sync_service import iiko_sync_service

router = APIRouter(prefix="/iiko", tags=["iiko Integration"])


# =============================================================================
# Настройки
# =============================================================================

@router.get("/settings", response_model=IikoSettingsResponse)
async def get_settings(session: Session = Depends(get_session)):
    """Получить текущие настройки iiko"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="iiko settings not configured")
    return settings


@router.post("/settings", response_model=IikoSettingsResponse)
async def save_settings(
    data: IikoSettingsCreate,
    session: Session = Depends(get_session)
):
    """Сохранить / обновить настройки iiko"""
    existing = session.exec(select(IikoSettings)).first()

    if existing:
        for key, value in data.model_dump().items():
            setattr(existing, key, value)
        existing.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(existing)
        return existing
    else:
        new_settings = IikoSettings(**data.model_dump())
        session.add(new_settings)
        session.commit()
        session.refresh(new_settings)
        return new_settings


# =============================================================================
# Проверка подключения
# =============================================================================

@router.post("/test-connection", response_model=IikoConnectionTestResponse)
async def test_connection(
    data: Optional[IikoSettingsCreate] = None,
    session: Session = Depends(get_session)
):
    """Проверить подключение к iiko Cloud API"""
    print(f"DEBUG: test_connection called with data: {data}")
    if data:
        # Очищаем данные от пробелов
        api_login = data.api_login.strip() if data.api_login else ""
        org_id = data.organization_id.strip() if data.organization_id else ""
        
        print(f"DEBUG: Testing with provided login: {api_login}")
        # Тестируем с переданными данными (без сохранения в БД)
        try:
            result = await iiko_service.test_connection(
                api_login=api_login,
                organization_id=org_id
            )
            return IikoConnectionTestResponse(**result)
        except Exception as e:
            print(f"DEBUG: Exception in test_connection: {e}")
            raise HTTPException(status_code=400, detail=str(e))
    else:
        # Тестируем с данными из БД
        settings = session.exec(select(IikoSettings)).first()
        if not settings:
            raise HTTPException(status_code=404, detail="Settings not found")
        print(f"DEBUG: Testing with DB login: {settings.api_login}")
        try:
            result = await iiko_service.test_connection(
                api_login=settings.api_login,
                organization_id=settings.organization_id
            )
            return IikoConnectionTestResponse(**result)
        except Exception as e:
            print(f"DEBUG: Exception in test_connection (DB): {e}")
            raise HTTPException(status_code=400, detail=str(e))


# =============================================================================
# Справочники (организации, терминалы, типы оплаты)
# =============================================================================

@router.get("/organizations")
async def get_organizations(session: Session = Depends(get_session)):
    """Получить список организаций из iiko"""
    settings = session.exec(select(IikoSettings)).first()
    api_login = settings.api_login if settings else None
    try:
        return await iiko_service.get_organizations(api_login=api_login)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/terminal-groups")
async def get_terminal_groups(session: Session = Depends(get_session)):
    """Получить список терминальных групп"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    try:
        return await iiko_service.get_terminal_groups(
            api_login=settings.api_login,
            organization_id=settings.organization_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/payment-types")
async def get_payment_types(session: Session = Depends(get_session)):
    """Получить типы оплаты"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    try:
        return await iiko_service.get_payment_types(
            api_login=settings.api_login,
            organization_id=settings.organization_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/order-types")
async def get_order_types(session: Session = Depends(get_session)):
    """Получить типы заказов"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    try:
        return await iiko_service.get_order_types(
            api_login=settings.api_login,
            organization_id=settings.organization_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/discount-types")
async def get_discount_types(session: Session = Depends(get_session)):
    """Получить доступные типы скидок"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    try:
        return await iiko_service.get_discount_types(
            api_login=settings.api_login,
            organization_id=settings.organization_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/external-menus")
async def get_external_menus(session: Session = Depends(get_session)):
    """Получить список внешних меню"""
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    try:
        # Note: get_external_menus also needs update in service if dynamic
        return await iiko_service.get_external_menus(
            api_login=settings.api_login,
            organization_id=settings.organization_id
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Синхронизация
# =============================================================================

@router.post("/sync-menu", response_model=IikoSyncResponse)
async def sync_menu(session: Session = Depends(get_session)):
    """Полная синхронизация меню (категории + товары) из iiko"""
    try:
        result = await iiko_sync_service.sync_menu(session)
        return IikoSyncResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Menu sync error: {str(e)}")


@router.post("/sync-prices", response_model=IikoSyncResponse)
async def sync_prices(session: Session = Depends(get_session)):
    """Синхронизация только цен из iiko"""
    try:
        result = await iiko_sync_service.sync_prices(session)
        return IikoSyncResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Price sync error: {str(e)}")


@router.post("/sync-stop-lists", response_model=IikoSyncResponse)
async def sync_stop_lists(session: Session = Depends(get_session)):
    """Синхронизация стоп-листов (недоступные позиции)"""
    try:
        result = await iiko_sync_service.sync_stop_lists(session)
        return IikoSyncResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stop-list sync error: {str(e)}")


# =============================================================================
# Логи синхронизации
# =============================================================================

@router.get("/sync-logs", response_model=List[SyncLogResponse])
async def get_sync_logs(
    limit: int = 50,
    sync_type: str = None,
    session: Session = Depends(get_session)
):
    """Получить историю синхронизаций"""
    query = select(SyncLog).order_by(SyncLog.created_at.desc()).limit(limit)
    if sync_type:
        query = query.where(SyncLog.sync_type == sync_type)
    logs = session.exec(query).all()
    return logs


# =============================================================================
# Лояльность
# =============================================================================

@router.get("/customer/{phone}")
async def get_customer_info(phone: str):
    """Получить информацию о клиенте по номеру телефона"""
    try:
        return await iiko_service.get_customer_info(phone)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/customer/{phone}/balance")
async def get_customer_balance(phone: str):
    """Получить баланс бонусов клиента"""
    try:
        return await iiko_service.get_customer_balance(phone)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Управление вебхуками
# =============================================================================

@router.post("/webhooks/register")
async def register_webhook(
    webhook_url: str,
    auth_token: str = None,
    session: Session = Depends(get_session)
):
    """
    Регистрация вебхука в iiko и сохранение настроек
    """
    # 1. Сохраняем в БД
    settings = session.exec(select(IikoSettings)).first()
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    
    settings.webhook_url = webhook_url
    settings.webhook_auth_token = auth_token
    session.add(settings)
    session.commit()
    session.refresh(settings)

    # 2. Отправляем запрос в iiko
    try:
        result = await iiko_service.update_webhook_settings(webhook_url, auth_token)
        return {"success": True, "iiko_response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"iiko API error: {str(e)}")


@router.get("/webhooks/logs", response_model=List[IikoWebhookEventResponse])
async def get_webhook_logs(
    limit: int = 50,
    session: Session = Depends(get_session)
):
    """Получить лог вебхуков"""
    query = select(IikoWebhookEvent).order_by(IikoWebhookEvent.created_at.desc()).limit(limit)
    return session.exec(query).all()
