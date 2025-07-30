-- Table Admins
CREATE TABLE Admins (
    AdminID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL UNIQUE,
    [Password] NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    [Status] NVARCHAR(20) DEFAULT 'Active' CHECK ([Status] IN ('Active', 'Inactive', 'Suspended', 'Locked')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table Users (Patient, Doctor, Nurse, Receptionist)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL UNIQUE,
    [Password] NVARCHAR(255) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    FullName NVARCHAR(100),
    Dob DATE,
    Gender NVARCHAR(20) CHECK (Gender IN ('Male', 'Female', 'Other')),
    Phone NVARCHAR(15) UNIQUE,
    [Address] NVARCHAR(255),
    MedicalHistory TEXT,
    Specialization NVARCHAR(100),
    [Role] NVARCHAR(20) NOT NULL CHECK ([Role] IN ('Patient', 'Doctor', 'Nurse', 'Receptionist')),
    [Status] NVARCHAR(20) DEFAULT 'Active' CHECK ([Status] IN ('Active', 'Inactive', 'Suspended', 'Locked')),
    CreatedBy INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID)
);

-- Table Services
CREATE TABLE [Services] (
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    ServiceName NVARCHAR(100) NOT NULL,
    [Description] TEXT,
    Price DECIMAL(10, 2) NOT NULL,
    [Status] NVARCHAR(20) DEFAULT 'Active' CHECK ([Status] IN ('Active', 'Inactive', 'Discontinued')),
    CreatedBy INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID)
);

-- Table Rooms
CREATE TABLE Rooms (
    RoomID INT PRIMARY KEY IDENTITY(1,1),
    RoomName NVARCHAR(50) NOT NULL UNIQUE,
    [Description] TEXT,
    DoctorID INT NULL, -- Bác sĩ chính của phòng (có thể thay đổi)
    NurseID INT NULL, -- Y tá chính của phòng (có thể thay đổi)
    [Status] NVARCHAR(20) DEFAULT 'Available' CHECK ([Status] IN ('Available', 'Not Available', 'In Progress', 'Completed')),
    CreatedBy INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (DoctorID) REFERENCES Users(UserID),
    FOREIGN KEY (NurseID) REFERENCES Users(UserID),
    FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID)
);

-- Table ScheduleEmployee (Lịch làm việc của nhân viên)
CREATE TABLE ScheduleEmployee (
    SlotID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL, -- ID của nhân viên (Doctor, Nurse, Receptionist)
	PatientID int ,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Doctor', 'Nurse', 'Receptionist')), -- Vai trò của nhân viên trong lịch này
    RoomID INT NULL, -- ID phòng làm việc trong slot này (có thể NULL nếu không cần phòng cụ thể)
    SlotDate DATE NOT NULL, -- Ngày làm việc
    StartTime DATETIME NOT NULL, -- Giờ bắt đầu
    EndTime DATETIME NOT NULL, -- Giờ kết thúc
    [Status] NVARCHAR(20) DEFAULT 'Available' CHECK ([Status] IN ('Available', 'Booked', 'Completed', 'Cancelled')), -- Trạng thái của slot
    CreatedBy INT NOT NULL, -- ID người tạo lịch (thường là Admin)
    CreatedAt DATETIME DEFAULT GETDATE(), -- Thời gian tạo
    UpdatedAt DATETIME DEFAULT GETDATE(), -- Thời gian cập nhật
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
    FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID),
	FOREIGN KEY (PatientID) REFERENCES Users(UserID),
);

-- Table Appointments (Lịch hẹn khám bệnh - Đã loại bỏ NurseID và ReceptionistID, thêm SlotID và ServiceID)
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT,
    DoctorID INT NOT NULL,
    RoomID INT NOT NULL,
    SlotID INT NOT NULL, -- Thêm SlotID để liên kết với ScheduleEmployee
    ServiceID INT NOT NULL, -- Thêm ServiceID để liên kết với Services
    AppointmentTime DATETIME NOT NULL,
    [Status] NVARCHAR(20) DEFAULT 'Pending' CHECK ([Status] IN ('Pending', 'Approved', 'Rejected')),
    CreatedBy INT NULL, -- Có thể là Admin hoặc Patient tự tạo
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
   
    FOREIGN KEY (PatientID) REFERENCES Users(UserID),
    FOREIGN KEY (DoctorID) REFERENCES Users(UserID),
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
    FOREIGN KEY (SlotID) REFERENCES ScheduleEmployee(SlotID),
);

