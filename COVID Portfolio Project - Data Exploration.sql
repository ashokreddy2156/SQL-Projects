
/*
	Covid19 Data Exploration

	Skills Used : Joins, CTE's, Temp Tables, Windows Functions ,Aggregate Functions, Creating Views, Converting Data Types
	
*/

Create database covid
use covid

-- Import data from the Excel sheets containing information on COVID deaths and COVID vaccinations into the COVID database.

-- Displaying the data from the CovidDeaths table.

SELECT 
* FROM dbo.CovidDeaths
ORDER BY location,date


-- Displaying the data from the  CovidVaccinations

SELECT *
FROM dbo.CovidVaccinations
ORDER BY location,date



-- Choose the data with which we will commence.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2



-- Total Cases Vs Total Deaths 
-- Indicates the probability of mortality upon contracting COVID-19 in your respective country.

SELECT location, date, total_deaths, total_cases, (total_deaths/total_cases)*100 as Death_Persentage
FROM dbo.CovidDeaths
WHERE continent is not null and location = 'india'
ORDER BY location, date



-- Total Cases Vs Total Population
-- Indicates the proportion of individuals afflicted with COVID-19. 

SELECT location, date, total_cases,population, (total_cases/Population) as PopulationInfectedPercentage
FROM dbo.CovidDeaths
WHERE continent is not null and location = 'india'
ORDER BY 1,2

-- Comparison of infection rates in countries relative to their populations with the highest incidence.

SELECT location,Population, max(total_cases) as HighestInfection, round(max(total_cases/Population),5) as InfectionPercentage
FROM  CovidDeaths
GROUP BY location,population
ORDER BY population DESC


-- Countries exhibiting the highest death count per capita.

SELECT location, max(cast(Total_Deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Breaking Things Down by Continent
-- Displaying the continent with the highest mortality rate.

SELECT continent , max(cast(Total_Deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY  continent
ORDER BY TotalDeathCount DESC


-- Displaying the highest death count based on continent and location.

SELECT continent ,location, max(cast(Total_Deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent, location
ORDER BY TotalDeathCount desc



-- Global Numbers

SELECT	SUM(new_cases) as total_cases,SUM(CAST(new_deaths as int)) as TotalDeaths,
round(SUM(CAST(new_Deaths as int ))/sum(new_cases) * 100,6) as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2



-- Total Population Vs Total Vaccinations
-- Displaying the percentage of the population that has received at least one COVID-19 vaccine.
-- using Joins Concept

SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
( vac.new_vaccinations/dea.population) * 100 as VaccinationPercentage
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND		DEA.date = vac.date
WHERE dea.continent is not null 
ORDER BY  1,2,3



-- Total Population Vs Tota l Vaccinations By Locations Rolling Count 
-- Using Windows Function and Joins 

SELECT dea.continent, dea.location, dea. population, dea.date, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) over ( PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingVacci_Count,
(vac.new_vaccinations/dea.population) * 100 as VaccinationRate
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	on dea.location = vac.location
	AND dea.date = vac.date
WHERE DEA.continent is not null 
ORDER BY	1,2,3



-- Utilizing Common Table Expressions (CTE) to execute calculations on partitions based on the preceding query.
 
WITH PopVsVacci (Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinated)
AS (
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	on dea.location = vac.location
	AND dea.date = vac.date
WHERE	dea.continent is not null

)
SELECT *, (RollingPeopleVaccinated/Population) * 100 as VacRate_TillDate
FROM PopVsVacci




-- Using Temp Table to Perform CalCulation On Partition By In Previous Query

Drop Table if exists VaccinationPercentage
CREATE TABLE VaccinationPercentage
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
INSERT INTO VaccinationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.New_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date ) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	on dea.location = vac.location
	AND dea.date = vac.date

SELECT *,(RollingPeopleVaccinated/Population) * 100 as Vaccination_Till_Date
FROM VaccinationPercentage

-- Creating View to Store data 

CREATE VIEW VaccinationTillDate AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations
    ,SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated

From 
	CovidDeaths dea
JOIN 
	CovidVaccinations vac 
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 

SELECT * FROM VaccinationTillDate

