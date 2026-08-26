from sqlalchemy import create_engine

# declarative_base の import 元を sqlalchemy.ext.declarative から sqlalchemy.orm へ変更。
# SQLAlchemy 2.0 で正式な置き場所が orm 側に移り、旧 import は MovedIn20Warning が出る。
# 機能は同じ（返るクラスも同一）ので、import 行を差し替えるだけでよい。
from sqlalchemy.orm import declarative_base, sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./farmflow.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()