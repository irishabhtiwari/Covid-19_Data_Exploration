/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/



SELECT *
FROM   portfolioproject..coviddeath
WHERE  continent IS NOT NULL
ORDER  BY location, date;


-- Select Data that we are going to be starting with



SELECT location,date, total_cases, new_cases, total_deaths, population
FROM   portfolioproject..coviddeath
WHERE  continent IS NOT NULL
ORDER  BY location, date ;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in India



SELECT location, date, total_cases, total_deaths,
       ( total_deaths / total_cases ) * 100 AS DeathPercentage
FROM   portfolioproject..coviddeath
WHERE  location LIKE 'India' AND continent IS NOT NULL
ORDER  BY location, date; 



-- Total Cases Vs Population
-- Shows what percentage of population infected with Covid



SELECT location,date,
       total_cases,
       population,
       ( total_cases / population ) * 100 AS DeathPercentage
FROM   portfolioproject..coviddeath
-- where location like 'India'
ORDER  BY location,date; 



-- Countries with Highest Infection Rate compared to Population



SELECT location,population,
       Max(total_cases)                    AS HighestInfectionCount,
       Max(total_cases / population) * 100 AS PercentagePopulationInfected
FROM   portfolioproject..coviddeath
WHERE  continent IS NOT NULL
-- where location like 'India'
GROUP  BY location,population
ORDER  BY percentagepopulationinfected DESC; 



-- Countries with Highest Death Count per Population



SELECT location,
       Max(Cast(total_deaths AS INT)) AS TotaldeathCount
FROM   portfolioproject..coviddeath
WHERE  continent IS NOT NULL
-- where location like 'India'
GROUP  BY location
ORDER  BY totaldeathcount DESC;



--- Breaking Things By Continent

-- Showing continents with highest death count per population



SELECT continent,
       Max(Cast(total_deaths AS INT)) AS TotaldeathCount
FROM   portfolioproject..coviddeath
WHERE  continent IS NOT NULL
-- where location like 'India'
GROUP  BY continent
ORDER  BY totaldeathcount DESC; 



--  GLOBAL NUMBERS



SELECT Sum(new_cases)                                      AS total_cases,
       Sum(Cast(new_deaths AS INT))                        AS total_deaths,
       Sum(Cast(new_deaths AS INT)) / Sum(new_cases) * 100 AS DeathPercentage
FROM   portfolioproject..coviddeath
--Where location like 'India'
WHERE  continent IS NOT NULL
-- Group By date
ORDER  BY total_cases,
          total_deaths 



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine



SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       Sum(CONVERT(BIGINT, vac.new_vaccinations))
         OVER (
           partition BY dea.location
           ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM   portfolioproject..coviddeath dea
       JOIN portfolioproject..covidvaccination vac
         ON dea.location = vac.location
            AND dea.date = vac.date
WHERE  dea.continent IS NOT NULL
ORDER  BY dea.location,
          dea.date 



-- Using CTE to perform Calculation on Partition By in previous query



WITH popvsvac (continent, location, date, population, new_vaccinations,
     rollingpeoplevaccinated
     )
     AS (SELECT dea.continent,
                dea.location,
                dea.date,
                dea.population,
                vac.new_vaccinations,
                Sum(CONVERT(BIGINT, vac.new_vaccinations))
                  OVER (
                    partition BY dea.location
                    ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
         --, (RollingPeopleVaccinated/population)*100
         FROM   portfolioproject..coviddeath dea
                JOIN portfolioproject..covidvaccination vac
                  ON dea.location = vac.location
                     AND dea.date = vac.date
         WHERE  dea.continent IS NOT NULL
        --order by dea.location,dea.date
        )
SELECT *,
       ( rollingpeoplevaccinated / population ) * 100
FROM   popvsvac 



-- Using Temp Table to perform Calculation on Partition By in previous query



DROP TABLE IF EXISTS #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
             (
                          continent               nvarchar(255),
                          location                nvarchar(255),
                                                  date datetime,
                          population              numeric,
                          new_vaccinations        numeric,
                          rollingpeoplevaccinated numeric
             )INSERT INTO #percentpopulationvaccinated
SELECT   dea.continent,
         dea.location,
         dea.date,
         dea.population,
         vac.new_vaccinations ,
         Sum(CONVERT(BIGINT,vac.new_vaccinations)) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
         --, (RollingPeopleVaccinated/population)*100
FROM     portfolioproject..coviddeath dea
JOIN     portfolioproject..covidvaccination vac
ON       dea.location = vac.location
AND      dea.date = vac.date
--where dea.continent is not null
--order by dea.location,dea.date

SELECT *,
       (rollingpeoplevaccinated/population)*100
FROM   #percentpopulationvaccinated



-- Creating View to store data for later visualizations



CREATE VIEW PercentPopulationVaccinated AS
  SELECT dea.continent,
         dea.location,
         dea.date,
         dea.population,
         vac.new_vaccinations,
         Sum(CONVERT(INT, vac.new_vaccinations))
           OVER (
             partition BY dea.location
             ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/population)*100
  FROM   portfolioproject..coviddeath dea
         JOIN portfolioproject..covidvaccination vac
           ON dea.location = vac.location
              AND dea.date = vac.date
  WHERE  dea.continent IS NOT NULL