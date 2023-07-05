-- Shlomit Yehezkel 
-- 14.05.2023

-- Advanced SQL
-- Project 2 

--EX1
GO
select pp.ProductID as 'Product ID', pp.Name as 'Product Name', pp.Color as 'Product Color',pp.ListPrice as'Product List Price', pp.Size as 'Product Size'
from Production.Product as PP
	left join  Sales.SalesOrderDetail as SS
	on ss.ProductID=pp.ProductID
where ss.ProductID is null 
-- 238 rows

-- EX2
/* 
update Sales.Customer set PersonID=CustomerID
where CustomerID<=290
update Sales.Customer set PersonID=CustomerID+1700
where CustomerID>=300 and CustomerID <=350
update Sales.Customer set PersonID=CustomerID+1700
where CustomerID>=352290 and CustomerID <=701
*/ 
GO
select SC.CustomerID as 'Customer ID',ISNULL( PP.FirstName, 'UnKnown') as 'First Name', ISNULL( PP.LastName, 'UnKnown') as 'Last Name'
from Sales.Customer as SC
	full join  Sales.SalesOrderHeader as SOH
	on SOH.CustomerID=SC.CustomerID
	 left join Person.Person as PP
	on PP.BusinessEntityID=SC.PersonID
where SOH.SalesOrderID is null
order by SC.CustomerID
-- 701 Rows 

--EX3
GO
select top 10*
from
(
select distinct  SC.CustomerID as 'Customer ID', PP.FirstName as 'First Name',  PP.LastName as 'Last Name',
	  count  (SOH.SalesOrderID) over (partition by SOH.CustomerID )as 'Current Order' 
from Sales.Customer as SC
	full join  Sales.SalesOrderHeader as SOH
	on SOH.CustomerID=SC.CustomerID
	left join Person.Person as PP
	on PP.BusinessEntityID=SC.PersonID
) as Top10
order by 4 desc
--10 Rows

-- EX4
GO
select PP.FirstName as 'First Name', PP.LastName as 'Last Name', HRE.JobTitle as 'Emp Job Titel', HRE.HireDate as 'Hire Date',
count (HRE.BusinessEntityID) over (partition by HRE.JobTitle ) as 'Emp on this Titel'
from HumanResources.Employee as HRE
	join Person.Person as PP
	on pp.BusinessEntityID=HRE.BusinessEntityID
--290 Rows

-- Ex5 with Rank
GO
with CTE_2Last_ORDERS_DATE
as (
	select SC.CustomerID , PP.FirstName ,  PP.LastName , SOH.OrderDate ,
	DENSE_RANK() over(partition by SC.CustomerID order by SOH.OrderDate desc) as Rank, 
	LEAD ( SOH.OrderDate) over (partition by SC.CustomerID order by SOH.OrderDate desc) as Lead
	from Sales.Customer as SC
		full join  Sales.SalesOrderHeader as SOH
		on SOH.CustomerID=SC.CustomerID
		 left join Person.Person as PP
		on PP.BusinessEntityID=SC.PersonID
	where SOH.OrderDate is not null
	--and SC.CustomerID = 11638 or SC.CustomerID = 11153 
	)
select CTE_2Last_ORDERS_DATE.CustomerID as  'Customer ID',
		CTE_2Last_ORDERS_DATE.FirstName as  'First Name ',
		CTE_2Last_ORDERS_DATE.LastName as  'Last Name ',
		CTE_2Last_ORDERS_DATE.OrderDate as 'Last Order Date',
		CTE_2Last_ORDERS_DATE.Lead as 'Previous Order Date'
from CTE_2Last_ORDERS_DATE
where CTE_2Last_ORDERS_DATE.Rank = 1 
 --19,127 Rows

 -- Ex5 with ROW_NUMBER
 GO
 with CTE_2Last_ORDERS_DATE
as (
	select SC.CustomerID , PP.FirstName ,  PP.LastName , SOH.OrderDate ,
	ROW_NUMBER() over(partition by SC.CustomerID order by SOH.OrderDate desc) as ROWNUM, 
	LEAD ( SOH.OrderDate) over (partition by SC.CustomerID order by SOH.OrderDate desc) as Lead
	from Sales.Customer as SC
		full join  Sales.SalesOrderHeader as SOH
		on SOH.CustomerID=SC.CustomerID
		 left join Person.Person as PP
		on PP.BusinessEntityID=SC.PersonID
	where SOH.OrderDate is not null
	)
select CTE_2Last_ORDERS_DATE.CustomerID as  'Customer ID',
		CTE_2Last_ORDERS_DATE.FirstName as  'First Name ',
		CTE_2Last_ORDERS_DATE.LastName as  'Last Name ',
		CTE_2Last_ORDERS_DATE.OrderDate as 'Last Order Date',
		CTE_2Last_ORDERS_DATE.Lead as 'Previous Order Date'
from CTE_2Last_ORDERS_DATE
where CTE_2Last_ORDERS_DATE.ROWNUM = 1 
-- 19119 ROWS

