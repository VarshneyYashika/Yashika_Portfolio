/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

/*
Covid 19 Data downloaded from ourworldindata.org in csv format.
Table cdeath contains all the details of covid death data across different countries
and table cvaccine contains details of covid vaccinations. */



-- Creating tables and importing data from csv files

CREATE TABLE cdeaths(
    iso_code VARCHAR(100),
    continent VARCHAR(100),	
    location1 VARCHAR(100),	
    date1	DATE,
    population BIGINT,
    total_cases BIGINT,
    new_cases BIGINT,
    new_cases_smoothed FLOAT8,
    total_deaths BIGINT,
    new_deaths BIGINT,
    new_deaths_smoothed FLOAT8,
    total_cases_per_million FLOAT8,
    new_cases_per_million FLOAT8,
    new_cases_smoothed_per_million FLOAT8,
    total_deaths_per_million FLOAT8,
    new_deaths_per_million FLOAT8,
    new_deaths_smoothed_per_million FLOAT8,
    reproduction_rate FLOAT8,
    icu_patients BIGINT,	
    icu_patients_per_million FLOAT8,
    hosp_patients BIGINT,
    hosp_patients_per_million FLOAT8,
    weekly_icu_admissions BIGINT,
    weekly_icu_admissions_per_million FLOAT8,
    weekly_hosp_admissions BIGINT,
    weekly_hosp_admissions_per_million FLOAT8
);

COPY cdeaths FROM 'C:\Users\Public\CD.csv' DELIMITER ',' CSV;

CREATE TABLE cvaccine
(iso_code VARCHAR(100),	
 continent VARCHAR(100),	
 location1 VARCHAR(100),	
 date1	DATE,
 total_tests BIGINT,
 new_tests BIGINT,
 total_tests_per_thousand FLOAT8,
 new_tests_per_thousand FLOAT8,
 new_tests_smoothed FLOAT8,
 new_tests_smoothed_per_thousand FLOAT8,
 positive_rate FLOAT8,
 tests_per_case FLOAT8,
 tests_units VARCHAR(150),
 total_vaccinations BIGINT,
 people_vaccinated BIGINT,	
 people_fully_vaccinated BIGINT,	
 total_boosters BIGINT,	
 new_vaccinations BIGINT,
 new_vaccinations_smoothed	FLOAT8,
 total_vaccinations_per_hundred	FLOAT8, 
 people_vaccinated_per_hundred FLOAT8,
 people_fully_vaccinated_per_hundred FLOAT8,
 total_boosters_per_hundred FLOAT8,
 new_vaccinations_smoothed_per_million FLOAT8,
 new_people_vaccinated_smoothed FLOAT8,
 new_people_vaccinated_smoothed_per_hundred	FLOAT8,
 stringency_index FLOAT8,
 population_density FLOAT8,
 median_age FLOAT8,	
 aged_65_older FLOAT8,	
 aged_70_older FLOAT8,	
 gdp_per_capita FLOAT8,
 extreme_poverty FLOAT8,
 cardiovasc_death_rate FLOAT8,	
 diabetes_prevalence FLOAT8,
 female_smokers FLOAT8,
 male_smokers FLOAT8,
 handwashing_facilities FLOAT8,
 hospital_beds_per_thousand FLOAT8,
 life_expectancy FLOAT8,
 human_development_index FLOAT8,
 excess_mortality_cumulative_absolute  FLOAT8,
 excess_mortality_cumulative FLOAT8,
 excess_mortality FLOAT8,
 excess_mortality_cumulative_per_million FLOAT8
 );

COPY cvaccine FROM 'C:\Users\Public\CV.csv' DELIMITER ',' CSV;


-- Having a look at the tables created

SELECT * FROM cdeaths LIMIT 10;
SELECT * FROM cvaccine LIMIT 10;

--Understanding the width and scope of the data

SELECT COUNT(*) FROM cdeaths;
SELECT COUNT(*) FROM cvaccine;


SELECT DISTINCT(continent) FROM cdeaths;
SELECT COUNT(*), location1  FROM cdeaths
WHERE continent IS NULL
GROUP BY location1;
SELECT COUNT(*)
FROM cdeaths
WHERE continent IS NULL;

/* Some entries have null continent and 
the location for null continent is mostly the name of the continent or arbitary word
The count of such entries is low as compared total number of entries.
So, these entries will not ignored for most calculations and statistics.
*/



