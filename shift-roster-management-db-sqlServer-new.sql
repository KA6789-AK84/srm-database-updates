-- Create Schemas (run these first if they don't exist)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'iam')
BEGIN
    EXEC('CREATE SCHEMA iam');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'organization')
BEGIN
    EXEC('CREATE SCHEMA organization');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'schedule')
BEGIN
    EXEC('CREATE SCHEMA schedule');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'approvals')
BEGIN
    EXEC('CREATE SCHEMA approvals');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'notify')
BEGIN
    EXEC('CREATE SCHEMA notify');
END;
GO

------------------------------------------------------------------------------------------------------------------------
-- iam (Identity and Access Management) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Roles Table
CREATE TABLE iam.roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    role_name NVARCHAR(50) UNIQUE NOT NULL,
    description NVARCHAR(MAX)
);
GO
-- Index for role_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_iam_roles_role_name ON iam.roles (role_name);
GO


-- Permissions Table
CREATE TABLE iam.permissions (
    permission_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    permission_name NVARCHAR(100) UNIQUE NOT NULL,
    description NVARCHAR(MAX)
);
GO
-- Index for permission_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_iam_permissions_permission_name ON iam.permissions (permission_name);
GO


-- Role Permissions Junction Table
CREATE TABLE iam.role_permissions (
    role_id INT NOT NULL REFERENCES iam.roles(role_id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES iam.permissions(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
GO
-- Indexes for foreign keys to speed up joins and constraint checks
CREATE INDEX idx_iam_role_permissions_role_id ON iam.role_permissions (role_id);
CREATE INDEX idx_iam_role_permissions_permission_id ON iam.role_permissions (permission_id);
GO


-- Users Table (formerly user_auth)
CREATE TABLE iam.users (
    user_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    username NVARCHAR(100) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES iam.roles(role_id), -- Cross-schema FK
    is_active BIT DEFAULT 1, -- BOOLEAN equivalent
    last_login DATETIMEOFFSET, -- TIMESTAMP WITH TIME ZONE equivalent
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Indexes for common lookups
CREATE UNIQUE INDEX idx_iam_users_username ON iam.users (username);
CREATE INDEX idx_iam_users_employee_id ON iam.users (employee_id); -- FK
CREATE INDEX idx_iam_users_role_id ON iam.users (role_id); -- FK
CREATE INDEX idx_iam_users_is_active ON iam.users (is_active); -- For filtering active users
GO


------------------------------------------------------------------------------------------------------------------------
-- organization (Core Organizational Data) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Employees Table
CREATE TABLE organization.employees (
    employee_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) UNIQUE NOT NULL,
    role_id INT NOT NULL REFERENCES iam.roles(role_id), -- Cross-schema FK
    date_joined DATE NOT NULL,
    status NVARCHAR(20) DEFAULT 'Active' -- 'Active', 'Inactive', 'On Leave'
);
GO
-- Indexes for common lookups
CREATE UNIQUE INDEX idx_organization_employees_email ON organization.employees (email);
CREATE INDEX idx_organization_employees_role_id ON organization.employees (role_id); -- FK
CREATE INDEX idx_organization_employees_status ON organization.employees (status); -- For filtering employees by status
CREATE INDEX idx_organization_employees_name ON organization.employees (last_name, first_name); -- For sorting/filtering by name
GO


-- Skills Table
CREATE TABLE organization.skills (
    skill_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    skill_name NVARCHAR(100) UNIQUE NOT NULL,
    description NVARCHAR(MAX)
);
GO
-- Index for skill_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_organization_skills_skill_name ON organization.skills (skill_name);
GO


-- Employee Skills Junction Table
CREATE TABLE organization.employee_skills (
    emp_skill_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- FK
    skill_id INT NOT NULL REFERENCES organization.skills(skill_id) ON DELETE CASCADE, -- FK
    proficiency_level NVARCHAR(20) CHECK (proficiency_level IN ('Beginner','Intermediate','Expert')),
    UNIQUE(employee_id, skill_id)
);
GO
-- Indexes for foreign keys and compound unique constraint
CREATE INDEX idx_organization_employee_skills_employee_id ON organization.employee_skills (employee_id);
CREATE INDEX idx_organization_employee_skills_skill_id ON organization.employee_skills (skill_id);
CREATE UNIQUE INDEX idx_organization_employee_skills_unique ON organization.employee_skills (employee_id, skill_id);
GO


-- Projects Table
CREATE TABLE organization.projects (
    project_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    project_name NVARCHAR(200) NOT NULL UNIQUE,
    description NVARCHAR(MAX)
);
GO
-- Index for project_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_organization_projects_project_name ON organization.projects (project_name);
GO


-- Manager Projects Junction Table
CREATE TABLE organization.manager_projects (
    manager_project_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    manager_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- FK
    project_id INT NOT NULL REFERENCES organization.projects(project_id) ON DELETE CASCADE, -- FK
    UNIQUE(manager_id, project_id)
);
GO
-- Indexes for foreign keys and compound unique constraint
CREATE INDEX idx_organization_manager_projects_manager_id ON organization.manager_projects (manager_id);
CREATE INDEX idx_organization_manager_projects_project_id ON organization.manager_projects (project_id);
CREATE UNIQUE INDEX idx_organization_manager_projects_unique ON organization.manager_projects (manager_id, project_id);
GO


-- Leave Types Table
CREATE TABLE organization.leave_types (
    leave_type_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    leave_name NVARCHAR(100) UNIQUE NOT NULL,
    description NVARCHAR(MAX),
    max_days_per_year INT
);
GO
-- Index for leave_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_organization_leave_types_leave_name ON organization.leave_types (leave_name);
GO


------------------------------------------------------------------------------------------------------------------------
-- schedule (Shift Definitions, Preferences, and Assignments) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Shifts Table
CREATE TABLE schedule.shifts (
    shift_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    shift_name NVARCHAR(50) NOT NULL UNIQUE,
    start_time TIME(0) NOT NULL, -- TIME WITHOUT TIME ZONE equivalent, (0) for no fractional seconds
    end_time TIME(0) NOT NULL,
    -- Computed column for duration in hours, PERSISTED stores the value
    duration_hours AS (CAST(DATEDIFF(minute, start_time, end_time) AS INT) / 60) PERSISTED,
    overlap_minutes INT DEFAULT 60 CHECK (overlap_minutes >= 0),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Index for shift_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_schedule_shifts_shift_name ON schedule.shifts (shift_name);
-- Index for time range queries
CREATE INDEX idx_schedule_shifts_time_range ON schedule.shifts (start_time, end_time);
GO


-- Preferences Table
CREATE TABLE schedule.preferences (
    preference_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT NOT NULL UNIQUE REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    preferred_shifts NVARCHAR(MAX), -- Store as JSON string or comma-separated
    weekoffs NVARCHAR(50), -- e.g., 'Monday,Tuesday'
    notes NVARCHAR(MAX)
);
GO
-- Index for employee_id as it's UNIQUE and a FK
CREATE UNIQUE INDEX idx_schedule_preferences_employee_id ON schedule.preferences (employee_id);
GO


-- Assignments Table
CREATE TABLE schedule.assignments (
    assignment_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    project_id INT NOT NULL REFERENCES organization.projects(project_id) ON DELETE CASCADE, -- Cross-schema FK
    shift_id INT NOT NULL REFERENCES schedule.shifts(shift_id) ON DELETE CASCADE, -- Cross-schema FK
    assignment_date DATE NOT NULL,
    hours_planned INT DEFAULT 9,
    overlap_minutes INT DEFAULT 60,
    status NVARCHAR(20) DEFAULT 'Scheduled', -- 'Scheduled', 'Completed', 'Canceled', 'Swapped'
    UNIQUE(employee_id, assignment_date),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Indexes for foreign keys and common query patterns
CREATE INDEX idx_schedule_assignments_employee_id ON schedule.assignments (employee_id); -- FK
CREATE INDEX idx_schedule_assignments_project_id ON schedule.assignments (project_id); -- FK
CREATE INDEX idx_schedule_assignments_shift_id ON schedule.assignments (shift_id); -- FK
CREATE INDEX idx_schedule_assignments_date ON schedule.assignments (assignment_date); -- For filtering by date
CREATE INDEX idx_schedule_assignments_status ON schedule.assignments (status); -- For filtering by status
-- Compound index for faster retrieval of assignments for a specific employee on a given date range
CREATE INDEX idx_schedule_assignments_employee_date_range ON schedule.assignments (employee_id, assignment_date);
-- Compound index for faster retrieval of assignments for a specific project on a given date range
CREATE INDEX idx_schedule_assignments_project_date_range ON schedule.assignments (project_id, assignment_date);
GO


------------------------------------------------------------------------------------------------------------------------
-- approvals (Leave and Shift Swap Requests) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Leave Requests Table
CREATE TABLE approvals.leave_requests (
    leave_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    leave_type_id INT NOT NULL REFERENCES organization.leave_types(leave_type_id), -- Cross-schema FK
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    reason NVARCHAR(MAX),
    status NVARCHAR(20) DEFAULT 'Pending', -- 'Pending', 'Approved', 'Rejected'
    approval_date DATE,
    approver_id INT REFERENCES organization.employees(employee_id) ON DELETE SET NULL, -- Cross-schema FK
    ai_insights NVARCHAR(MAX), -- Store JSON as NVARCHAR(MAX)
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Indexes for foreign keys and common query patterns
CREATE INDEX idx_approvals_leave_requests_employee_id ON approvals.leave_requests (employee_id); -- FK
CREATE INDEX idx_approvals_leave_requests_leave_type_id ON approvals.leave_requests (leave_type_id); -- FK
CREATE INDEX idx_approvals_leave_requests_status ON approvals.leave_requests (status); -- For filtering pending/approved requests
CREATE INDEX idx_approvals_leave_requests_approver_id ON approvals.leave_requests (approver_id); -- FK
CREATE INDEX idx_approvals_leave_requests_date_range ON approvals.leave_requests (from_date, to_date); -- For querying leaves within a period
GO


-- Shift Swaps Table
CREATE TABLE approvals.swaps (
    swap_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    from_emp INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    to_emp INT REFERENCES organization.employees(employee_id) ON DELETE SET NULL, -- Cross-schema FK (nullable if seeking 'any' employee)
    original_shift_id INT REFERENCES schedule.shifts(shift_id) ON DELETE SET NULL, -- Cross-schema FK
    swap_date DATE NOT NULL,
    status NVARCHAR(20) DEFAULT 'Pending',
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET()
);
GO
-- Indexes for foreign keys and common query patterns
CREATE INDEX idx_approvals_swaps_from_emp ON approvals.swaps (from_emp); -- FK
CREATE INDEX idx_approvals_swaps_to_emp ON approvals.swaps (to_emp); -- FK
CREATE INDEX idx_approvals_swaps_original_shift_id ON approvals.swaps (original_shift_id); -- FK
CREATE INDEX idx_approvals_swaps_date ON approvals.swaps (swap_date); -- For filtering by date
CREATE INDEX idx_approvals_swaps_status ON approvals.swaps (status); -- For filtering pending/approved swaps
GO


------------------------------------------------------------------------------------------------------------------------
-- notify (System Notifications) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Notifications Table
CREATE TABLE notify.notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY, -- SERIAL equivalent
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    message NVARCHAR(MAX) NOT NULL,
    type NVARCHAR(50),
    created_at DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(), -- TIMESTAMP DEFAULT CURRENT_TIMESTAMP equivalent
    status NVARCHAR(20) DEFAULT 'Unread'
);
GO
-- Indexes for foreign key and common query patterns
CREATE INDEX idx_notify_notifications_employee_id ON notify.notifications (employee_id); -- FK
CREATE INDEX idx_notify_notifications_status ON notify.notifications (status); -- For filtering unread notifications
CREATE INDEX idx_notify_notifications_type ON notify.notifications (type); -- For filtering by notification type
-- Compound index for efficient retrieval of unread notifications for a specific employee
CREATE INDEX idx_notify_notifications_employee_status_unread ON notify.notifications (employee_id, status) WHERE status = 'Unread';
GO