-- EX6
GO
with CTE_Highest_Order
as (
select year( SOH.OrderDate) as Year ,SOH.SalesOrderID  as 'Order Number', PP.FirstName as ' Customer First Name',  PP.LastName as 'Customer Last Name', SOH.SubTotal as 'Total Amount',
DENSE_RANK() over(partition by year( SOH.OrderDate) order by  SOH.SubTotal desc)  as 'Rank '

from Sales.Customer as SC
	full join  Sales.SalesOrderHeader as SOH
	on SOH.CustomerID=SC.CustomerID
	 left join Person.Person as PP
	on PP.BusinessEntityID=SC.PersonID
	where SOH.SalesOrderID is not null --and SOH.SalesOrderID = 73793
)
select CTE_Highest_Order.Year,CTE_Highest_Order.[Order Number] ,CTE_Highest_Order.[ Customer First Name], CTE_Highest_Order.[Customer Last Name],
 FORMAT(Cast(CTE_Highest_Order.[Total Amount] as money),'C', 'en-us') As 'Total Amount'
from CTE_Highest_Order
where CTE_Highest_Order.[Rank ]=1


--EX7
GO
select * from
(
select  year( SOH.OrderDate) as Year, MONTH( SOH.OrderDate) as Month, SOH.SalesOrderID  
from Sales.SalesOrderHeader as SOH
) As INFO
pivot (count( SalesOrderID ) for Year in ([2011],[2012],[2013],[2014]) ) as YY order by Month

--EX8 
with CTE_Sub_Total as -- Creat information data
(select  CAST(YEAR( SOH.OrderDate)as varchar(10)) as Year, 
		CAST(MONTH( SOH.OrderDate)as varchar(10)) as Month,
		FORMAT (SUM(SOH.SubTotal),'c','en-us') as SubTotal,
	    Format(SUM(SUM(SOH.SubTotal))over(partition by YEAR( SOH.OrderDate) order by MONTH( SOH.OrderDate) rows between unbounded preceding and current row),'c','en-us') as 'Cumulative Amount'
from sales.salesorderheader SOH 
group by YEAR( SOH.OrderDate), MONTH( SOH.OrderDate))
,
CTE_IS as -- Interim Summary 
(select CAST (YEAR( SOH.OrderDate) as varchar (10)) as Year,
		'Total' as Month,
		'-->' as SubTotal,
		Format(sum(SOH.SubTotal),'c','en-us') as 'Cumulative Amount'
	from sales.salesorderheader SOH 
	group by YEAR( SOH.OrderDate)
union
select 'Grand' as Year,
		'Total' as Month, 
		'=' as Sum_Price,
		FORMAT(SUM(SOH.SubTotal),'c','en-us') as 'Cumulative Amount'
	from sales.salesorderheader SOH)

select * from CTE_Sub_Total 
union
select * from CTE_IS


--EX9
GO
with CTE_EMP as
(
select HD.Name as 'DepartmentName',
		HE.BusinessEntityID As'EmployeID',
		CONCAT( PP.LastName ,' ', PP.LastName) AS 'EmployeFullName',
		HE.HireDate AS 'HireDate',
		DATEDIFF(MM, HE.HireDate,getdate()) As'Seniority'
from HumanResources.Employee HE
	 join HumanResources.EmployeeDepartmentHistory as HEH
	on HE.BusinessEntityID=HEH.BusinessEntityID
	 join HumanResources.Department as HD
	on HD.DepartmentID = HEH.DepartmentID
	 join Person.Person as PP
	on PP.BusinessEntityID=HE.BusinessEntityID
where HD.Name is not null and HEH.EndDate is null)
select*,
	LEAD(EmployeFullName,1)over(partition by DepartmentName order by HireDate desc  ) as 'Previous Emp Name',
	LEAD(HireDate,1)over(partition by DepartmentName order by HireDate desc ) as 'Previous EmpHDate',
	DATEDIFF (dd ,LEAD(HireDate,1)over(partition by DepartmentName order by HireDate desc ),HireDate ) as 'Days Apart'
from CTE_EMP
order by DepartmentName,HireDate desc

--EX10
GO
with CTE_EMP AS
(
SELECT HE.HireDate as 'Hire Date' ,HD.DepartmentID as 'Department ID',
	 concat (HE.BusinessEntityID ,' ', PP.LastName, ' ' ,PP.FirstName,'  ') as INFO
from HumanResources.Employee HE
	join HumanResources.EmployeeDepartmentHistory as HEH
	on HE.BusinessEntityID=HEH.BusinessEntityID
	join HumanResources.Department as HD
	on HD.DepartmentID = HEH.DepartmentID
	join Person.Person as PP
	on PP.BusinessEntityID=HE.BusinessEntityID
where HEH.EndDate is null		
)
select CTE_EMP.[Hire Date], CTE_EMP.[Department ID] , STRING_AGG (CTE_EMP.INFO, ' ') as 'Department EMPP with Hired on same date'
from CTE_EMP 
group by CTE_EMP.[Hire Date], CTE_EMP.[Department ID]
order by 1


