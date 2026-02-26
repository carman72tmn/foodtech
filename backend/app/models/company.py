from typing import Optional, List
from datetime import datetime
from sqlmodel import SQLModel, Field, Relationship

class CompanyBase(SQLModel):
    name: str
    description: Optional[str] = None
    inn: Optional[str] = None
    is_active: bool = True

    # iiko connection settings
    iiko_api_login: Optional[str] = None
    iiko_organization_id: Optional[str] = None


class Company(CompanyBase, table=True):
    __tablename__ = "companies"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    branches: List["Branch"] = Relationship(back_populates="company", sa_relationship_kwargs={"cascade": "all, delete-orphan"})


class BranchBase(SQLModel):
    name: str
    address: str
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_active: bool = True
    company_id: int = Field(foreign_key="companies.id")
    
    # Управление приемом заказов
    is_accepting_orders: bool = Field(default=True, description="Принимает ли филиал заказы вообще")
    is_accepting_delivery: bool = Field(default=True, description="Принимает ли заказы на доставку")
    is_accepting_pickup: bool = Field(default=True, description="Принимает ли заказы на самовывоз")
    
    # iiko sync correlation
    iiko_terminal_id: Optional[str] = None


class Branch(BranchBase, table=True):
    __tablename__ = "branches"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    company: Company = Relationship(back_populates="branches")
    delivery_zones: List["DeliveryZone"] = Relationship(back_populates="branch", sa_relationship_kwargs={"cascade": "all, delete-orphan"})


class DeliveryZoneBase(SQLModel):
    name: str
    branch_id: int = Field(foreign_key="branches.id")
    
    # Coordinates for polygon (GeoJSON or simple list of points stringified for MVP)
    polygon_coordinates: str = Field(description="JSON string of lat/lng coordinate pairs")
    
    min_order_amount: float = Field(default=0.0)
    delivery_cost: float = Field(default=0.0)
    free_delivery_from: Optional[float] = None
    is_active: bool = True


class DeliveryZone(DeliveryZoneBase, table=True):
    __tablename__ = "delivery_zones"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    branch: Branch = Relationship(back_populates="delivery_zones")
