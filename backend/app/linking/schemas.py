from pydantic import BaseModel, Field


class TableRef(BaseModel):
    table: str = Field(description="fully-qualified schema.table name")
    reason: str = Field(description="why this table is needed to answer the question")


class ColumnRef(BaseModel):
    table: str
    column: str


class JoinSpec(BaseModel):
    left_table: str
    left_column: str
    right_table: str
    right_column: str


class FilterSpec(BaseModel):
    table: str
    column: str
    op: str = Field(description="e.g. '=', '>', '<', 'IN', 'LIKE'")
    value: str = Field(description="literal value or short description if a subquery is implied")


class LinkedSchema(BaseModel):
    tables: list[TableRef]
    columns: list[ColumnRef]
    joins: list[JoinSpec]
    filters: list[FilterSpec]
    aggregation: str | None = Field(
        default=None, description="e.g. 'COUNT', 'SUM(claim.paid_amount)', or null if none"
    )
    out_of_scope: bool = Field(
        default=False,
        description="true if the question cannot be answered from the retrieved schema",
    )
    out_of_scope_reason: str | None = None


class RetrievedTable(BaseModel):
    table_schema: str
    table_name: str
    description: str
    columns_json: list[dict]
    domain_cluster: str | None = None
    score: float = 0.0

    @property
    def full_name(self) -> str:
        return f"{self.table_schema}.{self.table_name}"
