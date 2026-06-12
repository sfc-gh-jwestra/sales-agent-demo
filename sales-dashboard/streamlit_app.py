"""
Sales Analytics Dashboard

Interactive dashboard showing:
- KPI summary cards (revenue, orders, customers, avg order value)
- Top 10 customers by revenue
- Top 10 markets for sales
- Monthly sales trend
- Revenue by product category
- Revenue by customer segment
"""

from datetime import date, timedelta
import os

import pandas as pd
import streamlit as st
import altair as alt
import snowflake.connector

st.set_page_config(
    page_title="Sales Analytics Dashboard",
    page_icon=":material/storefront:",
    layout="wide",
)

# =============================================================================
# Constants
# =============================================================================

CHART_HEIGHT = 350


# =============================================================================
# Snowflake Connection
# =============================================================================


@st.cache_resource
def get_connection():
    """Get Snowflake connection using snowflake-connector-python."""
    return snowflake.connector.connect(
        connection_name=os.getenv("SNOWFLAKE_DEFAULT_CONNECTION_NAME") or "default"
    )


@st.cache_data(ttl=600)
def run_query(sql):
    """Execute a query and return a DataFrame."""
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
        cols = [c[0].lower() for c in cur.description]
    return pd.DataFrame(rows, columns=cols)


# =============================================================================
# Data Loading
# =============================================================================


@st.cache_data(ttl=600)
def load_kpis():
    """Load KPI summary metrics."""
    return run_query("""
        SELECT 
            SUM(TOTAL_AMOUNT) AS total_revenue,
            COUNT(DISTINCT ORDER_ID) AS total_orders,
            COUNT(DISTINCT CUSTOMER_ID) AS active_customers,
            ROUND(AVG(TOTAL_AMOUNT), 2) AS avg_order_value
        FROM DEMO_DB.SALES.ORDERS
    """)


@st.cache_data(ttl=600)
def load_top_customers():
    """Load top 10 customers by revenue."""
    return run_query("""
        SELECT 
            c.CUSTOMER_NAME AS customer_name,
            c.SEGMENT AS segment,
            SUM(o.TOTAL_AMOUNT) AS total_revenue,
            COUNT(o.ORDER_ID) AS order_count
        FROM DEMO_DB.SALES.CUSTOMERS c
        JOIN DEMO_DB.SALES.ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
        GROUP BY c.CUSTOMER_NAME, c.SEGMENT
        ORDER BY total_revenue DESC
        LIMIT 10
    """)


@st.cache_data(ttl=600)
def load_top_markets():
    """Load top 10 markets by sales."""
    return run_query("""
        SELECT 
            m.MARKET_NAME AS market_name,
            m.REGION AS region,
            SUM(o.TOTAL_AMOUNT) AS total_sales,
            COUNT(o.ORDER_ID) AS order_count
        FROM DEMO_DB.SALES.MARKETS m
        JOIN DEMO_DB.SALES.ORDERS o ON m.MARKET_ID = o.MARKET_ID
        GROUP BY m.MARKET_NAME, m.REGION
        ORDER BY total_sales DESC
        LIMIT 10
    """)


@st.cache_data(ttl=600)
def load_monthly_trend():
    """Load monthly sales trend."""
    return run_query("""
        SELECT 
            DATE_TRUNC('MONTH', ORDER_DATE) AS month,
            SUM(TOTAL_AMOUNT) AS monthly_revenue,
            COUNT(DISTINCT ORDER_ID) AS order_count
        FROM DEMO_DB.SALES.ORDERS
        GROUP BY month
        ORDER BY month
    """)


@st.cache_data(ttl=600)
def load_category_revenue():
    """Load revenue by product category."""
    return run_query("""
        SELECT 
            p.CATEGORY AS category,
            SUM(oi.LINE_TOTAL) AS total_revenue,
            SUM(oi.QUANTITY) AS total_units
        FROM DEMO_DB.SALES.PRODUCTS p
        JOIN DEMO_DB.SALES.ORDER_ITEMS oi ON p.PRODUCT_ID = oi.PRODUCT_ID
        GROUP BY p.CATEGORY
        ORDER BY total_revenue DESC
    """)


@st.cache_data(ttl=600)
def load_segment_revenue():
    """Load revenue by customer segment."""
    return run_query("""
        SELECT 
            c.SEGMENT AS segment,
            COUNT(DISTINCT c.CUSTOMER_ID) AS customer_count,
            SUM(o.TOTAL_AMOUNT) AS total_revenue,
            COUNT(o.ORDER_ID) AS order_count
        FROM DEMO_DB.SALES.CUSTOMERS c
        JOIN DEMO_DB.SALES.ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
        GROUP BY c.SEGMENT
        ORDER BY total_revenue DESC
    """)


# =============================================================================
# Page Header
# =============================================================================

def render_page_header():
    """Render page header with title and reset button."""
    with st.container(
        horizontal=True, horizontal_alignment="distribute", vertical_alignment="center"
    ):
        st.markdown("# :material/storefront: Sales Analytics Dashboard")
        if st.button(":material/restart_alt: Refresh", type="tertiary"):
            st.cache_data.clear()
            st.rerun()


# =============================================================================
# Page Layout
# =============================================================================

