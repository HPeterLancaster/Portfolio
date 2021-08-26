


----------------- Covid Deaths Data

--Select Location, date, total_cases, new_cases, total_deaths, population
--From Portfolio.dbo.CovidDeaths
--order by 1,2

-----------US Only

--Total Cases vs Total Deaths (US)
Select Location, Cast(date as datetime), total_cases, total_deaths, ((Cast(total_deaths as float)/NULLIF(Cast(total_cases as float),0))*100) as [Percentage(Deaths)]
From Portfolio.dbo.CovidDeaths
Where location like '%states%'
order by 1,2


-- Total Cases vs Population (US)
Select Location, Cast(date as datetime), total_cases, population, (Cast(total_cases as float)/population)*100 as [Percentage(Infected)]
From Portfolio.dbo.CovidDeaths
Where location like '%states%'
order by 1,2

--------------By Country

-- Total Cases vs Population (By Country)
Select Location, population, Max(total_cases) as Highest_Case_Count, (MAX(Cast(total_cases as float))/NullIF(cast(population as float),0))*100 as [Percentage Population Infected]
From Portfolio.dbo.CovidDeaths
where continent is not NULL
group by Location,population
order by [Percentage Population Infected] desc


-- Total Deaths vs Population (By Country)
Select Location, MAX(Cast(total_deaths as int)) as [Total_Death_Count]
From Portfolio.dbo.CovidDeaths A
where continent is not NULL  -- Not working. Dig in later. (Field leaving blanks not Nulls... Weird.)
group by Location
order by [Total_Death_Count] desc


------------ By Continent


-- Total Deaths vs Population (By Continent)
Select location, MAX(Cast(total_deaths as int)) as [Total_Death_Count]
From Portfolio.dbo.CovidDeaths A
where continent is not NULL  
group by location
order by [Total_Death_Count] desc


----------- Global 


--This isn't right. add partitions to correct sum method
Select cast(date as smalldatetime), SUM(Cast(new_cases as int)) as [Total Cases], SUM(Cast(new_deaths as int)) as [Total Deaths], 
	   (SUM(Cast(new_deaths as int))/NULLIF(SUM(Cast(new_cases as int)) ,0))*100 as  [Percentage(Deaths)]
From Portfolio.dbo.CovidDeaths
Where continent is not Null
Group by date
order by 1,2 





--------------------Vaccinations Data



Select *
From Portfolio.dbo.CovidVaccinations Vac
Join Portfolio.dbo.CovidDeaths Dea
	On Vac.location = Dea.location AND vac.date = dea.date




-- Total Vaccinations vs Population - (Vaccinations are per vaccine not per person. Is there a per person vaccine data point)

With VacvsPop (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccine_Total)
as
(
Select dea.continent, dea.location, Cast(dea.date as smalldatetime) as [Date], dea.population, CAST(vac.new_vaccinations as bigint) as New_Vaccinations,
       SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_Vaccine_Total
	   
From Portfolio.dbo.CovidDeaths Dea
Join Portfolio.dbo.CovidVaccinations Vac
	On Vac.location = Dea.location 
		AND 
	   vac.date = dea.date
	Where dea.continent is not NULL
	
)
Select * , (Rolling_Vaccine_Total/Population)*100 as [Vaccine_Doses_by_Population]
From VacvsPop
order by 2,3



--Temp Table
Drop Table if exists #Percent_Vaccines_by_Population
Create Table #Percent_Vaccines_by_Population
(
continent nvarchar(255),
Location nvarchar(255),
Date smalldatetime,
Population numeric,
New_Vaccinations numeric,
Rolling_Vaccine_Total numeric
)

Insert into #Percent_Vaccines_by_Population
Select dea.continent, dea.location, Cast(dea.date as smalldatetime) as [Date], dea.population, CAST(vac.new_vaccinations as bigint) as New_Vaccinations,
       SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_Vaccine_Total
From Portfolio.dbo.CovidDeaths Dea
Join Portfolio.dbo.CovidVaccinations Vac
	On Vac.location = Dea.location 
		AND 
	   vac.date = dea.date
	Where dea.continent is not NULL

Select * , (Rolling_Vaccine_Total/Population)*100 as [Vaccine_Doses_by_Population]
From #Percent_Vaccines_by_Population





------------- View Creation

Create View DeathsPercentPopulation as 
-- Total Deaths vs Population (By Continent)  Will work with location if I can get the "is not Null" to work
Select location, MAX(Cast(total_deaths as int)) as [Total_Death_Count]
From Portfolio.dbo.CovidDeaths A
where continent is not NULL  -- Not working. Dig in later. (Field leaving blanks not Nulls... Weird.)
group by location
