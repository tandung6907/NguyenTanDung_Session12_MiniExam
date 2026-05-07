create database miniexam_ss12;

use miniexam_ss12;

-- 1. Bảng Khoa
CREATE TABLE Department (
    DeptID VARCHAR(5) PRIMARY KEY,
    DeptName VARCHAR(50) NOT NULL
);

-- 2. Bảng SinhVien
CREATE TABLE Student (
    StudentID VARCHAR(6) PRIMARY KEY,
    FullName VARCHAR(50),
    Gender VARCHAR(10),
    BirthDate DATE,
    DeptID VARCHAR(5),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- 3. Bảng MonHoc
CREATE TABLE Course (
    CourseID VARCHAR(6) PRIMARY KEY,
    CourseName VARCHAR(50),
    Credits INT
);

-- 4. Bảng DangKy
CREATE TABLE Enrollment (
    StudentID VARCHAR(6),
    CourseID VARCHAR(6),
    Score DECIMAL(4,2), 
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- Chèn dữ liệu mẫu
INSERT INTO Department VALUES
('IT','Information Technology'),
('BA','Business Administration'),
('ACC','Accounting');

INSERT INTO Student VALUES
('S00001','Nguyen An','Male','2003-05-10','IT'),
('S00002','Tran Binh','Male','2003-06-15','IT'),
('S00003','Le Hoa','Female','2003-08-20','BA'),
('S00004','Pham Minh','Male','2002-12-12','ACC'),
('S00005','Vo Lan','Female','2003-03-01','IT'),
('S00006','Do Hung','Male','2002-11-11','BA'),
('S00007','Nguyen Mai','Female','2003-07-07','ACC'),
('S00008','Tran Phuc','Male','2003-09-09','IT');

INSERT INTO Course (CourseID, CourseName, Credits) VALUES
('CS101', 'Introduction to Programming', 3),
('DB201', 'Database Systems', 4),
('MGT11', 'Principles of Management', 3),
('ACC01', 'Financial Accounting', 3),
('MAT01', 'Advanced Mathematics', 3);

INSERT INTO Enrollment (StudentID, CourseID, Score) VALUES
('S00001', 'CS101', 8.5),
('S00001', 'DB201', 7.0),
('S00002', 'CS101', 9.0),
('S00002', 'MAT01', 6.5),
('S00005', 'CS101', 7.5),
('S00005', 'DB201', 9.5),
('S00008', 'MAT01', 8.0),

('S00003', 'MGT11', 8.0),
('S00003', 'MAT01', 7.5),
('S00006', 'MGT11', 5.5),
('S00006', 'ACC01', 6.0),

('S00004', 'ACC01', 9.0),
('S00004', 'MAT01', 4.5),
('S00007', 'ACC01', 7.0),
('S00007', 'MGT11', 8.5);


-- PHẦN A – CƠ BẢN (4đ)
-- Câu 1: Tạo View ViewStudentBasic hiển thị: StudentID, FullName, và DeptName. Sau đó viết lệnh truy vấn toàn bộ dữ liệu từ View này.
create or replace view v_viewstudentbasic as
select 
	s.StudentID,
    s.FullName,
    d.DeptName
from Student s 
join Department d 	on s.DeptID = d.DeptID;
select * from v_viewstudentbasic;

-- Câu 2: Tạo một Regular Index tên là idxFullName cho cột FullName của bảng Student.
create index regular_idx_fullname on Student (FullName);

-- Câu 3: Viết Stored Procedure GetStudentsIT (không có tham số).
-- Chức năng: Hiển thị toàn bộ sinh viên thuộc khoa "Information Technology" trong bảng Student kết hợp với DeptName từ bảng Department.
-- Yêu cầu: Gọi procedure bằng lệnh CALL để kiểm tra.
delimiter //

create procedure sp_getstudentsIT()
begin
	select
		*
	from v_viewstudentbasic v 
    where v.DeptName = 'Information Technology';
end

// delimiter ;
call sp_getstudentsIT();

--   PHẦN B – KHÁ (3đ)
-- Câu 4:
-- a) Tạo View ViewStudentCountByDept hiển thị: DeptName, TotalStudents (số lượng sinh viên của mỗi khoa).
create or replace view v_viewstudentcountbydept as
select
    v.deptname,
    count(*) as totalstudents
from v_viewstudentbasic v
group by v.deptname;

select * from v_viewstudentcountbydept;

-- b) Từ View trên, viết truy vấn hiển thị khoa có nhiều sinh viên nhất.
select *
from v_viewstudentcountbydept
where totalstudents = (
    select max(totalstudents)
    from v_viewstudentcountbydept
);