-- DATA EXPLORATION

SELECT * FROM cdeaths 
WHERE continent IS NOT NULL
ORDER BY 3,4;


SELECT location1, date1, total_cases, new_cases, total_deaths, population
FROM cdeaths
WHERE continent IS NOT null 
ORDER BY 1,2;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in India

SELECT location1, date1, total_cases,total_deaths,(CAST(total_deaths as FLOAT)/CAST(total_cases as FLOAT))*100 as DeathPercentage
FROM cdeaths
WHERE location1 ILIKE 'India' AND continent IS NOT NULL
ORDER BY 1,2;

--INFERENCE: Death Percentage shows overall decreasing trend with time in India
--INFERENCE: As of 08 May,2022, likelyhood of dying if you contract covid is 1.19% in India



-- Total Cases vs Population
-- Shows percentage of population infected with Covid in India

SELECT location1, date1, Population, total_cases,  (CAST (total_cases as FLOAT)/CAST(population as FLOAT))*100 as PercentPopulationInfected
FROM cdeaths
WHERE location1 ILIKE 'India'
ORDER BY 1,2;
 
--INFERENCE: As of 08 May, 2022, aorund 3% of the population is covid infected in India



-- Countries with Highest Infection Rate compared to Population

SELECT  location1, population, MAX(total_cases) as HighestInfectionCount,  Max((CAST(total_cases as FLOAT)/CAST(population as FLOAT))*100) as PercentPopulationInfected
FROM cdeaths
GROUP BY location1, Population
ORDER BY PercentPopulationInfected DESC;

--INFERENCE: According to data, Faeroe Islands reached the maximum Infection rate of 65.5% 
--and North Korea never crossed the infection rate of 3.85%  in the span of the last 3 years



-- Countries with Highest Death Count per Population

SELECT location1, MAX(Total_deaths) as TotalDeathCount
FROM cdeaths
WHERE continent IS NOT NULL 
GROUP BY location1
ORDER BY TotalDeathCount DESC;

-- INFERENCE: United States has the highest death count in covid-19



-- BREAKING THINGS DOWN BY CONTINENT


-- Showing contintents with the highest death count per population

SELECT continent, MAX(Total_deaths) as TotalDeathCount
FROM cdeaths
WHERE continent IS NOT null 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--INFERENCE: North America has the highest and Oceania has the lowest death count



-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(New_Cases))*100 as DeathPercentage
FROM cdeaths
WHERE continent IS NOT null 
ORDER BY 1,2;



-- Total Population vs Vaccinations
-- Shows rolling sum of the number of new vaccination by date and location

SELECT dea.continent, dea.location1, dea.date1, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location1 ORDER BY dea.location1, dea.Date1) AS RollingPeopleVaccinated
FROM cdeaths dea
JOIN cvaccine vac
	ON dea.location1 = vac.location1
	AND dea.date1 = vac.date1
WHERE dea.continent IS NOT null 
ORDER BY 2,3;



-- Using CTE to perform Calculation on Partition By in previous query
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

WITH PopvsVac (Continent, location1, Date1, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location1, dea.date1, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location1 ORDER BY dea.location1, dea.Date1) AS RollingPeopleVaccinated
FROM cdeaths dea
JOIN cvaccine vac
	ON dea.location1 = vac.location1
	AND dea.date1 = vac.date1
WHERE dea.continent IS NOT null 
ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingVaccinationPercentage
FROM PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(
Continent VARCHAR(255),
Location VARCHAR (255),
Date1 DATE,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location1, dea.date1, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location1 ORDER BY dea.location1, dea.Date1) AS RollingPeopleVaccinated
FROM cdeaths dea
JOIN cvaccine vac
	ON dea.location1 = vac.location1
	AND dea.date1 = vac.date1
WHERE dea.continent IS NOT null 
ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingVaccinationPercentage
FROM PercentPopulationVaccinated;



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location1, dea.date1, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location1 ORDER BY dea.location1, dea.Date1) AS RollingPeopleVaccinated
FROM cdeaths dea
JOIN cvaccine vac
	ON dea.location1 = vac.location1
	AND dea.date1 = vac.date1
WHERE dea.continent IS NOT null 
ORDER BY 2,3;




