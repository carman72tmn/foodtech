from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.story import Story
from app.schemas import StoryCreate, StoryUpdate, StoryResponse

router = APIRouter(prefix="/stories", tags=["Stories"])

@router.get("/", response_model=List[StoryResponse])
def get_stories(is_active: bool = None, db: Session = Depends(get_session)):
    """Получить список историй (можно отфильтровать активные для фронтенда)"""
    query = select(Story)
    if is_active is not None:
        query = query.where(Story.is_active == is_active)
        
    # Сортируем по заданному порядку
    query = query.order_by(Story.sort_order)
    
    stories = db.exec(query).all()
    return stories

@router.post("/", response_model=StoryResponse)
def create_story(story: StoryCreate, db: Session = Depends(get_session)):
    """Создать новую историю"""
    db_story = Story.model_validate(story)
    db.add(db_story)
    db.commit()
    db.refresh(db_story)
    return db_story

@router.get("/{story_id}", response_model=StoryResponse)
def get_story(story_id: int, db: Session = Depends(get_session)):
    """Получить информацию о конкретной истории"""
    story = db.get(Story, story_id)
    if not story:
        raise HTTPException(status_code=404, detail="Story not found")
    return story

@router.patch("/{story_id}", response_model=StoryResponse)
def update_story(story_id: int, story_data: StoryUpdate, db: Session = Depends(get_session)):
    """Обновить настройки истории (скрыть, изменить ссылку)"""
    db_story = db.get(Story, story_id)
    if not db_story:
        raise HTTPException(status_code=404, detail="Story not found")
        
    update_data = story_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_story, key, value)
        
    db.add(db_story)
    db.commit()
    db.refresh(db_story)
    return db_story

@router.delete("/{story_id}")
def delete_story(story_id: int, db: Session = Depends(get_session)):
    """Удалить историю"""
    story = db.get(Story, story_id)
    if not story:
        raise HTTPException(status_code=404, detail="Story not found")
        
    db.delete(story)
    db.commit()
    return {"ok": True}
