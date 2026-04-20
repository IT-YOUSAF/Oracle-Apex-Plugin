select 'TOTAL ORDERS' label,
       '4,821' value,
       'fa-cube' icon,
       '#4a90e2' color,
       '▲ 12.4% vs last month' subtext,
       'positive' trend_type
from dual
union all
select 'TOTAL REVENUE',
       '$983K',
       'fa-usd',
       '#39a37a',
       '▲ 8.7% vs last month',
       'positive'
from dual
union all
select 'ACTIVE USERS',
       '1,247',
       'fa-users',
       '#8a67d5',
       '▲ 5.2% vs last month',
       'positive'
from dual
union all
select 'PENDING TASKS',
       '38',
       'fa-clipboard-list',
       '#d46a3a',
       '▼ needs attention',
       'negative'
from dual




-------------------------------

select 'Jan' label, 100 value from dual
union all
select 'Feb', 200 from dual
union all
select 'Mar', 150 from dual

------------------------------

select 'Completed' label, 5 value from dual
union all
select 'Pending', 3 from dual
union all
select 'Cancelled', 1 from dual

------------------------------------

select 'ORD-001' as "Order ID",
       'John Smith' as "Customer",
       '18 Apr 2026' as "Date",
       'Completed' as "STATUS",
       '$120.00' as "Amount",
       'Sales' as "Department"
from dual
union all
select 'ORD-002', 'Mary Jones', '17 Apr 2026', 'Pending' STATUS, '$85.00', 'Support' from dual