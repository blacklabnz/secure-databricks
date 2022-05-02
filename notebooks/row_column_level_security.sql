-- Databricks notebook source
create database employee

-- COMMAND ----------

CREATE TABLE employee.salary (
  id INT,
  firstName STRING,
  lastName STRING,
  gender STRING,
  position STRING,
  location STRING,
  salary INT,
  viewable_by STRING
) USING DELTA

-- COMMAND ----------

-- MAGIC %sql
-- MAGIC INSERT INTO employee.salary VALUES
-- MAGIC   (1, 'Billy', 'Tommie', 'M', 'staff', 'NZ', 55250, 'manager'),
-- MAGIC   (2, 'Judie', 'Williams', 'F', 'manager', 'NZ', 65250, 'snrmgmt'),
-- MAGIC   (3, 'Tom', 'Cruise', 'M', 'staff', 'USA', 75250, 'manager'),
-- MAGIC   (4, 'May', 'Thompson', 'F', 'manager', 'USA', 85250, 'snrmgmt'),
-- MAGIC   (5, 'David', 'Wang', 'M', 'staff', 'AUSSIE', 95250, 'manager'),
-- MAGIC   (6, 'Sammie', 'Willies', 'F', 'staff', 'AUSSIE', 105250, 'manager'),
-- MAGIC   (7, 'Jianguo', 'Liu', 'M', 'staff', 'CHINA', 115250, 'manager'),
-- MAGIC   (8, 'li', 'Wu', 'F', 'cto', 'CHINA', 125250, 'finance')

-- COMMAND ----------

INSERT INTO test.salary VALUES
  (9, 'Mary', 'Jeans', 'F', 'technician', 'NZ', 1234, 'manager')

-- COMMAND ----------

SELECT is_member('abc') as group 

-- COMMAND ----------

CREATE GROUP finance;
CREATE GROUP manager;
CREATE GROUP snrmgmt;

-- COMMAND ----------

ALTER GROUP finance ADD USER `neil.xu@lab3nz.co.nz`;
-- ALTER GROUP finance ADD USER ;

-- COMMAND ----------

CREATE or replace VIEW employee.staff_salary_vw AS
select 
*
FROM employee.salary s
WHERE is_member(viewable_by) or current_user() = CONCAT(s.firstName, '.', s.lastName, '@lab3nz.co.nz')

-- COMMAND ----------

select * from employee.staff_salary_vw;
