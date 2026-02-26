"""
API эндпоинты для управления Клиентами
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlmodel import Session, select
from app.core.database import get_session
from app.models.customer import Customer
from app.schemas import CustomerCreate, CustomerUpdate, CustomerResponse

router = APIRouter(prefix="/customers", tags=["Customers"])

@router.get("/", response_model=List[CustomerResponse])
async def get_customers(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    session: Session = Depends(get_session)
):
    """Список клиентов с возможностью поиска по телефону или имени"""
    query = select(Customer).order_by(Customer.created_at.desc()).offset(skip).limit(limit)
    
    if search:
        query = query.where(
            Customer.phone.contains(search) | Customer.name.contains(search)
        )
        
    customers = session.exec(query).all()
    return customers

@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(customer_id: int, session: Session = Depends(get_session)):
    """Детали одного клиента"""
    customer = session.get(Customer, customer_id)
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    return customer

@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(
    customer_data: CustomerCreate,
    session: Session = Depends(get_session)
):
    """Создать профиль клиента"""
    existing = session.exec(select(Customer).where(Customer.phone == customer_data.phone)).first()
    if existing:
        raise HTTPException(status_code=400, detail="Customer with this phone already exists")
        
    customer = Customer(**customer_data.model_dump())
    session.add(customer)
    session.commit()
    session.refresh(customer)
    return customer

@router.patch("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: int,
    customer_data: CustomerUpdate,
    session: Session = Depends(get_session)
):
    """Обновление профиля клиента"""
    customer = session.get(Customer, customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    update_data = customer_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(customer, key, value)

    session.add(customer)
    session.commit()
    session.refresh(customer)
    return customer
