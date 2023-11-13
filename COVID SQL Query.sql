--Exploratory Data Analysis on the Covid Dataset
--Data as of 10/20


SELECT * 
FROM DataAnalysis..CovidDeaths
Order by 3, 4

SELECT * FROM DataAnalysis..CovidVaccinations
order by 3,4 



-- Total Cases vs Total Deaths

-- What percentage of total population has died from COVID
SELECT SUM(CAST(new_cases as int)) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, (SUM(CAST(total_deaths as numeric))/SUM(CAST(total_cases as numeric)))*100 as DeathPercentage
FROM DataAnalysis..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 


-- Likelihood of Dying when contracting Covid in US
SELECT location, date, total_cases, new_cases, total_deaths, (CAST(total_deaths as numeric)/total_cases)*100 as DeathPercentage
FROM DataAnalysis..CovidDeaths
WHERE total_cases IS NOT NULL AND location like '%states%'
ORDER BY 1,2 


--Total cases vs population
--What percentage of the population in the US got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as CasesPopulation
FROM DataAnalysis..CovidDeaths
WHERE total_cases IS NOT NULL AND location like '%states%'
ORDER BY 1,2 

-- Which country has the highest infection rate
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as CasesPopulation
FROM DataAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY population, location
ORDER BY CasesPopulation desc

-- Which country has the highest death rate
SELECT location, population, MAX(CAST(total_deaths as numeric)) as TotalDeathCount, (MAX(CAST(total_deaths as numeric)/population)) as DeathPercentage
FROM DataAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Deaths by country
SELECT location, MAX(CAST(total_deaths as numeric)) as TotalDeathCount
FROM DataAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc




--Deaths by continent
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM DataAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, COALESCE(SUM(new_deaths)/NULLIF(SUM(new_cases),0),0)*100 as DeathPercentage
FROM DataAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 

--Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition By dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as running_people_vaccinated
FROM DataAnalysis..CovidDeaths dea
JOIN DataAnalysis..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE population IS NOT NULL AND dea.continent IS NOT NULL
ORDER BY 2,3


--CTE for percentage
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, running_people_vaccinated) as (

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition By dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as running_people_vaccinated
FROM DataAnalysis..CovidDeaths dea
JOIN DataAnalysis..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

)
SELECT *, (running_people_vaccinated/Population)*100 as running_percentage_vaccinated
FROM PopvsVac


-- TEMP TABLE for percentage

DROP TABLE IF Exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric 
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition By dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as running_people_vaccinated
FROM DataAnalysis..CovidDeaths dea
JOIN DataAnalysis..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 as running_percentage_vaccinated
FROM #PercentPopulationVaccinated




-- Creating View to store for data visualizations
USE DataAnalysis
GO
CREATE VIEW PercentPopVac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition By dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) as running_people_vaccinated
FROM DataAnalysis..CovidDeaths dea
JOIN DataAnalysis..CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * FROM PercentPopVac