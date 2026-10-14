SELECT first_name, Last_name, salary
FROM employee_salary
ORDER BY salary DESC;

SELECT first_name, Last_name, age, gender
FROM employee_demographics
WHERE age> 40 AND
gender= 'Female';

SELECT occupation, AVG(salary) AS avg_sal, MAX(salary) MAX_sal, MIN(salary) MIN_sal
FROM employee_salary
GROUP BY occupation;

SELECT Count(employee_id) AS Count_id, occupation
FROM employee_salary
GROUP BY Occupation
HAVING COUNT(employee_id)>1;

SELECT dem.employee_id, dem.first_name, sal.dept_id, dem.age, dept.department_name
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id= sal.employee_id
JOIN parks_departments AS dept
	ON sal.dept_id= dept.department_id
    ;
    
SELECT sal.employee_id, sal.first_name, dem.age
FROM employee_salary AS sal
LEFT JOIN employee_demographics AS dem
ON sal.employee_id=dem.employee_id
;

SELECT *
FROM Employee_salary
WHERE salary > 
	(SELECT AVG(salary)
	FROM employee_salary AS sal)
;

SELECT employee_id, first_name, salary, dept_id,
RANK() OVER (PARTITION BY dept_id order by salary desc)
FROM employee_salary ;



SELECT First_name, Salary,
CASE
	WHEN salary > 70000 THEN 'HIGH'
    WHEN salary >=50000 THEN 'MEDIUM'
    ELSE 'LOW'
END AS 'salary_rank'
FROM employee_salary;

SELECT SUM(salary), dept_id, 
ROUND(SUM(salary)*100/ SUM(SUM(Salary)) OVER (), 1)
FROM employee_salary
GROUP BY dept_id;


WITH dept_totals AS (
SELECT dept_id, SUM(salary) AS dept_total
FROM employee_salary
GROUP BY dept_id
)
SELECT dept_id,
dept_total,
ROUND( dept_total *100/ SUM(dept_total) OVER (), 1)
FROM dept_totals;