render_page_header()
st.caption(":material/cloud: Powered by Snowflake  |  Data: DEMO_DB.SALES")

# --- KPI Cards ---
kpis = load_kpis()
if not kpis.empty:
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Revenue", f"${kpis['total_revenue'].iloc[0]:,.0f}")
    with col2:
        st.metric("Total Orders", f"{kpis['total_orders'].iloc[0]:,}")
    with col3:
        st.metric("Active Customers", f"{kpis['active_customers'].iloc[0]:,}")
    with col4:
        st.metric("Avg Order Value", f"${kpis['avg_order_value'].iloc[0]:,.0f}")

st.divider()

# --- Row 1: Top 10 Customers & Top 10 Markets ---
row1_left, row1_right = st.columns(2)

with row1_left:
    st.subheader("Top 10 Customers by Revenue")
    df_customers = load_top_customers()
    if not df_customers.empty:
        chart = (
            alt.Chart(df_customers)
            .mark_bar()
            .encode(
                x=alt.X("total_revenue:Q", title="Revenue ($)"),
                y=alt.Y("customer_name:N", sort="-x", title=None),
                color=alt.Color(
                    "segment:N",
                    title="Segment",
                    legend=alt.Legend(orient="bottom"),
                ),
                tooltip=[
                    alt.Tooltip("customer_name:N", title="Customer"),
                    alt.Tooltip("segment:N", title="Segment"),
                    alt.Tooltip("total_revenue:Q", title="Revenue", format="$,.0f"),
                    alt.Tooltip("order_count:Q", title="Orders"),
                ],
            )
            .properties(height=CHART_HEIGHT)
        )
        st.altair_chart(chart, use_container_width=True)

with row1_right:
    st.subheader("Top 10 Markets for Sales")
    df_markets = load_top_markets()
    if not df_markets.empty:
        chart = (
            alt.Chart(df_markets)
            .mark_bar()
            .encode(
                x=alt.X("total_sales:Q", title="Sales ($)"),
                y=alt.Y("market_name:N", sort="-x", title=None),
                color=alt.Color(
                    "region:N",
                    title="Region",
                    legend=alt.Legend(orient="bottom"),
                ),
                tooltip=[
                    alt.Tooltip("market_name:N", title="Market"),
                    alt.Tooltip("region:N", title="Region"),
                    alt.Tooltip("total_sales:Q", title="Sales", format="$,.0f"),
                    alt.Tooltip("order_count:Q", title="Orders"),
                ],
            )
            .properties(height=CHART_HEIGHT)
        )
        st.altair_chart(chart, use_container_width=True)

st.divider()

# --- Row 2: Monthly Trend ---
st.subheader("Monthly Sales Trend")
df_trend = load_monthly_trend()
if not df_trend.empty:
    df_trend["month"] = pd.to_datetime(df_trend["month"])
    chart = (
        alt.Chart(df_trend)
        .mark_line(point=True, strokeWidth=2)
        .encode(
            x=alt.X("month:T", title=None),
            y=alt.Y("monthly_revenue:Q", title="Revenue ($)", scale=alt.Scale(zero=False)),
            tooltip=[
                alt.Tooltip("month:T", title="Month", format="%B %Y"),
                alt.Tooltip("monthly_revenue:Q", title="Revenue", format="$,.0f"),
                alt.Tooltip("order_count:Q", title="Orders"),
            ],
        )
        .properties(height=CHART_HEIGHT)
    )
    st.altair_chart(chart, use_container_width=True)

st.divider()

# --- Row 3: Category & Segment ---
row3_left, row3_right = st.columns(2)

with row3_left:
    st.subheader("Revenue by Product Category")
    df_category = load_category_revenue()
    if not df_category.empty:
        chart = (
            alt.Chart(df_category)
            .mark_arc(innerRadius=60)
            .encode(
                theta=alt.Theta("total_revenue:Q"),
                color=alt.Color(
                    "category:N",
                    title="Category",
                    legend=alt.Legend(orient="bottom"),
                ),
                tooltip=[
                    alt.Tooltip("category:N", title="Category"),
                    alt.Tooltip("total_revenue:Q", title="Revenue", format="$,.0f"),
                    alt.Tooltip("total_units:Q", title="Units Sold"),
                ],
            )
            .properties(height=CHART_HEIGHT)
        )
        st.altair_chart(chart, use_container_width=True)

with row3_right:
    st.subheader("Revenue by Customer Segment")
    df_segment = load_segment_revenue()
    if not df_segment.empty:
        chart = (
            alt.Chart(df_segment)
            .mark_bar()
            .encode(
                x=alt.X("segment:N", title=None, sort="-y"),
                y=alt.Y("total_revenue:Q", title="Revenue ($)"),
                color=alt.Color(
                    "segment:N",
                    title="Segment",
                    legend=None,
                ),
                tooltip=[
                    alt.Tooltip("segment:N", title="Segment"),
                    alt.Tooltip("total_revenue:Q", title="Revenue", format="$,.0f"),
                    alt.Tooltip("customer_count:Q", title="Customers"),
                    alt.Tooltip("order_count:Q", title="Orders"),
                ],
            )
            .properties(height=CHART_HEIGHT)
        )
        st.altair_chart(chart, use_container_width=True)
