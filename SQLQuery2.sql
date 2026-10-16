/*
RaceDay - Part 1 SQL Database Script
Microsoft SQL Server Management Studio (SSMS)

This script:
1. Creates the RaceDay database.
2. Creates all relational tables.
3. Defines PK, FK, UNIQUE, NOT NULL, DEFAULT and CHECK constraints.
4. Seeds realistic sample data:
   - 2 Organisers
   - 2 Participants
   - 3 Events
   - Categories for every event
   - Sample enrolments
   - Sample results
*/

USE master;
GO

IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END
GO

CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_Users_Role CHECK (Role IN ('Organiser','Participant'))
);

CREATE TABLE Categories (
    CategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(80) NOT NULL UNIQUE,
    Description NVARCHAR(255) NULL
);

CREATE TABLE Events (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserId INT NOT NULL,
    EventName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    EventType NVARCHAR(20) NOT NULL,
    EventDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    Venue NVARCHAR(150) NOT NULL,
    City NVARCHAR(80) NOT NULL,
    Province NVARCHAR(80) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    MaxParticipants INT NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL DEFAULT 0,
    RouteInformation NVARCHAR(500) NULL,
    WeatherInformation NVARCHAR(500) NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Open',
    CONSTRAINT FK_Events_Users FOREIGN KEY (OrganiserId)
        REFERENCES Users(UserId),
    CONSTRAINT CK_Events_Type CHECK (EventType IN ('Running','Walking','Cycling')),
    CONSTRAINT CK_Events_Distance CHECK (DistanceKm > 0),
    CONSTRAINT CK_Events_Max CHECK (MaxParticipants > 0),
    CONSTRAINT CK_Events_Fee CHECK (EntryFee >= 0),
    CONSTRAINT CK_Events_Status CHECK (Status IN ('Open','Closed','Completed','Cancelled'))
);

CREATE TABLE EventCategories (
    EventId INT NOT NULL,
    CategoryId INT NOT NULL,
    PRIMARY KEY (EventId, CategoryId),
    CONSTRAINT FK_EventCategories_Events FOREIGN KEY (EventId)
        REFERENCES Events(EventId) ON DELETE CASCADE,
    CONSTRAINT FK_EventCategories_Categories FOREIGN KEY (CategoryId)
        REFERENCES Categories(CategoryId)
);

CREATE TABLE Enrolments (
    EnrolmentId INT IDENTITY(1,1) PRIMARY KEY,
    EventId INT NOT NULL,
    ParticipantId INT NOT NULL,
    CategoryId INT NOT NULL,
    EnrolmentDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Enrolled',
    CONSTRAINT FK_Enrolments_Events FOREIGN KEY (EventId)
        REFERENCES Events(EventId),
    CONSTRAINT FK_Enrolments_Users FOREIGN KEY (ParticipantId)
        REFERENCES Users(UserId),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryId)
        REFERENCES Categories(CategoryId),
    CONSTRAINT UQ_Enrolment UNIQUE (EventId, ParticipantId),
    CONSTRAINT CK_Enrolments_Status CHECK (Status IN ('Enrolled','Withdrawn','Completed'))
);

CREATE TABLE Results (
    ResultId INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId INT NOT NULL UNIQUE,
    FinishPosition INT NULL,
    FinishTimeSeconds INT NULL,
    PaceSecondsPerKm INT NULL,
    ResultStatus NVARCHAR(20) NOT NULL DEFAULT 'Finished',
    RecordedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentId)
        REFERENCES Enrolments(EnrolmentId),
    CONSTRAINT CK_Results_Position CHECK (FinishPosition IS NULL OR FinishPosition > 0),
    CONSTRAINT CK_Results_Time CHECK (FinishTimeSeconds IS NULL OR FinishTimeSeconds > 0),
    CONSTRAINT CK_Results_Pace CHECK (PaceSecondsPerKm IS NULL OR PaceSecondsPerKm > 0),
    CONSTRAINT CK_Results_Status CHECK (ResultStatus IN ('Finished','DNF','DNS','Disqualified'))
);

CREATE INDEX IX_Events_Date ON Events(EventDate);
CREATE INDEX IX_Events_Organiser ON Events(OrganiserId);
CREATE INDEX IX_Enrolments_Participant ON Enrolments(ParticipantId);

-- =========================
-- SAMPLE DATA
-- =========================

INSERT INTO Users (FullName, Email, PasswordHash, Role) VALUES
('Lunga Maseko', 'lunga@raceday.co.za', 'HASH001', 'Organiser'),
('Aphiwe Jacobs', 'aphiwe@raceday.co.za', 'HASH002', 'Organiser'),
('Sanelise Mboniswa', 'sanelise@email.com', 'HASH003', 'Participant'),
('Ayanda Ndlovu', 'ayanda@email.com', 'HASH004', 'Participant');

INSERT INTO Categories (CategoryName, Description) VALUES
('5K', '5 kilometre road race'),
('10K', '10 kilometre road race'),
('21.1K', 'Half marathon'),
('42.2K', 'Full marathon'),
('Cycling 50K', '50 kilometre road cycling'),
('Community Walk', 'Community social walk');

INSERT INTO Events
(OrganiserId, EventName, Description, EventType, EventDate, StartTime,
 Venue, City, Province, DistanceKm, MaxParticipants, EntryFee,
 RouteInformation, WeatherInformation, Status)
VALUES
(1, 'Cape Spring 10K', 'Annual spring road running event', 'Running',
 '2026-09-20', '07:00', 'Green Point Stadium', 'Cape Town', 'Western Cape',
 10.00, 1500, 120.00, 'City road route', 'Live weather via API in Part 2', 'Open'),

(2, 'Soweto Community Walk', 'Family community walking event', 'Walking',
 '2026-10-05', '08:00', 'Orlando Stadium', 'Soweto', 'Gauteng',
 5.00, 2000, 40.00, 'Neighbourhood walking route', 'Live weather via API in Part 2', 'Open'),

(1, 'Durban Coastal Cycle', 'Road cycling event along the coast', 'Cycling',
 '2026-11-15', '06:30', 'Durban Beachfront', 'Durban', 'KwaZulu-Natal',
 50.00, 800, 180.00, 'Coastal cycling route', 'Live weather via API in Part 2', 'Open');

-- Categories for each event
INSERT INTO EventCategories (EventId, CategoryId) VALUES
(1,1),(1,2),
(2,6),
(3,5);

-- Sample enrolments
INSERT INTO Enrolments (EventId, ParticipantId, CategoryId, Status) VALUES
(1,3,2,'Enrolled'),
(1,4,1,'Completed'),
(2,3,6,'Enrolled'),
(3,4,5,'Completed');

-- Sample results
INSERT INTO Results (EnrolmentId, FinishPosition, FinishTimeSeconds, PaceSecondsPerKm, ResultStatus) VALUES
(2,18,1680,336,'Finished'),
(4,9,5400,108,'Finished');

-- Verification
SELECT * FROM Users;
SELECT * FROM Categories;
SELECT * FROM Events;
SELECT * FROM EventCategories;
SELECT * FROM Enrolments;
SELECT * FROM Results;
GO
GO
