from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.funnel import Funnel
from app.schemas import FunnelCreate, FunnelUpdate, FunnelResponse

router = APIRouter(prefix="/funnels", tags=["Funnels"])

@router.get("/", response_model=List[FunnelResponse])
def get_funnels(db: Session = Depends(get_session)):
    """Получить список всех воронок"""
    funnels = db.exec(select(Funnel).order_by(Funnel.id.desc())).all()
    return funnels

@router.post("/", response_model=FunnelResponse)
def create_funnel(funnel: FunnelCreate, db: Session = Depends(get_session)):
    """Создать новую авто-воронку"""
    db_funnel = Funnel.model_validate(funnel)
    db.add(db_funnel)
    db.commit()
    db.refresh(db_funnel)
    return db_funnel

@router.get("/{funnel_id}", response_model=FunnelResponse)
def get_funnel(funnel_id: int, db: Session = Depends(get_session)):
    """Получить настройки конкретной воронки и её шаги"""
    funnel = db.get(Funnel, funnel_id)
    if not funnel:
        raise HTTPException(status_code=404, detail="Funnel not found")
    return funnel

@router.patch("/{funnel_id}", response_model=FunnelResponse)
def update_funnel(funnel_id: int, funnel_data: FunnelUpdate, db: Session = Depends(get_session)):
    """Обновить настройки воронки (включение/выключение, изменение шагов JSON)"""
    db_funnel = db.get(Funnel, funnel_id)
    if not db_funnel:
        raise HTTPException(status_code=404, detail="Funnel not found")
        
    update_data = funnel_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_funnel, key, value)
        
    db.add(db_funnel)
    db.commit()
    db.refresh(db_funnel)
    return db_funnel

@router.delete("/{funnel_id}")
def delete_funnel(funnel_id: int, db: Session = Depends(get_session)):
    """Удалить воронку"""
    funnel = db.get(Funnel, funnel_id)
    if not funnel:
        raise HTTPException(status_code=404, detail="Funnel not found")
        
    db.delete(funnel)
    db.commit()
    return {"ok": True}
