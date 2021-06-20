--SELECT *
--FROM coviddeaths
--ORDER BY 3,4;

--SELECT *
--FROM covidvaccinations
--ORDER BY 3,4

--SELECT location, date,total_cases, new_cases, total_deaths, population
--FROM coviddeaths
--ORDER BY 1,2

--To show likelihood that you will die in your country
SELECT location, date,total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM coviddeaths
WHERE location LIKE '%India%'
ORDER BY 1,2;

--Looking at Cases v/s Population
SELECT location, date,total_cases, population, (total_cases/population)*100 AS death_percentage
FROM coviddeaths
WHERE location LIKE '%India%'
ORDER BY 1,2


--Looking at countries compared to highest infection rate
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 
AS percent_population_infected
FROM coviddeaths
--WHERE location LIKE '%India%'
GROUP BY location, population
ORDER BY percent_population_infected DESC


--Looking at countries with highest date count per population
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM coviddeaths
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--Looking at continets
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM coviddeaths
--WHERE location LIKE '%India%'
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

 --Showing continents with highest death count per population
 SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM coviddeaths
--WHERE location LIKE '%India%'
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

--Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(cast (new_deaths as INT)) AS total_deaths, SUM( cast(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(cast (new_deaths as INT)) AS total_deaths, SUM( cast(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3


-- CTE 
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

)
SELECT *, (rolling_people_vaccinated/population)*100
FROM pop_vs_vac

--Temp Table
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #percent_population_vaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100
FROM #percent_population_vaccinated


-- Creating View to store data  for later visualization

CREATE VIEW percent_population_vaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) 
AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *
FROM percent_population_vaccinated