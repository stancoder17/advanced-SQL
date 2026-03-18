-- 1 Write a query for the emp table using CASE that returns the surnames of all employees and an additional column. For employees from department 30 display "sales", for department 10 "accounting", and for others "others".
SELECT ename,
CASE deptno 
	WHEN 30 THEN 'sales'
	WHEN 10 THEN 'accounting'
	ELSE 'others'
END
FROM emp;

-- 2 Write a query using CASE that returns the surnames of all employees and an additional column. For employees from department 30 display "sales"; for department 10 without commission "accounting without commission"; for department 10 with commission "accounting with commission"; otherwise "others".
SELECT ename,
CASE 
	WHEN deptno = 30 THEN 'sales'
	WHEN deptno = 10 AND comm IS NULL THEN 'accounting without commission'
	WHEN deptno = 10 AND comm IS NOT NULL THEN 'accounting with commission'
	ELSE 'others'
END
FROM emp;

-- 3 Create a table new_emp based on emp using SELECT INTO. Then overwrite all salaries and restore them using a correlated UPDATE.
SELECT * INTO nowy_emp FROM emp;

UPDATE nowy_emp SET sal = 0;

UPDATE nowy_emp
SET sal = emp.sal
FROM emp
WHERE nowy_emp.empno = emp.empno;

-- 4 Test the TRUNCATE TABLE statement.
TRUNCATE TABLE nowy_emp;

-- 5 Write a function returning the average salary for a given department and use it in a query.
CREATE FUNCTION dept_average_sal (@deptno INT)
RETURNS NUMERIC(8,2)
AS
BEGIN
    DECLARE @average NUMERIC(8,2);

    SELECT @average = AVG(sal) FROM emp
    WHERE deptno = @deptno;

    RETURN @average;
END;

SELECT * FROM emp
WHERE sal > dbo.dept_average_sal(deptno);

-- 6 Write and test any table-valued function.
CREATE FUNCTION kings_subordinates (@deptno INT)
RETURNS @table TABLE
(
	empno INT,
	ename VARCHAR(50)
)
AS
BEGIN
	INSERT INTO @table (empno, ename)
	SELECT empno, ename FROM emp
	WHERE deptno = @deptno AND mgr = (SELECT empno FROM emp
									  WHERE ename = 'KING')
	RETURN
END;

SELECT * FROM dbo.kings_subordinates(10);

-- 7 Write a procedure that adjusts salaries based on department average using a temporary table and cursor.
CREATE PROCEDURE alter_salaries
AS
BEGIN
    CREATE TABLE #average_salaries (
        deptno INT,
        avg_sal NUMERIC(10,2)
    );

    INSERT INTO #average_salaries (deptno, avg_sal)
    SELECT deptno, AVG(sal)
    FROM emp
    GROUP BY deptno;

    DECLARE @empno INT;
    DECLARE @deptno INT;
    DECLARE @sal INT;
    DECLARE @avg_sal NUMERIC(10,2);

    DECLARE employees CURSOR FOR
    SELECT empno, deptno, sal
    FROM emp;

    OPEN employees;
    FETCH NEXT FROM employees INTO @empno, @deptno, @sal;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @avg_sal = avg_sal FROM #average_salaries WHERE deptno = @deptno;

        IF @sal > @avg_sal
        BEGIN
            UPDATE emp
            SET sal = sal * 0.9
            WHERE empno = @empno;
        END
        ELSE IF @sal < @avg_sal
        BEGIN
            UPDATE emp
            SET sal = sal * 1.1
            WHERE empno = @empno;
        END

        FETCH NEXT FROM employees INTO @empno, @deptno, @sal;
    END; 

    CLOSE employees;
    DEALLOCATE employees;
END;

SELECT * FROM emp;
EXEC dbo.alter_salaries;
SELECT * FROM emp;

-- 8 Using SCROLL CURSOR and RAND, write a procedure that selects a random row from emp.
CREATE OR PROCEDURE get_random_employee
AS
BEGIN
    DECLARE @rowcount INT;
    DECLARE @randomRow INT;

    DECLARE @empno INT;
    DECLARE @ename NVARCHAR(10);
    DECLARE @job NVARCHAR(9);
    DECLARE @mgr INT;
    DECLARE @hiredate DATE;
    DECLARE @sal DECIMAL(10,2);
    DECLARE @comm DECIMAL(10,2);
    DECLARE @deptno INT;

    SELECT @rowcount = COUNT(*) FROM emp;

    SET @randomRow = CEILING(RAND() * @rowcount);

    DECLARE emp_cursor SCROLL CURSOR FOR
        SELECT empno, ename, job, mgr, hiredate, sal, comm, deptno
        FROM emp
        ORDER BY empno;

    OPEN emp_cursor;

    FETCH ABSOLUTE @randomRow 
    FROM emp_cursor 
    INTO @empno, @ename, @job, @mgr, @hiredate, @sal, @comm, @deptno;
	
	PRINT CONCAT(
        'Random employee: ', @empno, ' - ', @ename, 
        ' | Job: ', @job, 
        ' | Manager: ', ISNULL(CAST(@mgr AS NVARCHAR(10)), 'N/A'),
        ' | Hire date: ', CONVERT(NVARCHAR(20), @hiredate, 23),
        ' | Salary: ', @sal,
        ' | Comm: ', ISNULL(CAST(@comm AS NVARCHAR(10)), 'N/A'),
        ' | Dept: ', @deptno
    );

    CLOSE emp_cursor;
    DEALLOCATE emp_cursor;
END;