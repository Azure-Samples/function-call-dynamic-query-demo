from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.functions import execute_query

router = APIRouter()


class QueryRequest(BaseModel):
    query: str


@router.post("/execute_query/")
async def execute_query_endpoint(request: QueryRequest):
    results = execute_query(request.query)
    return {"results": results}


@router.get("/health_check/")
async def health_check():
    try:
        query = "SELECT 1 AS Test"
        results = execute_query(query)
        if results:
            return {
                "status": "success",
                "details": "Database connection and query execution are working.",
            }
        else:
            return {"status": "error", "details": "Database connection or query execution failed."}
    except Exception as e:
        return {"status": "error", "details": str(e)}