-- Table ExaminationResults (Kết quả khám bệnh)
CREATE TABLE ExaminationResults (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    AppointmentID INT NOT NULL,
    DoctorID INT NOT NULL,
    PatientID INT NOT NULL,
    NurseID INT NOT NULL, -- Y tá tham gia (nếu có)
    ServiceID INT NOT NULL, -- Dịch vụ được thực hiện trong lần khám này
    [Status] NVARCHAR(20) DEFAULT 'Pending' CHECK ([Status] IN ('Pending', 'Draft', 'Completed', 'Reviewed', 'Cancelled')),
	Diagnosis NVARCHAR(MAX),
    Notes NVARCHAR(MAX),
    CreateBy int,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID),
    FOREIGN KEY (DoctorID) REFERENCES Users(UserID),
    FOREIGN KEY (PatientID) REFERENCES Users(UserID),
    FOREIGN KEY (NurseID) REFERENCES Users(UserID),
	FOREIGN KEY (CreateBy) REFERENCES Users(UserID),
	
);

-- Table Prescriptions (Đơn thuốc)
CREATE TABLE Prescriptions (
    PrescriptionID INT PRIMARY KEY IDENTITY(1,1),
	 NurseID INT,
    ResultID INT, -- Liên kết với kết quả khám
	 [Signature] NVARCHAR(200),
	 [Instruct] NVARCHAR(200),
	 Quantity NVARCHAR(200),
    DoctorID INT,
    PatientID INT,
	AppointmentID int,
    [Status] NVARCHAR(20) DEFAULT 'Pending' CHECK ([Status] IN ('Pending', 'In Progress', 'Completed', 'Dispensed', 'Cancelled')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ResultID) REFERENCES ExaminationResults(ResultID),
    FOREIGN KEY (DoctorID) REFERENCES Users(UserID),
    FOREIGN KEY (PatientID) REFERENCES Users(UserID),
	FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID),
	 FOREIGN KEY (NurseID) REFERENCES Users(UserID)
);

-- Table Medications (Thuốc)
CREATE TABLE Medications (
    MedicationID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL, -- Tên thuốc
    dosage NVARCHAR(100) NOT NULL, -- Liều dùng
    manufacturer NVARCHAR(255) NOT NULL, -- Nhà sản xuất
    description NVARCHAR(MAX), -- Mô tả
    status NVARCHAR(50) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Out of Stock')), -- Trạng thái
    dosage_form NVARCHAR(100) NOT NULL CHECK (dosage_form IN ('Tablet', 'Liquid', 'Capsule', 'Injection', 'Syrup', 'Powder', 'Cream', 'Ointment')), -- Dạng bào chế
    CONSTRAINT check_dates CHECK (expiration_date > production_date),
    CONSTRAINT check_positive_price CHECK (price >= 0),
    CONSTRAINT check_positive_quantity CHECK (quantity >= 0)
);

-- Tạo index để tìm kiếm nhanh
CREATE INDEX IX_Medications_Name ON Medications(name);

-- Table Invoices (Hóa đơn)
CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY IDENTITY(1,1),
	ResultID int,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    [Status] NVARCHAR(20) DEFAULT 'Pending' CHECK ([Status] IN ('Pending', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled', 'Refunded')),
    CreatedBy INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(), 
	FOREIGN KEY (ResultID) REFERENCES ExaminationResults(ResultID),
    FOREIGN KEY (PatientID) REFERENCES Users(UserID),
    FOREIGN KEY (DoctorID) REFERENCES Users(UserID),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserID),
);

-- Table RoomServices (Dịch vụ có sẵn trong phòng)
CREATE TABLE RoomServices (
    RoomServiceID INT PRIMARY KEY IDENTITY(1,1),
    RoomID INT NOT NULL,
    ServiceID INT NOT NULL,
    CreatedBy INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
    FOREIGN KEY (ServiceID) REFERENCES [Services](ServiceID),
    FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID),
    UNIQUE (RoomID, ServiceID)
);

-- Table Notifications (Thông báo)
CREATE TABLE Notifications (
    NotificationID INT PRIMARY KEY IDENTITY(1,1),
    SenderID INT NOT NULL,
    SenderRole NVARCHAR(20) NOT NULL CHECK (SenderRole IN ('Admin', 'Doctor', 'Nurse', 'Receptionist', 'Patient')),
    ReceiverID INT NOT NULL,
    ReceiverRole NVARCHAR(20) NOT NULL CHECK (ReceiverRole IN ('Admin', 'Doctor', 'Nurse', 'Receptionist', 'Patient')),
    Title NVARCHAR(255) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
);
