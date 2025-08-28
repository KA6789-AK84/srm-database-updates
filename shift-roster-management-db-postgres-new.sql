-- Create Schemas (run these first if they don't exist)
CREATE SCHEMA IF NOT EXISTS iam;
CREATE SCHEMA IF NOT EXISTS organization;
CREATE SCHEMA IF NOT EXISTS schedule;
CREATE SCHEMA IF NOT EXISTS approvals;
CREATE SCHEMA IF NOT EXISTS notify;

------------------------------------------------------------------------------------------------------------------------
-- iam (Identity and Access Management) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Roles Table
CREATE TABLE iam.roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);
-- Index for role_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_iam_roles_role_name ON iam.roles (role_name);


-- Permissions Table
CREATE TABLE iam.permissions (
    permission_id SERIAL PRIMARY KEY,
    permission_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);
-- Index for permission_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_iam_permissions_permission_name ON iam.permissions (permission_name);


-- Role Permissions Junction Table
CREATE TABLE iam.role_permissions (
    role_id INT NOT NULL REFERENCES iam.roles(role_id) ON DELETE CASCADE,
    permission_id INT NOT NULL REFERENCES iam.permissions(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
-- Indexes for foreign keys to speed up joins and constraint checks
CREATE INDEX idx_iam_role_permissions_role_id ON iam.role_permissions (role_id);
CREATE INDEX idx_iam_role_permissions_permission_id ON iam.role_permissions (permission_id);





------------------------------------------------------------------------------------------------------------------------
-- organization (Core Organizational Data) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Employees Table
CREATE TABLE organization.employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role_id INT NOT NULL REFERENCES iam.roles(role_id), -- Cross-schema FK
    date_joined DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' -- 'Active', 'Inactive', 'On Leave'
);
-- Indexes for common lookups
CREATE UNIQUE INDEX idx_organization_employees_email ON organization.employees (email);
CREATE INDEX idx_organization_employees_role_id ON organization.employees (role_id); -- FK
CREATE INDEX idx_organization_employees_status ON organization.employees (status); -- For filtering employees by status
CREATE INDEX idx_organization_employees_name ON organization.employees (last_name, first_name); -- For sorting/filtering by name

------------------------------------------------------------------------------------------------------------------------
-- iam.user (Identity and Access Management) Schema Table is required to add after employee table due to mapping
------------------------------------------------------------------------------------------------------------------------
-- Users Table 
CREATE TABLE iam.users (
    user_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES iam.roles(role_id), -- Cross-schema FK
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP
);
-- Indexes for common lookups
CREATE UNIQUE INDEX idx_iam_users_username ON iam.users (username);
CREATE INDEX idx_iam_users_employee_id ON iam.users (employee_id); -- FK
CREATE INDEX idx_iam_users_role_id ON iam.users (role_id); -- FK
CREATE INDEX idx_iam_users_is_active ON iam.users (is_active); -- For filtering active users

-- Skills Table
CREATE TABLE organization.skills (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);
-- Index for skill_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_organization_skills_skill_name ON organization.skills (skill_name);


-- Employee Skills Junction Table
CREATE TABLE organization.employee_skills (
    emp_skill_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- FK
    skill_id INT NOT NULL REFERENCES organization.skills(skill_id) ON DELETE CASCADE, -- FK
    proficiency_level VARCHAR(20) CHECK (proficiency_level IN ('Beginner','Intermediate','Expert')),
    UNIQUE(employee_id, skill_id)
);
-- Indexes for foreign keys and compound unique constraint
CREATE INDEX idx_organization_employee_skills_employee_id ON organization.employee_skills (employee_id);
CREATE INDEX idx_organization_employee_skills_skill_id ON organization.employee_skills (skill_id);
CREATE UNIQUE INDEX idx_organization_employee_skills_unique ON organization.employee_skills (employee_id, skill_id);


-- Projects Table
CREATE TABLE organization.projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT
);
-- Index for project_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_organization_projects_project_name ON organization.projects (project_name);


-- Manager Projects Junction Table
CREATE TABLE organization.manager_projects (
    manager_project_id SERIAL PRIMARY KEY,
    manager_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- FK
    project_id INT NOT NULL REFERENCES organization.projects(project_id) ON DELETE CASCADE, -- FK
    UNIQUE(manager_id, project_id)
);
-- Indexes for foreign keys and compound unique constraint
CREATE INDEX idx_organization_manager_projects_manager_id ON organization.manager_projects (manager_id);
CREATE INDEX idx_organization_manager_projects_project_id ON organization.manager_projects (project_id);
CREATE UNIQUE INDEX idx_organization_manager_projects_unique ON organization.manager_projects (manager_id, project_id);





------------------------------------------------------------------------------------------------------------------------
-- schedule (Shift Definitions, Preferences, and Assignments) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Shifts Table
CREATE TABLE schedule.shifts (
    shift_id SERIAL PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL UNIQUE,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
    end_time TIME WITHOUT TIME ZONE NOT NULL,
    duration_hours INT GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (end_time - start_time)) / 3600) STORED,
    overlap_minutes INT DEFAULT 60 CHECK (overlap_minutes >= 0)
);
-- Index for shift_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_schedule_shifts_shift_name ON schedule.shifts (shift_name);
-- Index for time range queries
CREATE INDEX idx_schedule_shifts_time_range ON schedule.shifts (start_time, end_time);


