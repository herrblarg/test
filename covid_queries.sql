select *
from covid_project..covid_deaths
order by 3, 4

select *
from covid_project..covid_deaths
where continent is not null
order by 3, 4

select *
from covid_project..covid_vax
order by 3, 4

 -- selects the data we're using

 select Location, date, total_cases, new_cases, total_deaths, population
 FROM covid_project..covid_deaths
 where continent is not null
 order by 1,2
 
 
 -- Looking at Total Cases vs Total Deaths
 --overall
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As 'Death %'
FROM covid_project..covid_deaths
where continent is not null
order by 1,2

-- in the US
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As 'Death %'
FROM covid_project..covid_deaths
where location like '%states%' and continent is not null
order by 1,2


-- looking at Total Cases vs Population
-- Shows what % population got covid
select Location, date, population, total_cases, (total_cases/population)*100 As '% population infected'
FROM covid_project..covid_deaths
where location like '%states%' and continent is not null
order by 1,2


-- Looking at infection rates, compared to population
select Location, population, MAX(total_cases) as 'Highest_Infection _Count', MAX((total_cases/population))*100 As '%_population_infected'
FROM covid_project..covid_deaths
group by location, population
order by 1,2

--Looking at countries with highest infection rate, compared to population
select Location, population, MAX(total_cases) as 'Highest_Infection _Count', MAX((total_cases/population))*100 As percent_population_infected
FROM covid_project..covid_deaths
group by location, population
order by percent_population_infected desc

-- Showing countries with highest death count per population
select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM covid_project..covid_deaths
where continent is not null
group by location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid_project..covid_deaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid_project..covid_deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_project..covid_deaths dea
Join covid_project..covid_vax vac	
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3




-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_project..covid_deaths dea
Join covid_project..covid_vax vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_project..covid_deaths dea
Join covid_project..covid_vax vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_project..covid_deaths dea
Join covid_project..covid_vax vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 