"""
API эндпоинты для управления Филиалами и Зонами доставки
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.company import Branch, DeliveryZone
from app.schemas import (
    BranchCreate, BranchUpdate, BranchResponse,
    DeliveryZoneCreate, DeliveryZoneUpdate, DeliveryZoneResponse
)

router = APIRouter(prefix="/branches", tags=["Branches"])

# ============= Филиалы =============

@router.get("/", response_model=List[BranchResponse])
async def get_branches(
    company_id: int = None,
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(get_session)
):
    """Список всех филиалов (с возможностью фильтрации по компании)"""
    query = select(Branch).offset(skip).limit(limit)
    if company_id:
        query = query.where(Branch.company_id == company_id)
        
    branches = session.exec(query).all()
    return branches


@router.get("/{branch_id}", response_model=BranchResponse)
async def get_branch(branch_id: int, session: Session = Depends(get_session)):
    """Детали одного филиала"""
    branch = session.get(Branch, branch_id)
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Branch with id {branch_id} not found"
        )
    return branch


@router.post("/", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
async def create_branch(
    branch_data: BranchCreate,
    session: Session = Depends(get_session)
):
    """Создание нового филиала"""
    branch = Branch(**branch_data.model_dump())
    session.add(branch)
    session.commit()
    session.refresh(branch)
    return branch


@router.patch("/{branch_id}", response_model=BranchResponse)
async def update_branch(
    branch_id: int,
    branch_data: BranchUpdate,
    session: Session = Depends(get_session)
):
    """Обновление данных филиала"""
    branch = session.get(Branch, branch_id)
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Branch with id {branch_id} not found"
        )

    update_data = branch_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(branch, key, value)

    session.add(branch)
    session.commit()
    session.refresh(branch)
    return branch


@router.delete("/{branch_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_branch(branch_id: int, session: Session = Depends(get_session)):
    """Удаление филиала"""
    branch = session.get(Branch, branch_id)
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Branch with id {branch_id} not found"
        )

    session.delete(branch)
    session.commit()


# ============= Зоны доставки =============

@router.get("/{branch_id}/zones", response_model=List[DeliveryZoneResponse])
async def get_delivery_zones(
    branch_id: int,
    session: Session = Depends(get_session)
):
    """Списки зон доставки для конкретного филиала"""
    query = select(DeliveryZone).where(DeliveryZone.branch_id == branch_id)
    zones = session.exec(query).all()
    return zones


@router.post("/{branch_id}/zones", response_model=DeliveryZoneResponse, status_code=status.HTTP_201_CREATED)
async def create_delivery_zone(
    branch_id: int,
    zone_data: DeliveryZoneCreate,
    session: Session = Depends(get_session)
):
    """Создание новой зоны доставки"""
    if zone_data.branch_id != branch_id:
        raise HTTPException(status_code=400, detail="Branch ID mismatch")
        
    zone = DeliveryZone(**zone_data.model_dump())
    session.add(zone)
    session.commit()
    session.refresh(zone)
    return zone

@router.patch("/zones/{zone_id}", response_model=DeliveryZoneResponse)
async def update_delivery_zone(
    zone_id: int,
    zone_data: DeliveryZoneUpdate,
    session: Session = Depends(get_session)
):
    """Обновление зоны доставки"""
    zone = session.get(DeliveryZone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")

    update_data = zone_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(zone, key, value)

    session.add(zone)
    session.commit()
    session.refresh(zone)
    return zone

@router.delete("/zones/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_delivery_zone(zone_id: int, session: Session = Depends(get_session)):
    """Удаление зоны доставки"""
    zone = session.get(DeliveryZone, zone_id)
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")

    session.delete(zone)
    session.commit()
