from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, DECIMAL, BLOB
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import UUID
import datetime
import uuid

Base = declarative_base()


class Customer(Base):
    __tablename__ = "Customer"

    CustomerID = Column(Integer, primary_key=True, index=True)
    NameStyle = Column(Boolean, default=False)
    Title = Column(String(8), nullable=True)
    FirstName = Column(String(50), nullable=False)
    MiddleName = Column(String(50), nullable=True)
    LastName = Column(String(50), nullable=False)
    Suffix = Column(String(10), nullable=True)
    CompanyName = Column(String(128), nullable=True)
    SalesPerson = Column(String(256), nullable=True)
    EmailAddress = Column(String(50), nullable=True)
    Phone = Column(String(25), nullable=True)
    PasswordHash = Column(String(128), nullable=False)
    PasswordSalt = Column(String(10), nullable=False)
    rowguid = Column(UUID(as_uuid=True), default=uuid.uuid4, nullable=False)
    ModifiedDate = Column(DateTime, default=datetime.datetime.now, nullable=False)


class Product(Base):
    __tablename__ = "Product"

    ProductID = Column(Integer, primary_key=True, index=True)
    Name = Column(String(50), nullable=False)
    ProductNumber = Column(String(25), nullable=False)
    Color = Column(String(15), nullable=True)
    StandardCost = Column(Float, nullable=False)
    ListPrice = Column(Float, nullable=False)
    Size = Column(String(5), nullable=True)
    Weight = Column(DECIMAL(precision=8, scale=2), nullable=True)
    ProductCategoryID = Column(Integer, nullable=True)
    ProductModelID = Column(Integer, nullable=True)
    SellStartDate = Column(DateTime, nullable=False)
    SellEndDate = Column(DateTime, nullable=True)
    DiscontinuedDate = Column(DateTime, nullable=True)
    ThumbNailPhoto = Column(BLOB, nullable=True)
    ThumbnailPhotoFileName = Column(String(50), nullable=True)
    rowguid = Column(UUID(as_uuid=True), default=uuid.uuid4, nullable=False)
    ModifiedDate = Column(DateTime, default=datetime.datetime.now, nullable=False)