-- Câu 5:
-- a) Viết Stored Procedure GetTopScoreStudent với tham số: IN varCourseID VARCHAR(6).
-- Chức năng: Hiển thị sinh viên có điểm cao nhất trong môn học được truyền vào.
delimiter //
create procedure sp_gettopscorestudent(
    in varcourseid varchar(6)
)
begin
    declare topscore decimal(4,2);

    select max(e.score) into topscore
    from enrollment e
    where e.courseid = varcourseid;

    select
        s.studentid,
        s.fullname,
        c.coursename,
        e.score
    from student s
    join enrollment e on s.studentid = e.studentid
    join course c     on e.courseid = c.courseid
    where e.courseid = varcourseid
      and e.score = topscore;
end 

// delimiter ;
-- b) Gọi thủ tục trên để tìm sinh viên có điểm cao nhất môn "Database Systems" (C00001).
call sp_gettopscorestudent('c00001');

-- PHẦN C – GIỎI (3đ)
-- Câu 6: Quản lý việc cập nhật điểm cho môn Database Systems (C00001) theo các quy tắc sau:
-- Chỉ cho phép cập nhật điểm cho sinh viên thuộc khoa IT.
-- Nếu điểm mới truyền vào > 10 → tự động gán lại = 10.
-- Việc cập nhật phải thực hiện thông qua Stored Procedure.
-- Dữ liệu cập nhật phải đảm bảo không vi phạm điều kiện của View.
-- a) Tạo VIEW: Tạo View ViewITEnrollmentDB hiển thị các sinh viên thuộc khoa IT đăng ký môn C00001. View phải có ràng buộc WITH CHECK OPTION.
create or replace view v_viewitenrollmentdb as
select
    s.studentid,
    s.fullname,
    d.deptname,
    e.courseid,
    e.score
from student s
join department d  on s.deptid = d.deptid
join enrollment e  on s.studentid = e.studentid
where d.deptname = 'it'
  and e.courseid = 'c00001'
with check option;

-- b) Viết Stored Procedure: Tạo thủ tục UpdateScoreITDB với các tham số:
-- IN varStudentID VARCHAR(6)
-- INOUT inoutNewScore DECIMAL(4,2)
-- Xử lý: Nếu inoutNewScore > 10 → gán lại = 10. Thực hiện cập nhật điểm thông qua View ViewITEnrollmentDB.
delimiter //
create procedure sp_updatescoreitdb(
    in      varstudentid    varchar(6),
    inout   inoutnewscore   decimal(4,2)
)
begin
    if inoutnewscore > 10 then
        set inoutnewscore = 10;
    end if;

    update v_viewitenrollmentdb
    set score = inoutnewscore
    where studentid = varstudentid;
end 

// delimiter ;

-- c) GỌI THỦ TỤC: Viết lệnh CALL để kiểm tra thủ tục:
-- Khai báo biến session để nhận giá trị INOUT.
-- Gọi thủ tục để cập nhật điểm cho một sinh viên bất kỳ thuộc khoa IT.
-- Sau khi gọi: Hiển thị lại giá trị điểm mới và kiểm tra dữ liệu trong View ViewITEnrollmentDB.
set @newscore = 12.00;
call sp_updatescoreitdb('s00001', @newscore);

select @newscore as diemmoi;
select * from v_viewitenrollmentdb;