-- Preferences Table
CREATE TABLE schedule.preferences (
    preference_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL UNIQUE REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    preferred_shifts TEXT, -- e.g., JSON array as string or comma-separated
    weekoffs VARCHAR(50), -- e.g., 'Monday,Tuesday'
    notes TEXT
);
-- Index for employee_id as it's UNIQUE and a FK
CREATE UNIQUE INDEX idx_schedule_preferences_employee_id ON schedule.preferences (employee_id);


-- Assignments Table
CREATE TABLE schedule.assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    project_id INT NOT NULL REFERENCES organization.projects(project_id) ON DELETE CASCADE, -- Cross-schema FK
    shift_id INT NOT NULL REFERENCES schedule.shifts(shift_id) ON DELETE CASCADE, -- Cross-schema FK
    assignment_date DATE NOT NULL,
    hours_planned INT DEFAULT 9,
    overlap_minutes INT DEFAULT 60,
    status VARCHAR(20) DEFAULT 'Scheduled', -- 'Scheduled', 'Completed', 'Canceled', 'Swapped'
    UNIQUE(employee_id, assignment_date)
);
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


------------------------------------------------------------------------------------------------------------------------
-- approvals (Leave and Shift Swap Requests) Schema Tables
------------------------------------------------------------------------------------------------------------------------
-- Leave Types Table
CREATE TABLE approvals.leave_types (
    leave_type_id SERIAL PRIMARY KEY,
    leave_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    max_days_per_year INT
);
-- Index for leave_name as it's UNIQUE and often used for lookup
CREATE UNIQUE INDEX idx_approvals_leave_types_leave_name ON approvals.leave_types (leave_name);

-- Leave Requests Table
CREATE TABLE approvals.leave_requests (
    leave_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    leave_type_id INT NOT NULL REFERENCES approvals.leave_types(leave_type_id), -- Cross-schema FK
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'Pending', -- 'Pending', 'Approved', 'Rejected'
    approval_date DATE,
    approver_id INT REFERENCES organization.employees(employee_id) ON DELETE SET NULL -- Cross-schema FK
);
-- Indexes for foreign keys and common query patterns
CREATE INDEX idx_approvals_leave_requests_employee_id ON approvals.leave_requests (employee_id); -- FK
CREATE INDEX idx_approvals_leave_requests_leave_type_id ON approvals.leave_requests (leave_type_id); -- FK
CREATE INDEX idx_approvals_leave_requests_status ON approvals.leave_requests (status); -- For filtering pending/approved requests
CREATE INDEX idx_approvals_leave_requests_approver_id ON approvals.leave_requests (approver_id); -- FK
CREATE INDEX idx_approvals_leave_requests_date_range ON approvals.leave_requests (from_date, to_date); -- For querying leaves within a period


-- Shift Swaps Table
CREATE TABLE approvals.swaps (
    swap_id SERIAL PRIMARY KEY,
    from_emp INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    to_emp INT REFERENCES organization.employees(employee_id) ON DELETE SET NULL, -- Cross-schema FK (nullable if seeking 'any' employee)
    original_shift_id INT REFERENCES schedule.shifts(shift_id) ON DELETE SET NULL, -- Cross-schema FK
    swap_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending'
);
-- Indexes for foreign keys and common query patterns
CREATE INDEX idx_approvals_swaps_from_emp ON approvals.swaps (from_emp); -- FK
CREATE INDEX idx_approvals_swaps_to_emp ON approvals.swaps (to_emp); -- FK
CREATE INDEX idx_approvals_swaps_original_shift_id ON approvals.swaps (original_shift_id); -- FK
CREATE INDEX idx_approvals_swaps_date ON approvals.swaps (swap_date); -- For filtering by date
CREATE INDEX idx_approvals_swaps_status ON approvals.swaps (status); -- For filtering pending/approved swaps


------------------------------------------------------------------------------------------------------------------------
-- notify (System Notifications) Schema Tables
------------------------------------------------------------------------------------------------------------------------

-- Notifications Table
CREATE TABLE notify.notifications (
    notification_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES organization.employees(employee_id) ON DELETE CASCADE, -- Cross-schema FK
    message TEXT NOT NULL,
    type VARCHAR(50), -- e.g., 'Shift Update', 'Approval', 'Broadcast', 'Alert'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Unread'
);
-- Indexes for foreign key and common query patterns
CREATE INDEX idx_notify_notifications_employee_id ON notify.notifications (employee_id); -- FK
CREATE INDEX idx_notify_notifications_status ON notify.notifications (status); -- For filtering unread notifications
CREATE INDEX idx_notify_notifications_type ON notify.notifications (type); -- For filtering by notification type
-- Compound index for efficient retrieval of unread notifications for a specific employee
CREATE INDEX idx_notify_notifications_employee_status_unread ON notify.notifications (employee_id, status) WHERE status = 'Unread';