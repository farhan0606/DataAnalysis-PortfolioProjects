/*

Covid 19 Data Exploration with SQL

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


/*

This project involves exploring two datasets named "CovidDeaths" and "CovidVaccinations" with SQL queries.
These datasets were imported as tables via Excel CSV files into database named "PortfolioProject" 

*/


-- Sneak peak of the CovidDeath table

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL					-- 'Continent' name is also shown as a location in the 'Location' column. Where this occurs, its continent field is NULL
ORDER BY 3, 4								-- Sorting by Location and Date columns



-- Sneak peak of the CovidVaccination table

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent is not NULL					-- 'Continent' name is also shown as a location in the 'Location' column. Where this occurs, its continent field is NULL
ORDER BY 3, 4								-- Sorting by Location and Date columns



-- Selecting data that we are going to use further

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY location, date



-- Total Cases vs Total Population
-- Calculates percentage of population infected with COVID-19 virus for any given country

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent is not NULL
ORDER BY location, date



-- Total cases vs Total deaths
-- Calculates percentage of death due to COVID-19 for any given country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent is not NULL
ORDER BY location, date



-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc



-- Countries with Highest Death Count per Population

SELECT location, population, MAX(CAST (total_deaths as int)) as TotalDeathCount,  MAX(((cast(total_deaths as int))/population))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL   
GROUP BY location
ORDER BY TotalDeathCount desc




-- LETS BREAK THINGS DOWN BY CONTINENTS

-- Showing contintents with the highest death count per population

SELECT continent, MAX(CAST (total_deaths as int)) as TotalDeathCount,  MAX(((cast(total_deaths as int))/population))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL   
GROUP BY continent
ORDER BY TotalDeathCount desc




-- CALCULATING GLOBAL NUMBERS
-- Calculating world-wide total cases, total deaths and death percentage

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null



-- Total Vaccinations vs Total Population
-- Shows number of people for each country who have taken COVID-19 vaccine
-- CovidDeaths table combined with CovidVaccinations table using INNER JOIN


SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(Convert(bigint, cv.new_vaccinations))  OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd				-- Alaising 'CovidDeath' table as 'cd'
Join PortfolioProject..CovidVaccinations cv			-- Alaising 'CovidVaccinations' table as 'cv'	
on cd.date = cv.date
and cd.location = cv.location
WHERE cd.continent is not null



-- Using CTE for performing further calculations on PARTITION BY in the previous query
-- Shows percentage of population vaccinated along with the total number of vaccinations carried out.

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) as 
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(Convert(bigint, cv.new_vaccinations))  OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
on cd.date = cv.date
and cd.location = cv.location
WHERE cd.continent is not null
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as Percent_Vaccinated
FROM PopvsVac



-- Using TEMP table for performing further calculations on PARTITION BY in the previous query
-- Shows percentage of population vaccinated along with the total number of vaccinations carried out.

DROP TABLE IF EXISTS #PopulationVaccinatedPercentage
CREATE TABLE #PopulationVaccinatedPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PopulationVaccinatedPercentage
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(Convert(bigint, cv.new_vaccinations))  OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
on cd.date = cv.date
and cd.location = cv.location
WHERE cd.continent is not null
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as Percent_Vaccinated
FROM #PopulationVaccinatedPercentage



-- Creating a view to store data for using it later for visualization

Create View PopulationVaccinatedPercentage as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(Convert(bigint, cv.new_vaccinations))  OVER (Partition by cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccinations cv
on cd.date = cv.date
and cd.location = cv.location
WHERE cd.continent is not null
