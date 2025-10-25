--
-- PostgreSQL database dump
--

\restrict TMapmpA8c9rkZh4zKm6Jv6aCl1phviUVfcWnDR51G0rEsl0aiia33ARxc8K7ngv

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: approvals; Type: SCHEMA; Schema: -; Owner: ak682a
--

CREATE SCHEMA approvals;


ALTER SCHEMA approvals OWNER TO ak682a;

--
-- Name: iam; Type: SCHEMA; Schema: -; Owner: ak682a
--

CREATE SCHEMA iam;


ALTER SCHEMA iam OWNER TO ak682a;

--
-- Name: notify; Type: SCHEMA; Schema: -; Owner: ak682a
--

CREATE SCHEMA notify;


ALTER SCHEMA notify OWNER TO ak682a;

--
-- Name: organization; Type: SCHEMA; Schema: -; Owner: ak682a
--

CREATE SCHEMA organization;


ALTER SCHEMA organization OWNER TO ak682a;

--
-- Name: schedule; Type: SCHEMA; Schema: -; Owner: ak682a
--

CREATE SCHEMA schedule;


ALTER SCHEMA schedule OWNER TO ak682a;

--
-- Name: insert_swap_request(jsonb, integer); Type: PROCEDURE; Schema: approvals; Owner: ak682a
--

CREATE PROCEDURE approvals.insert_swap_request(IN p_payload jsonb, IN userid integer, OUT o_result jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
  fromEmp      INT := (p_payload->>'from_emp')::INT;
  toEmp        INT := (p_payload->>'to_emp')::INT;
  fromShiftId INT := (p_payload->>'from_shift_id')::INT;
  toShiftId   INT := (p_payload->>'to_shift_id')::INT;
  swapDate     DATE:= (p_payload->>'swap_date')::DATE;
  swapStatus        INT:=  p_payload->>'status';
  swapType     INT:=  p_payload->>'swap_type';
  projectId    INT := (p_payload->>'project_id')::INT;
  swapReason        TEXT:=  p_payload->>'reason';
  managerId		  INT; 
  swapId   INT;
BEGIN

-- 1. Fetch manager for the given user
  SELECT manager_id
    INTO managerId
    FROM organization.manager_projects
   WHERE project_id = projectId;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Manager not found for user %', userId
      USING ERRCODE = 'P0005';
  END IF;
  
  -- validations
  IF fromEmp = toEmp THEN
    RAISE EXCEPTION 'from_emp (%) and to_emp (%) must differ', fromEmp, toEmp
      USING ERRCODE='P0001';
  END IF;

  -- insert
  INSERT INTO approvals.swaps(
    from_emp, to_emp, from_shift_id, to_shift_id,
    swap_date, status, swap_type, manager_id,
    project_id, reason
  )
  VALUES (
    fromEmp, toEmp, fromShiftId, toShiftId,
    swapDate, swapStatus, swapType, userId,
    projectId, swapReason
  )
  RETURNING swap_id
    INTO swapId ;

  -- build JSON result
  o_result := jsonb_build_object(
    'swap_id', swapId,
    'from_emp', fromEmp,
    'to_emp',   toEmp,
    'from_shift_id', fromShiftId,
    'to_shift_id',   toShiftId,
    'swap_date',     swapDate,
    'status',        swapStatus,
    'swap_type',     swapType,
    'manager_id',    userId,
    'project_id',    projectId,
    'reason',        swapReason
  );
END;
$$;


ALTER PROCEDURE approvals.insert_swap_request(IN p_payload jsonb, IN userid integer, OUT o_result jsonb) OWNER TO ak682a;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: leave_requests; Type: TABLE; Schema: approvals; Owner: ak682a
--

CREATE TABLE approvals.leave_requests (
    leave_id integer NOT NULL,
    employee_id integer NOT NULL,
    leave_type_id integer NOT NULL,
    from_date date NOT NULL,
    to_date date NOT NULL,
    reason text,
    status character varying(20) DEFAULT 'Pending'::character varying,
    approval_date date,
    approver_id integer
);


ALTER TABLE approvals.leave_requests OWNER TO ak682a;

--
-- Name: leave_requests_leave_id_seq; Type: SEQUENCE; Schema: approvals; Owner: ak682a
--

CREATE SEQUENCE approvals.leave_requests_leave_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE approvals.leave_requests_leave_id_seq OWNER TO ak682a;

--
-- Name: leave_requests_leave_id_seq; Type: SEQUENCE OWNED BY; Schema: approvals; Owner: ak682a
--

ALTER SEQUENCE approvals.leave_requests_leave_id_seq OWNED BY approvals.leave_requests.leave_id;


--
-- Name: leave_types; Type: TABLE; Schema: approvals; Owner: ak682a
--

CREATE TABLE approvals.leave_types (
    leave_type_id integer NOT NULL,
    leave_name character varying(100) NOT NULL,
    description text,
    max_days_per_year integer
);


ALTER TABLE approvals.leave_types OWNER TO ak682a;

--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE; Schema: approvals; Owner: ak682a
--

CREATE SEQUENCE approvals.leave_types_leave_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE approvals.leave_types_leave_type_id_seq OWNER TO ak682a;

--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE OWNED BY; Schema: approvals; Owner: ak682a
--

ALTER SEQUENCE approvals.leave_types_leave_type_id_seq OWNED BY approvals.leave_types.leave_type_id;


--
-- Name: swap_type_lookup; Type: TABLE; Schema: approvals; Owner: ak682a
--

CREATE TABLE approvals.swap_type_lookup (
    swap_type_id smallint NOT NULL,
    swap_type_desc text NOT NULL
);


ALTER TABLE approvals.swap_type_lookup OWNER TO ak682a;

--
-- Name: swaps; Type: TABLE; Schema: approvals; Owner: ak682a
--

CREATE TABLE approvals.swaps (
    swap_id integer NOT NULL,
    from_emp integer NOT NULL,
    to_emp integer NOT NULL,
    from_shift_id integer NOT NULL,
    to_shift_id integer NOT NULL,
    swap_date date NOT NULL,
    status integer NOT NULL,
    swap_type smallint NOT NULL,
    manager_id integer NOT NULL,
    project_id integer NOT NULL,
    reason text
);


ALTER TABLE approvals.swaps OWNER TO ak682a;

--
-- Name: swaps_swap_id_seq; Type: SEQUENCE; Schema: approvals; Owner: ak682a
--

CREATE SEQUENCE approvals.swaps_swap_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE approvals.swaps_swap_id_seq OWNER TO ak682a;

--
-- Name: swaps_swap_id_seq; Type: SEQUENCE OWNED BY; Schema: approvals; Owner: ak682a
--

ALTER SEQUENCE approvals.swaps_swap_id_seq OWNED BY approvals.swaps.swap_id;


--
-- Name: permissions; Type: TABLE; Schema: iam; Owner: ak682a
--

CREATE TABLE iam.permissions (
    permission_id integer NOT NULL,
    permission_name character varying(100) NOT NULL,
    description text
);


ALTER TABLE iam.permissions OWNER TO ak682a;

--
-- Name: permissions_permission_id_seq; Type: SEQUENCE; Schema: iam; Owner: ak682a
--

CREATE SEQUENCE iam.permissions_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE iam.permissions_permission_id_seq OWNER TO ak682a;

--
-- Name: permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: iam; Owner: ak682a
--

ALTER SEQUENCE iam.permissions_permission_id_seq OWNED BY iam.permissions.permission_id;


--
-- Name: role_permissions; Type: TABLE; Schema: iam; Owner: ak682a
--

CREATE TABLE iam.role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE iam.role_permissions OWNER TO ak682a;

--
-- Name: roles; Type: TABLE; Schema: iam; Owner: ak682a
--

CREATE TABLE iam.roles (
    role_id integer NOT NULL,
    role_name character varying(50) NOT NULL,
    description text
);


ALTER TABLE iam.roles OWNER TO ak682a;

--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: iam; Owner: ak682a
--

CREATE SEQUENCE iam.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE iam.roles_role_id_seq OWNER TO ak682a;

--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: iam; Owner: ak682a
--

ALTER SEQUENCE iam.roles_role_id_seq OWNED BY iam.roles.role_id;


--
-- Name: users; Type: TABLE; Schema: iam; Owner: ak682a
--

CREATE TABLE iam.users (
    user_id integer NOT NULL,
    employee_id integer,
    username character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    salt character varying(255) NOT NULL,
    role_id integer NOT NULL,
    is_active boolean DEFAULT true,
    last_login timestamp without time zone
);


ALTER TABLE iam.users OWNER TO ak682a;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: iam; Owner: ak682a
--

CREATE SEQUENCE iam.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE iam.users_user_id_seq OWNER TO ak682a;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: iam; Owner: ak682a
--

ALTER SEQUENCE iam.users_user_id_seq OWNED BY iam.users.user_id;


--
-- Name: notifications; Type: TABLE; Schema: notify; Owner: ak682a
--

CREATE TABLE notify.notifications (
    notification_id integer NOT NULL,
    employee_id integer NOT NULL,
    message text NOT NULL,
    type character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'Unread'::character varying
);


ALTER TABLE notify.notifications OWNER TO ak682a;

--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: notify; Owner: ak682a
--

CREATE SEQUENCE notify.notifications_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notify.notifications_notification_id_seq OWNER TO ak682a;

--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: notify; Owner: ak682a
--

ALTER SEQUENCE notify.notifications_notification_id_seq OWNED BY notify.notifications.notification_id;


--
-- Name: employee_skills; Type: TABLE; Schema: organization; Owner: ak682a
--

CREATE TABLE organization.employee_skills (
    emp_skill_id integer NOT NULL,
    employee_id integer NOT NULL,
    skill_id integer NOT NULL,
    proficiency_level character varying(20),
    CONSTRAINT employee_skills_proficiency_level_check CHECK (((proficiency_level)::text = ANY ((ARRAY['Beginner'::character varying, 'Intermediate'::character varying, 'Expert'::character varying])::text[])))
);


ALTER TABLE organization.employee_skills OWNER TO ak682a;

--
-- Name: employee_skills_emp_skill_id_seq; Type: SEQUENCE; Schema: organization; Owner: ak682a
--

CREATE SEQUENCE organization.employee_skills_emp_skill_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE organization.employee_skills_emp_skill_id_seq OWNER TO ak682a;

--
-- Name: employee_skills_emp_skill_id_seq; Type: SEQUENCE OWNED BY; Schema: organization; Owner: ak682a
--

ALTER SEQUENCE organization.employee_skills_emp_skill_id_seq OWNED BY organization.employee_skills.emp_skill_id;


--
-- Name: employees; Type: TABLE; Schema: organization; Owner: ak682a
--

CREATE TABLE organization.employees (
    employee_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    role_id integer NOT NULL,
    date_joined date NOT NULL,
    status character varying(20) DEFAULT 'Active'::character varying,
    job_title character varying(100)
);


ALTER TABLE organization.employees OWNER TO ak682a;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: organization; Owner: ak682a
--

CREATE SEQUENCE organization.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE organization.employees_employee_id_seq OWNER TO ak682a;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: organization; Owner: ak682a
--

ALTER SEQUENCE organization.employees_employee_id_seq OWNED BY organization.employees.employee_id;


--
-- Name: manager_projects; Type: TABLE; Schema: organization; Owner: ak682a
--

CREATE TABLE organization.manager_projects (
    manager_project_id integer NOT NULL,
    manager_id integer NOT NULL,
    project_id integer NOT NULL
);


ALTER TABLE organization.manager_projects OWNER TO ak682a;

--
-- Name: manager_projects_manager_project_id_seq; Type: SEQUENCE; Schema: organization; Owner: ak682a
--

CREATE SEQUENCE organization.manager_projects_manager_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE organization.manager_projects_manager_project_id_seq OWNER TO ak682a;

--
-- Name: manager_projects_manager_project_id_seq; Type: SEQUENCE OWNED BY; Schema: organization; Owner: ak682a
--

ALTER SEQUENCE organization.manager_projects_manager_project_id_seq OWNED BY organization.manager_projects.manager_project_id;


--
-- Name: projects; Type: TABLE; Schema: organization; Owner: ak682a
--

CREATE TABLE organization.projects (
    project_id integer NOT NULL,
    project_name character varying(200) NOT NULL,
    description text,
    status integer DEFAULT 1
);


ALTER TABLE organization.projects OWNER TO ak682a;

--
-- Name: projects_project_id_seq; Type: SEQUENCE; Schema: organization; Owner: ak682a
--

CREATE SEQUENCE organization.projects_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE organization.projects_project_id_seq OWNER TO ak682a;

--
-- Name: projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: organization; Owner: ak682a
--

ALTER SEQUENCE organization.projects_project_id_seq OWNED BY organization.projects.project_id;


--
-- Name: skills; Type: TABLE; Schema: organization; Owner: ak682a
--

CREATE TABLE organization.skills (
    skill_id integer NOT NULL,
    skill_name character varying(100) NOT NULL,
    description text
);


ALTER TABLE organization.skills OWNER TO ak682a;

--
-- Name: skills_skill_id_seq; Type: SEQUENCE; Schema: organization; Owner: ak682a
--

CREATE SEQUENCE organization.skills_skill_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE organization.skills_skill_id_seq OWNER TO ak682a;

--
-- Name: skills_skill_id_seq; Type: SEQUENCE OWNED BY; Schema: organization; Owner: ak682a
--

ALTER SEQUENCE organization.skills_skill_id_seq OWNED BY organization.skills.skill_id;


--
-- Name: vw_managers_project; Type: VIEW; Schema: organization; Owner: ak682a
--

CREATE VIEW organization.vw_managers_project AS
 SELECT p.project_id AS pid,
    p.project_name AS projectname,
    p.description,
    mp.manager_id AS managerid,
    concat(e.first_name, ' ', e.last_name) AS managername,
    e.role_id AS roleid,
    p.status AS projectstatus
   FROM ((organization.projects p
     JOIN organization.manager_projects mp ON ((mp.project_id = p.project_id)))
     JOIN organization.employees e ON ((e.employee_id = mp.manager_id)))
  WHERE (((e.status)::text = 'Active'::text) AND (e.role_id = 2));


ALTER VIEW organization.vw_managers_project OWNER TO ak682a;

--
-- Name: assignments; Type: TABLE; Schema: schedule; Owner: ak682a
--

CREATE TABLE schedule.assignments (
    assignment_id integer NOT NULL,
    employee_id integer NOT NULL,
    project_id integer NOT NULL,
    group_id integer NOT NULL,
    shift_id integer NOT NULL,
    assignment_date date NOT NULL,
    hours_planned integer DEFAULT 9,
    overlap_minutes integer DEFAULT 60,
    status character varying(20) DEFAULT 'Scheduled'::character varying
);


ALTER TABLE schedule.assignments OWNER TO ak682a;

--
-- Name: assignments_assignment_id_seq; Type: SEQUENCE; Schema: schedule; Owner: ak682a
--

CREATE SEQUENCE schedule.assignments_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE schedule.assignments_assignment_id_seq OWNER TO ak682a;

--
-- Name: assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: schedule; Owner: ak682a
--

ALTER SEQUENCE schedule.assignments_assignment_id_seq OWNED BY schedule.assignments.assignment_id;


--
-- Name: preferences; Type: TABLE; Schema: schedule; Owner: ak682a
--

CREATE TABLE schedule.preferences (
    preference_id integer NOT NULL,
    employee_id integer NOT NULL,
    preferred_shifts text,
    weekoffs character varying(50),
    notes text
);


ALTER TABLE schedule.preferences OWNER TO ak682a;

--
-- Name: preferences_preference_id_seq; Type: SEQUENCE; Schema: schedule; Owner: ak682a
--

CREATE SEQUENCE schedule.preferences_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE schedule.preferences_preference_id_seq OWNER TO ak682a;

--
-- Name: preferences_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: schedule; Owner: ak682a
--

ALTER SEQUENCE schedule.preferences_preference_id_seq OWNED BY schedule.preferences.preference_id;


--
-- Name: shifts; Type: TABLE; Schema: schedule; Owner: ak682a
--

CREATE TABLE schedule.shifts (
    shift_id integer NOT NULL,
    shift_name character varying(50) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    duration_hours integer GENERATED ALWAYS AS ((EXTRACT(epoch FROM (end_time - start_time)) / (3600)::numeric)) STORED,
    overlap_minutes integer DEFAULT 60,
    CONSTRAINT shifts_overlap_minutes_check CHECK ((overlap_minutes >= 0))
);


ALTER TABLE schedule.shifts OWNER TO ak682a;

--
-- Name: shifts_group; Type: TABLE; Schema: schedule; Owner: ak682a
--

CREATE TABLE schedule.shifts_group (
    group_id integer NOT NULL,
    groupname character varying(255) NOT NULL,
    project_id integer NOT NULL,
    week_off_1 character varying(10),
    week_off_2 character varying(10)
);


ALTER TABLE schedule.shifts_group OWNER TO ak682a;

--
-- Name: shifts_group_group_id_seq; Type: SEQUENCE; Schema: schedule; Owner: ak682a
--

CREATE SEQUENCE schedule.shifts_group_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE schedule.shifts_group_group_id_seq OWNER TO ak682a;

--
-- Name: shifts_group_group_id_seq; Type: SEQUENCE OWNED BY; Schema: schedule; Owner: ak682a
--

ALTER SEQUENCE schedule.shifts_group_group_id_seq OWNED BY schedule.shifts_group.group_id;


--
-- Name: shifts_shift_id_seq; Type: SEQUENCE; Schema: schedule; Owner: ak682a
--

CREATE SEQUENCE schedule.shifts_shift_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE schedule.shifts_shift_id_seq OWNER TO ak682a;

--
-- Name: shifts_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: schedule; Owner: ak682a
--

ALTER SEQUENCE schedule.shifts_shift_id_seq OWNED BY schedule.shifts.shift_id;


--
-- Name: vw_shift_assignment_employee; Type: VIEW; Schema: schedule; Owner: ak682a
--

CREATE VIEW schedule.vw_shift_assignment_employee AS
 SELECT a.assignment_id,
    a.employee_id,
    a.project_id,
    a.group_id,
    a.shift_id,
    to_char((a.assignment_date)::timestamp with time zone, 'YYYY-MM-DD'::text) AS assignment_date,
    a.status AS shift_status,
    e.first_name,
    e.last_name,
    e.email,
    e.job_title,
    e.role_id,
    e.status AS emp_status,
    p.project_name,
    g.groupname,
    g.week_off_1,
    g.week_off_2,
    s.shift_name,
    s.start_time AS shift_start_time,
    s.end_time AS shift_end_time
   FROM ((((schedule.assignments a
     JOIN organization.employees e ON ((e.employee_id = a.employee_id)))
     JOIN organization.projects p ON ((p.project_id = a.project_id)))
     JOIN schedule.shifts_group g ON ((g.group_id = a.group_id)))
     JOIN schedule.shifts s ON ((s.shift_id = a.shift_id)));


ALTER VIEW schedule.vw_shift_assignment_employee OWNER TO ak682a;

--
-- Name: leave_requests leave_id; Type: DEFAULT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_requests ALTER COLUMN leave_id SET DEFAULT nextval('approvals.leave_requests_leave_id_seq'::regclass);


--
-- Name: leave_types leave_type_id; Type: DEFAULT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_types ALTER COLUMN leave_type_id SET DEFAULT nextval('approvals.leave_types_leave_type_id_seq'::regclass);


--
-- Name: swaps swap_id; Type: DEFAULT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps ALTER COLUMN swap_id SET DEFAULT nextval('approvals.swaps_swap_id_seq'::regclass);


--
-- Name: permissions permission_id; Type: DEFAULT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.permissions ALTER COLUMN permission_id SET DEFAULT nextval('iam.permissions_permission_id_seq'::regclass);


--
-- Name: roles role_id; Type: DEFAULT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.roles ALTER COLUMN role_id SET DEFAULT nextval('iam.roles_role_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.users ALTER COLUMN user_id SET DEFAULT nextval('iam.users_user_id_seq'::regclass);


--
-- Name: notifications notification_id; Type: DEFAULT; Schema: notify; Owner: ak682a
--

ALTER TABLE ONLY notify.notifications ALTER COLUMN notification_id SET DEFAULT nextval('notify.notifications_notification_id_seq'::regclass);


--
-- Name: employee_skills emp_skill_id; Type: DEFAULT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employee_skills ALTER COLUMN emp_skill_id SET DEFAULT nextval('organization.employee_skills_emp_skill_id_seq'::regclass);


--
-- Name: employees employee_id; Type: DEFAULT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employees ALTER COLUMN employee_id SET DEFAULT nextval('organization.employees_employee_id_seq'::regclass);


--
-- Name: manager_projects manager_project_id; Type: DEFAULT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.manager_projects ALTER COLUMN manager_project_id SET DEFAULT nextval('organization.manager_projects_manager_project_id_seq'::regclass);


--
-- Name: projects project_id; Type: DEFAULT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.projects ALTER COLUMN project_id SET DEFAULT nextval('organization.projects_project_id_seq'::regclass);


--
-- Name: skills skill_id; Type: DEFAULT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.skills ALTER COLUMN skill_id SET DEFAULT nextval('organization.skills_skill_id_seq'::regclass);


--
-- Name: assignments assignment_id; Type: DEFAULT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments ALTER COLUMN assignment_id SET DEFAULT nextval('schedule.assignments_assignment_id_seq'::regclass);


--
-- Name: preferences preference_id; Type: DEFAULT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.preferences ALTER COLUMN preference_id SET DEFAULT nextval('schedule.preferences_preference_id_seq'::regclass);


--
-- Name: shifts shift_id; Type: DEFAULT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts ALTER COLUMN shift_id SET DEFAULT nextval('schedule.shifts_shift_id_seq'::regclass);


--
-- Name: shifts_group group_id; Type: DEFAULT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts_group ALTER COLUMN group_id SET DEFAULT nextval('schedule.shifts_group_group_id_seq'::regclass);


--
-- Data for Name: leave_requests; Type: TABLE DATA; Schema: approvals; Owner: ak682a
--

COPY approvals.leave_requests (leave_id, employee_id, leave_type_id, from_date, to_date, reason, status, approval_date, approver_id) FROM stdin;
1	1	5	2025-09-26	2025-09-29	\N	Pending	2023-02-25	2
2	1	4	2025-04-03	2023-04-06	\N	Pending	2023-04-02	141
3	1	5	2024-10-29	2024-10-30	\N	Pending	2024-10-28	240
4	1	1	2025-07-21	2025-07-28	\N	Approved	2025-07-20	2
5	1	2	2025-02-19	2025-02-22	\N	Approved	2025-02-18	2
6	1	4	2023-09-17	2023-09-20	\N	Approved	2023-09-16	256
7	1	3	2023-08-09	2023-08-10	\N	Approved	2023-08-08	214
8	1	2	2024-06-10	2024-06-13	\N	Approved	2024-06-09	65
9	2	2	2023-07-23	2023-07-25	\N	Pending	2023-07-22	53
10	2	5	2024-11-25	2024-12-02	\N	Pending	2024-11-24	141
11	2	5	2024-10-06	2024-10-09	\N	Approved	2024-10-05	178
12	2	4	2023-04-28	2023-04-30	\N	Pending	2023-04-27	240
13	3	2	2023-09-08	2023-09-15	\N	Approved	2023-09-07	123
\.


--
-- Data for Name: leave_types; Type: TABLE DATA; Schema: approvals; Owner: ak682a
--

COPY approvals.leave_types (leave_type_id, leave_name, description, max_days_per_year) FROM stdin;
1	Casual Leave	Short casual leave	12
2	Sick Leave	Medical leave	10
3	Planned Leaves	Planned vacation	18
4	Maternity	Extended absence	30
5	CompOff	Compensatory off	8
\.


--
-- Data for Name: swap_type_lookup; Type: TABLE DATA; Schema: approvals; Owner: ak682a
--

COPY approvals.swap_type_lookup (swap_type_id, swap_type_desc) FROM stdin;
1	shift swap
2	weekoff swap
\.


--
-- Data for Name: swaps; Type: TABLE DATA; Schema: approvals; Owner: ak682a
--

COPY approvals.swaps (swap_id, from_emp, to_emp, from_shift_id, to_shift_id, swap_date, status, swap_type, manager_id, project_id, reason) FROM stdin;
44	1	3	1	2	2025-09-08	0	1	1	1	Adding reson for testing purpose
45	1	4	1	2	2025-09-17	0	1	1	1	Due to some urgent work. Could not do that shift.
46	1	15	1	2	2025-09-23	0	1	1	1	Testing
47	1	15	1	2	2025-09-25	0	1	1	1	Testing
48	1	10	1	2	2025-09-11	0	1	1	1	Tested
49	1	15	1	2	2025-09-13	0	1	1	1	Test
50	1	9	1	2	2025-10-24	0	1	1	1	This is the test reason
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: iam; Owner: ak682a
--

COPY iam.permissions (permission_id, permission_name, description) FROM stdin;
1	VIEW_OWN_ROSTER	View personal schedule
2	REQUEST_LEAVE	Request for leave
3	REQUEST_SWAP	Request shift swap
4	VIEW_NOTIFICATIONS	View system alerts
5	SET_SHIFT_PREFERENCES	Set preferred shifts
6	CHAT_IN_APP	Chat with team
7	CREATE_ROSTER	Create roster for team
8	MODIFY_ROSTER	Modify team roster
9	APPROVE_LEAVE	Approve or reject leave requests
10	APPROVE_SWAP	Approve or reject swap requests
11	MANAGE_PROJECTS	Manage assigned projects
12	VIEW_TEAM_ROSTER	View team’s schedule
13	VIEW_ANALYTICS	View analytics for team
14	MANAGE_ALL_PROJECTS	Oversee any project in system
15	MANAGE_USERS	Add/remove system users
16	MANAGE_ROLES	Create/edit roles
17	MANAGE_PERMISSIONS	Grant/revoke permissions
18	UPGRADE_DOWNGRADE_ACCESS	Change user access levels
19	SYSTEM_CONFIGURATION	Modify system-wide settings
20	AUDIT_LOGS	View all system activity logs
21	FULL_ANALYTICS	View organization-wide analytics
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: iam; Owner: ak682a
--

COPY iam.role_permissions (role_id, permission_id) FROM stdin;
1	1
1	2
1	3
1	4
1	5
1	6
2	1
2	2
2	3
2	4
2	5
2	6
2	7
2	8
2	9
2	10
2	11
2	12
2	13
3	1
3	2
3	3
3	4
3	5
3	6
3	7
3	8
3	9
3	10
3	11
3	12
3	13
3	14
3	15
3	16
3	17
3	18
3	19
3	20
3	21
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: iam; Owner: ak682a
--

COPY iam.roles (role_id, role_name, description) FROM stdin;
1	EMPLOYEE	Standard employee
2	MANAGER	Project manager with approvals
3	SUPERADMIN	System-wide admin
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: iam; Owner: ak682a
--

COPY iam.users (user_id, employee_id, username, password_hash, salt, role_id, is_active, last_login) FROM stdin;
2	2	aadhya.gupta2	$2b$10$u7X1oW615ZqctnwX16V.s.O8gqLBxKHNi2Cot/Hu8TZMmgRfajDtG	$2b$10$u7X1oW615ZqctnwX16V.s.	1	t	\N
4	4	sys.admin	$2b$10$u7X1oW615ZqctnwX16V.s.O8gqLBxKHNi2Cot/Hu8TZMmgRfajDtG	$2b$10$u7X1oW615ZqctnwX16V.s.	3	t	\N
1	1	anil.kumar	$2b$10$u7X1oW615ZqctnwX16V.s.O8gqLBxKHNi2Cot/Hu8TZMmgRfajDtG	$2b$10$u7X1oW615ZqctnwX16V.s.	1	t	2025-10-15 19:50:02.345
3	3	aarav.patel3	$2b$10$790LZuvubFesJ46PaFgvY.XDSoFaBF76DruoOWMP4Ws5zfNdZaTv2	$2b$10$790LZuvubFesJ46PaFgvY.	2	t	2025-10-15 20:04:04.592
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: notify; Owner: ak682a
--

COPY notify.notifications (notification_id, employee_id, message, type, created_at, status) FROM stdin;
\.


--
-- Data for Name: employee_skills; Type: TABLE DATA; Schema: organization; Owner: ak682a
--

COPY organization.employee_skills (emp_skill_id, employee_id, skill_id, proficiency_level) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: organization; Owner: ak682a
--

COPY organization.employees (employee_id, first_name, last_name, email, role_id, date_joined, status, job_title) FROM stdin;
1	Anil	Kumar	anil.kumar@example.com	1	2022-03-07	Active	Engineer
2	Aadhya	Gupta	aadhya.gupta2@example.com	1	2022-05-21	Active	Engineer
4	Ishaan	Das	ishaan.das4@example.com	1	2022-04-11	Active	Engineer
5	Aarohi	Iyer	aarohi.iyer5@example.com	1	2022-02-20	Active	Engineer
6	Aarav	Das	aarav.das6@example.com	1	2022-01-17	Active	Engineer
7	Arjun	Naidu	arjun.naidu7@example.com	1	2022-05-28	Active	Engineer
8	Sai	Patel	sai.patel8@example.com	1	2022-08-17	Active	Engineer
9	Vivaan	Singh	vivaan.singh9@example.com	1	2022-08-22	Active	Engineer
10	Aditya	Khan	aditya.khan10@example.com	1	2022-06-13	Active	Engineer
11	Pari	Verma	pari.verma11@example.com	1	2022-11-23	Active	Engineer
12	Vivaan	Das	vivaan.das12@example.com	2	2022-03-17	Active	Team Lead
13	Krishna	Verma	krishna.verma13@example.com	1	2022-04-30	Active	Engineer
14	Myra	Verma	myra.verma14@example.com	1	2022-04-30	Active	Engineer
15	Arjun	Khan	arjun.khan15@example.com	1	2022-06-25	Active	Engineer
16	Aarohi	Khan	aarohi.khan16@example.com	1	2022-09-10	Active	Engineer
17	Vivaan	Khan	vivaan.khan17@example.com	2	2022-09-06	Active	Team Lead
18	Sara	Verma	sara.verma18@example.com	1	2022-05-11	Active	Engineer
19	Aarohi	Reddy	aarohi.reddy19@example.com	1	2022-01-31	Active	Engineer
20	Anika	Naidu	anika.naidu20@example.com	1	2022-01-25	Active	Engineer
21	Pari	Khan	pari.khan21@example.com	1	2022-11-17	Active	Engineer
22	Aditya	Iyer	aditya.iyer22@example.com	1	2022-07-22	Active	Engineer
23	Aadhya	Patel	aadhya.patel23@example.com	1	2022-05-19	Active	Engineer
24	Kabir	Verma	kabir.verma24@example.com	1	2022-07-26	Active	Engineer
25	Krishna	Patel	krishna.patel25@example.com	1	2022-05-30	Active	Engineer
26	Aadhya	Khan	aadhya.khan26@example.com	1	2022-02-12	Active	Engineer
27	Sara	Gupta	sara.gupta27@example.com	1	2022-11-18	Active	Engineer
28	Pari	Reddy	pari.reddy28@example.com	1	2022-11-16	Active	Engineer
29	Sara	Sharma	sara.sharma29@example.com	1	2022-08-11	Active	Engineer
30	Diya	Sharma	diya.sharma30@example.com	1	2022-05-18	Active	Engineer
31	Reyansh	Singh	reyansh.singh31@example.com	1	2022-10-11	Active	Engineer
32	Zara	Iyer	zara.iyer32@example.com	1	2022-09-02	Active	Engineer
33	Aditya	Ghosh	aditya.ghosh33@example.com	1	2022-07-15	Active	Engineer
34	Vivaan	Reddy	vivaan.reddy34@example.com	1	2022-07-14	Active	Engineer
35	Anika	Patel	anika.patel35@example.com	1	2022-01-28	Active	Engineer
36	Vivaan	Khan	vivaan.khan36@example.com	1	2022-04-11	Active	Engineer
37	Aadhya	Iyer	aadhya.iyer37@example.com	1	2022-06-12	Active	Engineer
38	Kabir	Naidu	kabir.naidu38@example.com	1	2022-04-03	Active	Engineer
39	Anika	Iyer	anika.iyer39@example.com	1	2022-09-08	Active	Engineer
40	Myra	Khan	myra.khan40@example.com	1	2022-05-30	Active	Engineer
41	Sai	Iyer	sai.iyer41@example.com	1	2022-08-12	Active	Engineer
42	Aarohi	Sharma	aarohi.sharma42@example.com	1	2022-07-18	Active	Engineer
43	Anaya	Gupta	anaya.gupta43@example.com	1	2022-08-01	Active	Engineer
44	Aarav	Khan	aarav.khan44@example.com	1	2022-11-12	Active	Engineer
45	Krishna	Singh	krishna.singh45@example.com	1	2022-10-04	Active	Engineer
46	Aadhya	Khan	aadhya.khan46@example.com	1	2022-03-20	Active	Engineer
47	Arjun	Sharma	arjun.sharma47@example.com	1	2022-06-20	Active	Engineer
48	Ishaan	Das	ishaan.das48@example.com	1	2022-10-03	Active	Engineer
49	Krishna	Khan	krishna.khan49@example.com	1	2022-03-20	Active	Engineer
50	Anika	Naidu	anika.naidu50@example.com	1	2022-01-15	Active	Engineer
51	Aadhya	Menon	aadhya.menon51@example.com	1	2022-04-19	Active	Engineer
52	Sai	Naidu	sai.naidu52@example.com	1	2022-07-06	Active	Engineer
53	Aarohi	Sharma	aarohi.sharma53@example.com	2	2022-07-13	Active	Team Lead
54	Anaya	Khan	anaya.khan54@example.com	1	2022-01-09	Active	Engineer
55	Myra	Ghosh	myra.ghosh55@example.com	1	2022-08-15	Active	Engineer
56	Kabir	Khan	kabir.khan56@example.com	1	2022-07-25	Active	Engineer
57	Aarav	Das	aarav.das57@example.com	1	2022-12-01	Active	Engineer
58	Aarav	Gupta	aarav.gupta58@example.com	1	2022-02-20	Active	Engineer
59	Ishaan	Reddy	ishaan.reddy59@example.com	1	2022-09-23	Active	Engineer
60	Krishna	Iyer	krishna.iyer60@example.com	1	2022-04-24	Active	Engineer
61	Anika	Sharma	anika.sharma61@example.com	1	2022-02-19	Active	Engineer
62	Ira	Singh	ira.singh62@example.com	1	2022-07-23	Active	Engineer
63	Vivaan	Reddy	vivaan.reddy63@example.com	1	2022-04-26	Active	Engineer
64	Ira	Verma	ira.verma64@example.com	1	2022-05-09	Active	Engineer
65	Reyansh	Singh	reyansh.singh65@example.com	2	2022-02-20	Active	Team Lead
66	Aadhya	Patel	aadhya.patel66@example.com	1	2022-01-10	Active	Engineer
67	Pari	Singh	pari.singh67@example.com	1	2022-09-11	Active	Engineer
68	Aarav	Ghosh	aarav.ghosh68@example.com	1	2022-09-14	Active	Engineer
69	Aarav	Sharma	aarav.sharma69@example.com	1	2022-10-26	Active	Engineer
70	Diya	Khan	diya.khan70@example.com	1	2022-08-22	Active	Engineer
71	Pari	Verma	pari.verma71@example.com	1	2022-06-05	Active	Engineer
72	Reyansh	Menon	reyansh.menon72@example.com	1	2022-07-17	Active	Engineer
73	Zara	Naidu	zara.naidu73@example.com	1	2022-01-18	Active	Engineer
74	Aarohi	Verma	aarohi.verma74@example.com	1	2022-08-16	Active	Engineer
75	Zara	Singh	zara.singh75@example.com	1	2022-05-15	Active	Engineer
76	Ira	Iyer	ira.iyer76@example.com	1	2022-10-27	Active	Engineer
77	Diya	Patel	diya.patel77@example.com	1	2022-06-20	Active	Engineer
78	Aditya	Das	aditya.das78@example.com	1	2022-06-15	Active	Engineer
79	Arjun	Das	arjun.das79@example.com	1	2022-10-17	Active	Engineer
80	Kabir	Menon	kabir.menon80@example.com	1	2022-09-01	Active	Engineer
81	Diya	Patel	diya.patel81@example.com	1	2022-09-03	Active	Engineer
82	Aarav	Iyer	aarav.iyer82@example.com	1	2022-03-28	Active	Engineer
83	Aarohi	Naidu	aarohi.naidu83@example.com	1	2022-03-29	Active	Engineer
84	Sai	Sharma	sai.sharma84@example.com	1	2022-02-01	Active	Engineer
85	Anaya	Naidu	anaya.naidu85@example.com	1	2022-08-02	Active	Engineer
86	Anaya	Verma	anaya.verma86@example.com	1	2022-08-10	Active	Engineer
87	Aarav	Patel	aarav.patel87@example.com	1	2022-05-29	Active	Engineer
88	Ishaan	Iyer	ishaan.iyer88@example.com	1	2022-04-25	Active	Engineer
89	Kabir	Iyer	kabir.iyer89@example.com	1	2022-03-13	Active	Engineer
90	Arjun	Khan	arjun.khan90@example.com	1	2022-06-15	Active	Engineer
91	Sai	Khan	sai.khan91@example.com	1	2022-04-09	Active	Engineer
92	Pari	Singh	pari.singh92@example.com	1	2022-03-21	Active	Engineer
93	Krishna	Naidu	krishna.naidu93@example.com	1	2022-04-11	Active	Engineer
94	Vivaan	Iyer	vivaan.iyer94@example.com	1	2022-05-08	Active	Engineer
95	Zara	Ghosh	zara.ghosh95@example.com	1	2022-05-14	Active	Engineer
96	Sara	Das	sara.das96@example.com	1	2022-04-21	Active	Engineer
97	Vivaan	Verma	vivaan.verma97@example.com	1	2022-02-22	Active	Engineer
98	Ira	Das	ira.das98@example.com	1	2022-06-26	Active	Engineer
99	Aadhya	Ghosh	aadhya.ghosh99@example.com	1	2022-11-24	Active	Engineer
100	Anaya	Naidu	anaya.naidu100@example.com	1	2022-06-01	Active	Engineer
101	Kabir	Gupta	kabir.gupta101@example.com	1	2022-09-24	Active	Engineer
102	Anika	Iyer	anika.iyer102@example.com	1	2022-02-27	Active	Engineer
103	Arjun	Menon	arjun.menon103@example.com	1	2022-03-24	Active	Engineer
104	Vivaan	Reddy	vivaan.reddy104@example.com	1	2022-05-30	Active	Engineer
105	Kabir	Reddy	kabir.reddy105@example.com	1	2022-01-15	Active	Engineer
106	Aarohi	Menon	aarohi.menon106@example.com	1	2022-05-17	Active	Engineer
107	Aarohi	Patel	aarohi.patel107@example.com	2	2022-09-18	Active	Team Lead
108	Arjun	Menon	arjun.menon108@example.com	1	2022-01-08	Active	Engineer
109	Vivaan	Das	vivaan.das109@example.com	1	2022-01-25	Active	Engineer
110	Pari	Reddy	pari.reddy110@example.com	1	2022-04-29	Active	Engineer
111	Aarohi	Das	aarohi.das111@example.com	1	2022-07-21	Active	Engineer
112	Anaya	Reddy	anaya.reddy112@example.com	1	2022-05-22	Active	Engineer
113	Anika	Reddy	anika.reddy113@example.com	1	2022-05-12	Active	Engineer
114	Sai	Gupta	sai.gupta114@example.com	1	2022-08-19	Active	Engineer
115	Ishaan	Verma	ishaan.verma115@example.com	1	2022-07-18	Active	Engineer
116	Sara	Sharma	sara.sharma116@example.com	1	2022-01-02	Active	Engineer
117	Aadhya	Ghosh	aadhya.ghosh117@example.com	1	2022-06-29	Active	Engineer
118	Arjun	Menon	arjun.menon118@example.com	1	2022-08-16	Active	Engineer
119	Aarav	Khan	aarav.khan119@example.com	1	2022-06-28	Active	Engineer
120	Vivaan	Sharma	vivaan.sharma120@example.com	1	2022-09-06	Active	Engineer
121	Reyansh	Gupta	reyansh.gupta121@example.com	1	2022-08-24	Active	Engineer
122	Kabir	Iyer	kabir.iyer122@example.com	1	2022-08-30	Active	Engineer
123	Kabir	Khan	kabir.khan123@example.com	2	2022-11-21	Active	Team Lead
124	Aarohi	Verma	aarohi.verma124@example.com	1	2022-05-30	Active	Engineer
125	Anika	Khan	anika.khan125@example.com	1	2022-08-22	Active	Engineer
126	Myra	Verma	myra.verma126@example.com	1	2022-03-07	Active	Engineer
127	Aarav	Das	aarav.das127@example.com	1	2022-09-29	Active	Engineer
128	Pari	Khan	pari.khan128@example.com	1	2022-03-28	Active	Engineer
129	Kabir	Naidu	kabir.naidu129@example.com	1	2022-06-03	Active	Engineer
130	Pari	Reddy	pari.reddy130@example.com	1	2022-03-13	Active	Engineer
131	Aarav	Ghosh	aarav.ghosh131@example.com	1	2022-07-13	Active	Engineer
132	Aarav	Gupta	aarav.gupta132@example.com	1	2022-03-26	Active	Engineer
133	Aadhya	Ghosh	aadhya.ghosh133@example.com	1	2022-10-11	Active	Engineer
134	Diya	Khan	diya.khan134@example.com	1	2022-05-09	Active	Engineer
135	Aarohi	Patel	aarohi.patel135@example.com	1	2022-10-27	Active	Engineer
136	Arjun	Patel	arjun.patel136@example.com	1	2022-11-01	Active	Engineer
137	Krishna	Verma	krishna.verma137@example.com	1	2022-04-30	Active	Engineer
138	Aditya	Sharma	aditya.sharma138@example.com	1	2022-11-28	Active	Engineer
139	Krishna	Sharma	krishna.sharma139@example.com	1	2022-10-06	Active	Engineer
140	Ira	Singh	ira.singh140@example.com	1	2022-01-04	Active	Engineer
141	Aarav	Singh	aarav.singh141@example.com	2	2022-08-08	Active	Team Lead
142	Ira	Naidu	ira.naidu142@example.com	1	2022-01-14	Active	Engineer
143	Reyansh	Naidu	reyansh.naidu143@example.com	1	2022-06-13	Active	Engineer
144	Diya	Das	diya.das144@example.com	1	2022-02-27	Active	Engineer
145	Anaya	Iyer	anaya.iyer145@example.com	1	2022-05-16	Active	Engineer
146	Aditya	Das	aditya.das146@example.com	1	2022-01-26	Active	Engineer
147	Anaya	Sharma	anaya.sharma147@example.com	1	2022-05-31	Active	Engineer
148	Arjun	Menon	arjun.menon148@example.com	1	2022-10-01	Active	Engineer
149	Anika	Singh	anika.singh149@example.com	1	2022-09-24	Active	Engineer
150	Ishaan	Sharma	ishaan.sharma150@example.com	1	2022-08-23	Active	Engineer
151	Krishna	Verma	krishna.verma151@example.com	1	2022-03-30	Active	Engineer
152	Diya	Ghosh	diya.ghosh152@example.com	1	2022-06-11	Active	Engineer
153	Pari	Patel	pari.patel153@example.com	1	2022-06-12	Active	Engineer
154	Aarohi	Reddy	aarohi.reddy154@example.com	1	2022-03-29	Active	Engineer
155	Anaya	Iyer	anaya.iyer155@example.com	2	2022-01-17	Active	Team Lead
156	Zara	Singh	zara.singh156@example.com	1	2022-05-31	Active	Engineer
157	Aditya	Iyer	aditya.iyer157@example.com	1	2022-06-11	Active	Engineer
158	Pari	Menon	pari.menon158@example.com	1	2022-01-23	Active	Engineer
159	Ira	Gupta	ira.gupta159@example.com	1	2022-03-01	Active	Engineer
160	Myra	Ghosh	myra.ghosh160@example.com	1	2022-07-13	Active	Engineer
161	Ishaan	Patel	ishaan.patel161@example.com	1	2022-05-02	Active	Engineer
162	Vihaan	Verma	vihaan.verma162@example.com	1	2022-02-05	Active	Engineer
163	Anika	Gupta	anika.gupta163@example.com	1	2022-05-31	Active	Engineer
164	Zara	Gupta	zara.gupta164@example.com	1	2022-01-31	Active	Engineer
165	Aarohi	Singh	aarohi.singh165@example.com	1	2022-07-14	Active	Engineer
166	Pari	Patel	pari.patel166@example.com	1	2022-06-27	Active	Engineer
167	Aadhya	Patel	aadhya.patel167@example.com	2	2022-06-16	Active	Team Lead
168	Sara	Singh	sara.singh168@example.com	1	2022-04-11	Active	Engineer
169	Aditya	Gupta	aditya.gupta169@example.com	1	2022-01-17	Active	Engineer
170	Pari	Iyer	pari.iyer170@example.com	1	2022-06-20	Active	Engineer
171	Aarohi	Patel	aarohi.patel171@example.com	1	2022-01-21	Active	Engineer
172	Aadhya	Gupta	aadhya.gupta172@example.com	1	2022-07-04	Active	Engineer
173	Anaya	Patel	anaya.patel173@example.com	1	2022-01-08	Active	Engineer
174	Pari	Sharma	pari.sharma174@example.com	1	2022-03-13	Active	Engineer
175	Anaya	Das	anaya.das175@example.com	1	2022-03-02	Active	Engineer
176	Aditya	Das	aditya.das176@example.com	1	2022-03-08	Active	Engineer
177	Vihaan	Menon	vihaan.menon177@example.com	1	2022-09-10	Active	Engineer
178	Anika	Verma	anika.verma178@example.com	2	2022-06-26	Active	Team Lead
179	Sai	Naidu	sai.naidu179@example.com	1	2022-08-07	Active	Engineer
180	Kabir	Verma	kabir.verma180@example.com	1	2022-08-05	Active	Engineer
181	Reyansh	Iyer	reyansh.iyer181@example.com	1	2022-07-15	Active	Engineer
182	Vihaan	Das	vihaan.das182@example.com	1	2022-08-16	Active	Engineer
183	Ira	Gupta	ira.gupta183@example.com	1	2022-04-01	Active	Engineer
184	Kabir	Naidu	kabir.naidu184@example.com	1	2022-09-26	Active	Engineer
185	Anika	Reddy	anika.reddy185@example.com	1	2022-04-21	Active	Engineer
186	Myra	Reddy	myra.reddy186@example.com	1	2022-06-01	Active	Engineer
187	Ishaan	Ghosh	ishaan.ghosh187@example.com	1	2022-08-24	Active	Engineer
188	Krishna	Singh	krishna.singh188@example.com	1	2022-03-08	Active	Engineer
189	Anika	Khan	anika.khan189@example.com	1	2022-01-21	Active	Engineer
190	Anaya	Patel	anaya.patel190@example.com	1	2022-05-12	Active	Engineer
191	Kabir	Gupta	kabir.gupta191@example.com	1	2022-11-20	Active	Engineer
192	Aditya	Das	aditya.das192@example.com	1	2022-07-06	Active	Engineer
193	Pari	Das	pari.das193@example.com	1	2022-07-07	Active	Engineer
194	Anika	Gupta	anika.gupta194@example.com	1	2022-03-11	Active	Engineer
195	Diya	Singh	diya.singh195@example.com	1	2022-06-25	Active	Engineer
196	Sai	Menon	sai.menon196@example.com	1	2022-04-30	Active	Engineer
197	Diya	Sharma	diya.sharma197@example.com	1	2022-09-21	Active	Engineer
198	Vivaan	Naidu	vivaan.naidu198@example.com	1	2022-10-04	Active	Engineer
199	Sara	Menon	sara.menon199@example.com	1	2022-07-30	Active	Engineer
200	Sai	Iyer	sai.iyer200@example.com	1	2022-10-01	Active	Engineer
201	Zara	Reddy	zara.reddy201@example.com	1	2022-03-15	Active	Engineer
202	Anika	Menon	anika.menon202@example.com	1	2022-01-29	Active	Engineer
203	Aditya	Iyer	aditya.iyer203@example.com	1	2022-09-19	Active	Engineer
204	Krishna	Reddy	krishna.reddy204@example.com	1	2022-03-07	Active	Engineer
205	Ishaan	Khan	ishaan.khan205@example.com	1	2022-05-29	Active	Engineer
206	Reyansh	Gupta	reyansh.gupta206@example.com	1	2022-08-18	Active	Engineer
207	Zara	Verma	zara.verma207@example.com	1	2022-08-02	Active	Engineer
208	Ishaan	Sharma	ishaan.sharma208@example.com	1	2022-03-04	Active	Engineer
209	Zara	Naidu	zara.naidu209@example.com	1	2022-10-08	Active	Engineer
210	Anika	Singh	anika.singh210@example.com	1	2022-03-11	Active	Engineer
211	Sai	Singh	sai.singh211@example.com	1	2022-01-07	Active	Engineer
212	Vivaan	Reddy	vivaan.reddy212@example.com	1	2022-07-01	Active	Engineer
213	Aarav	Naidu	aarav.naidu213@example.com	1	2022-05-20	Active	Engineer
214	Aadhya	Reddy	aadhya.reddy214@example.com	2	2022-10-20	Active	Team Lead
215	Aditya	Khan	aditya.khan215@example.com	1	2022-03-10	Active	Engineer
216	Myra	Khan	myra.khan216@example.com	1	2022-02-24	Active	Engineer
217	Pari	Khan	pari.khan217@example.com	1	2022-11-28	Active	Engineer
218	Sara	Patel	sara.patel218@example.com	1	2022-05-04	Active	Engineer
219	Arjun	Sharma	arjun.sharma219@example.com	1	2022-06-14	Active	Engineer
220	Aditya	Khan	aditya.khan220@example.com	2	2022-01-18	Active	Team Lead
221	Ishaan	Menon	ishaan.menon221@example.com	1	2022-08-12	Active	Engineer
222	Kabir	Reddy	kabir.reddy222@example.com	1	2022-07-12	Active	Engineer
223	Sara	Ghosh	sara.ghosh223@example.com	2	2022-05-15	Active	Team Lead
224	Sara	Verma	sara.verma224@example.com	1	2022-11-09	Active	Engineer
225	Kabir	Das	kabir.das225@example.com	1	2022-05-30	Active	Engineer
226	Kabir	Patel	kabir.patel226@example.com	1	2022-10-21	Active	Engineer
227	Vihaan	Sharma	vihaan.sharma227@example.com	1	2022-10-05	Active	Engineer
228	Arjun	Verma	arjun.verma228@example.com	1	2022-01-28	Active	Engineer
229	Arjun	Gupta	arjun.gupta229@example.com	1	2022-03-20	Active	Engineer
230	Zara	Gupta	zara.gupta230@example.com	1	2022-09-03	Active	Engineer
231	Zara	Patel	zara.patel231@example.com	1	2022-08-10	Active	Engineer
232	Pari	Sharma	pari.sharma232@example.com	1	2022-09-19	Active	Engineer
233	Kabir	Naidu	kabir.naidu233@example.com	1	2022-02-14	Active	Engineer
234	Myra	Ghosh	myra.ghosh234@example.com	1	2022-06-18	Active	Engineer
235	Sai	Menon	sai.menon235@example.com	1	2022-11-27	Active	Engineer
236	Kabir	Reddy	kabir.reddy236@example.com	1	2022-04-24	Active	Engineer
237	Reyansh	Gupta	reyansh.gupta237@example.com	1	2022-11-22	Active	Engineer
238	Aarohi	Patel	aarohi.patel238@example.com	1	2022-06-02	Active	Engineer
239	Kabir	Verma	kabir.verma239@example.com	1	2022-01-23	Active	Engineer
240	Anika	Patel	anika.patel240@example.com	2	2022-05-04	Active	Team Lead
241	Aadhya	Patel	aadhya.patel241@example.com	1	2022-11-12	Active	Engineer
242	Ira	Menon	ira.menon242@example.com	1	2022-03-02	Active	Engineer
243	Sara	Singh	sara.singh243@example.com	1	2022-02-21	Active	Engineer
244	Aarav	Menon	aarav.menon244@example.com	1	2022-01-17	Active	Engineer
245	Zara	Patel	zara.patel245@example.com	1	2022-09-22	Active	Engineer
246	Vivaan	Patel	vivaan.patel246@example.com	1	2022-08-02	Active	Engineer
247	Zara	Das	zara.das247@example.com	2	2022-08-20	Active	Team Lead
248	Vihaan	Verma	vihaan.verma248@example.com	1	2022-10-30	Active	Engineer
249	Aarohi	Gupta	aarohi.gupta249@example.com	1	2022-04-26	Active	Engineer
250	Anaya	Menon	anaya.menon250@example.com	2	2022-11-09	Active	Team Lead
251	Diya	Iyer	diya.iyer251@example.com	1	2022-05-25	Active	Engineer
252	Anaya	Patel	anaya.patel252@example.com	1	2022-11-06	Active	Engineer
253	Anaya	Das	anaya.das253@example.com	1	2022-04-01	Active	Engineer
254	Reyansh	Iyer	reyansh.iyer254@example.com	1	2022-01-19	Active	Engineer
255	Aditya	Verma	aditya.verma255@example.com	2	2022-04-01	Active	Team Lead
256	Anika	Gupta	anika.gupta256@example.com	2	2022-03-14	Active	Team Lead
257	Reyansh	Das	reyansh.das257@example.com	1	2022-04-07	Active	Engineer
258	Zara	Reddy	zara.reddy258@example.com	1	2022-06-13	Active	Engineer
259	Reyansh	Das	reyansh.das259@example.com	1	2022-09-24	Active	Engineer
260	Ira	Das	ira.das260@example.com	1	2022-09-07	Active	Engineer
261	System	Admin	sys.admin@example.com	3	2023-01-01	Active	Administrator
3	Aarav	Patel	aarav.patel3@example.com	2	2022-03-30	Active	Engineer
\.


--
-- Data for Name: manager_projects; Type: TABLE DATA; Schema: organization; Owner: ak682a
--

COPY organization.manager_projects (manager_project_id, manager_id, project_id) FROM stdin;
1	3	1
2	3	2
3	3	3
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: organization; Owner: ak682a
--

COPY organization.projects (project_id, project_name, description, status) FROM stdin;
1	Network Monitoring Dashboard	Real-time monitoring of network elements and service health	1
2	Maintenance Automation Engine	Automated fault detection and remediation workflows	1
3	Access Control Portal	Role-based user management and secure access provisioning	1
4	Performance Reporting Module	Scheduled analytics and KPI reporting for network performance	1
5	Topology Visualization Tool	Interactive graphical view of network topology	1
6	Incident Alert System	Real-time alerts and notifications for network incidents	1
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: organization; Owner: ak682a
--

COPY organization.skills (skill_id, skill_name, description) FROM stdin;
1	DEV_BACKEND	Backend development
2	DEV_FRONTEND	Frontend development
3	QA	Quality engineering
4	DBA	Database administration
5	SYSADMIN	System administration
6	SRE	Site Reliability Engineering
7	MOBILE	iOS/Android Development
8	DATA	Data engineering/analytics
\.


--
-- Data for Name: assignments; Type: TABLE DATA; Schema: schedule; Owner: ak682a
--

COPY schedule.assignments (assignment_id, employee_id, project_id, group_id, shift_id, assignment_date, hours_planned, overlap_minutes, status) FROM stdin;
1	1	1	1	1	2025-08-31	9	1	
2	1	1	1	1	2025-09-01	9	1	
3	1	1	1	1	2025-09-02	9	1	
4	1	1	1	1	2025-09-03	9	1	
5	1	1	1	1	2025-09-04	9	1	
6	1	1	1	1	2025-09-05	9	1	weekoffs
7	1	1	1	1	2025-09-06	9	1	weekoffs
8	1	1	1	1	2025-09-07	9	1	
9	1	1	1	1	2025-09-08	9	1	
10	1	1	1	1	2025-09-09	9	1	
11	1	1	1	1	2025-09-10	9	1	
12	1	1	1	1	2025-09-11	9	1	
13	1	1	1	1	2025-09-12	9	1	weekoffs
14	1	1	1	1	2025-09-13	9	1	weekoffs
15	1	1	1	1	2025-09-14	9	1	
16	1	1	1	1	2025-09-15	9	1	
17	1	1	1	1	2025-09-16	9	1	
18	1	1	1	1	2025-09-17	9	1	
19	1	1	1	1	2025-09-18	9	1	
20	1	1	1	1	2025-09-19	9	1	weekoffs
21	1	1	1	1	2025-09-20	9	1	weekoffs
22	1	1	1	1	2025-09-21	9	1	
23	1	1	1	1	2025-09-22	9	1	
24	1	1	1	1	2025-09-23	9	1	
25	1	1	1	1	2025-09-24	9	1	
26	1	1	1	1	2025-09-25	9	1	
27	1	1	1	1	2025-09-26	9	1	weekoffs
28	1	1	1	1	2025-09-27	9	1	weekoffs
29	1	1	1	1	2025-09-28	9	1	
30	1	1	1	1	2025-09-29	9	1	
31	2	1	1	1	2025-08-31	9	1	
32	2	1	1	1	2025-09-01	9	1	
33	2	1	1	1	2025-09-02	9	1	
34	2	1	1	1	2025-09-03	9	1	
35	2	1	1	1	2025-09-04	9	1	
36	2	1	1	1	2025-09-05	9	1	weekoffs
37	2	1	1	1	2025-09-06	9	1	weekoffs
38	2	1	1	1	2025-09-07	9	1	
39	2	1	1	1	2025-09-08	9	1	
40	2	1	1	1	2025-09-09	9	1	
41	2	1	1	1	2025-09-10	9	1	
42	2	1	1	1	2025-09-11	9	1	
43	2	1	1	1	2025-09-12	9	1	weekoffs
44	2	1	1	1	2025-09-13	9	1	weekoffs
45	2	1	1	1	2025-09-14	9	1	
46	2	1	1	1	2025-09-15	9	1	
47	2	1	1	1	2025-09-16	9	1	
48	2	1	1	1	2025-09-17	9	1	
49	2	1	1	1	2025-09-18	9	1	
50	2	1	1	1	2025-09-19	9	1	weekoffs
51	2	1	1	1	2025-09-20	9	1	weekoffs
52	2	1	1	1	2025-09-21	9	1	
53	2	1	1	1	2025-09-22	9	1	
54	2	1	1	1	2025-09-23	9	1	
55	2	1	1	1	2025-09-24	9	1	
56	2	1	1	1	2025-09-25	9	1	
57	2	1	1	1	2025-09-26	9	1	weekoffs
58	2	1	1	1	2025-09-27	9	1	weekoffs
59	2	1	1	1	2025-09-28	9	1	
60	2	1	1	1	2025-09-29	9	1	
61	3	1	1	2	2025-08-31	9	1	
62	3	1	1	2	2025-09-01	9	1	
63	3	1	1	2	2025-09-02	9	1	
64	3	1	1	2	2025-09-03	9	1	
65	3	1	1	2	2025-09-04	9	1	
66	3	1	1	2	2025-09-05	9	1	weekoffs
67	3	1	1	2	2025-09-06	9	1	weekoffs
68	3	1	1	2	2025-09-07	9	1	
69	3	1	1	2	2025-09-08	9	1	
70	3	1	1	2	2025-09-09	9	1	
71	3	1	1	2	2025-09-10	9	1	
72	3	1	1	2	2025-09-11	9	1	
73	3	1	1	2	2025-09-12	9	1	weekoffs
74	3	1	1	2	2025-09-13	9	1	weekoffs
75	3	1	1	2	2025-09-14	9	1	
76	3	1	1	2	2025-09-15	9	1	
77	3	1	1	2	2025-09-16	9	1	
78	3	1	1	2	2025-09-17	9	1	
79	3	1	1	2	2025-09-18	9	1	
80	3	1	1	2	2025-09-19	9	1	weekoffs
81	3	1	1	2	2025-09-20	9	1	weekoffs
82	3	1	1	2	2025-09-21	9	1	
83	3	1	1	2	2025-09-22	9	1	
84	3	1	1	2	2025-09-23	9	1	
85	3	1	1	2	2025-09-24	9	1	
86	3	1	1	2	2025-09-25	9	1	
87	3	1	1	2	2025-09-26	9	1	weekoffs
88	3	1	1	2	2025-09-27	9	1	weekoffs
89	3	1	1	2	2025-09-28	9	1	
90	3	1	1	2	2025-09-29	9	1	
91	4	1	1	2	2025-08-31	9	1	
92	4	1	1	2	2025-09-01	9	1	
93	4	1	1	2	2025-09-02	9	1	
94	4	1	1	2	2025-09-03	9	1	
95	4	1	1	2	2025-09-04	9	1	
96	4	1	1	2	2025-09-05	9	1	weekoffs
97	4	1	1	2	2025-09-06	9	1	weekoffs
98	4	1	1	2	2025-09-07	9	1	
99	4	1	1	2	2025-09-08	9	1	
100	4	1	1	2	2025-09-09	9	1	
101	4	1	1	2	2025-09-10	9	1	
102	4	1	1	2	2025-09-11	9	1	
103	4	1	1	2	2025-09-12	9	1	weekoffs
104	4	1	1	2	2025-09-13	9	1	weekoffs
105	4	1	1	2	2025-09-14	9	1	
106	4	1	1	2	2025-09-15	9	1	
107	4	1	1	2	2025-09-16	9	1	
108	4	1	1	2	2025-09-17	9	1	
109	4	1	1	2	2025-09-18	9	1	
110	4	1	1	2	2025-09-19	9	1	weekoffs
111	4	1	1	2	2025-09-20	9	1	weekoffs
112	4	1	1	2	2025-09-21	9	1	
113	4	1	1	2	2025-09-22	9	1	
114	4	1	1	2	2025-09-23	9	1	
115	4	1	1	2	2025-09-24	9	1	
116	4	1	1	2	2025-09-25	9	1	
117	4	1	1	2	2025-09-26	9	1	weekoffs
118	4	1	1	2	2025-09-27	9	1	weekoffs
119	4	1	1	2	2025-09-28	9	1	
120	4	1	1	2	2025-09-29	9	1	
121	5	1	1	3	2025-08-31	9	1	
122	5	1	1	3	2025-09-01	9	1	
123	5	1	1	3	2025-09-02	9	1	
124	5	1	1	3	2025-09-03	9	1	
125	5	1	1	3	2025-09-04	9	1	
126	5	1	1	3	2025-09-05	9	1	weekoffs
127	5	1	1	3	2025-09-06	9	1	weekoffs
128	5	1	1	3	2025-09-07	9	1	
129	5	1	1	3	2025-09-08	9	1	
130	5	1	1	3	2025-09-09	9	1	
131	5	1	1	3	2025-09-10	9	1	
132	5	1	1	3	2025-09-11	9	1	
133	5	1	1	3	2025-09-12	9	1	weekoffs
134	5	1	1	3	2025-09-13	9	1	weekoffs
135	5	1	1	3	2025-09-14	9	1	
136	5	1	1	3	2025-09-15	9	1	
137	5	1	1	3	2025-09-16	9	1	
138	5	1	1	3	2025-09-17	9	1	
139	5	1	1	3	2025-09-18	9	1	
140	5	1	1	3	2025-09-19	9	1	weekoffs
141	5	1	1	3	2025-09-20	9	1	weekoffs
142	5	1	1	3	2025-09-21	9	1	
143	5	1	1	3	2025-09-22	9	1	
144	5	1	1	3	2025-09-23	9	1	
145	5	1	1	3	2025-09-24	9	1	
146	5	1	1	3	2025-09-25	9	1	
147	5	1	1	3	2025-09-26	9	1	weekoffs
148	5	1	1	3	2025-09-27	9	1	weekoffs
149	5	1	1	3	2025-09-28	9	1	
150	5	1	1	3	2025-09-29	9	1	
151	6	1	1	3	2025-08-31	9	1	
152	6	1	1	3	2025-09-01	9	1	
153	6	1	1	3	2025-09-02	9	1	
154	6	1	1	3	2025-09-03	9	1	
155	6	1	1	3	2025-09-04	9	1	
156	6	1	1	3	2025-09-05	9	1	weekoffs
157	6	1	1	3	2025-09-06	9	1	weekoffs
158	6	1	1	3	2025-09-07	9	1	
159	6	1	1	3	2025-09-08	9	1	
160	6	1	1	3	2025-09-09	9	1	
161	6	1	1	3	2025-09-10	9	1	
162	6	1	1	3	2025-09-11	9	1	
163	6	1	1	3	2025-09-12	9	1	weekoffs
164	6	1	1	3	2025-09-13	9	1	weekoffs
165	6	1	1	3	2025-09-14	9	1	
166	6	1	1	3	2025-09-15	9	1	
167	6	1	1	3	2025-09-16	9	1	
168	6	1	1	3	2025-09-17	9	1	
169	6	1	1	3	2025-09-18	9	1	
170	6	1	1	3	2025-09-19	9	1	weekoffs
171	6	1	1	3	2025-09-20	9	1	weekoffs
172	6	1	1	3	2025-09-21	9	1	
173	6	1	1	3	2025-09-22	9	1	
174	6	1	1	3	2025-09-23	9	1	
175	6	1	1	3	2025-09-24	9	1	
176	6	1	1	3	2025-09-25	9	1	
177	6	1	1	3	2025-09-26	9	1	weekoffs
178	6	1	1	3	2025-09-27	9	1	weekoffs
179	6	1	1	3	2025-09-28	9	1	
180	6	1	1	3	2025-09-29	9	1	
181	7	1	2	1	2025-08-31	9	1	weekoffs
182	7	1	2	1	2025-09-01	9	1	weekoffs
183	7	1	2	1	2025-09-02	9	1	
184	7	1	2	1	2025-09-03	9	1	
185	7	1	2	1	2025-09-04	9	1	
186	7	1	2	1	2025-09-05	9	1	
187	7	1	2	1	2025-09-06	9	1	
188	7	1	2	1	2025-09-07	9	1	weekoffs
189	7	1	2	1	2025-09-08	9	1	weekoffs
190	7	1	2	1	2025-09-09	9	1	
191	7	1	2	1	2025-09-10	9	1	
192	7	1	2	1	2025-09-11	9	1	
193	7	1	2	1	2025-09-12	9	1	
194	7	1	2	1	2025-09-13	9	1	
195	7	1	2	1	2025-09-14	9	1	weekoffs
196	7	1	2	1	2025-09-15	9	1	weekoffs
197	7	1	2	1	2025-09-16	9	1	
198	7	1	2	1	2025-09-17	9	1	
199	7	1	2	1	2025-09-18	9	1	
200	7	1	2	1	2025-09-19	9	1	
201	7	1	2	1	2025-09-20	9	1	
202	7	1	2	1	2025-09-21	9	1	weekoffs
203	7	1	2	1	2025-09-22	9	1	weekoffs
204	7	1	2	1	2025-09-23	9	1	
205	7	1	2	1	2025-09-24	9	1	
206	7	1	2	1	2025-09-25	9	1	
207	7	1	2	1	2025-09-26	9	1	
208	7	1	2	1	2025-09-27	9	1	
209	7	1	2	1	2025-09-28	9	1	weekoffs
210	7	1	2	1	2025-09-29	9	1	weekoffs
211	8	1	2	1	2025-08-31	9	1	weekoffs
212	8	1	2	1	2025-09-01	9	1	weekoffs
213	8	1	2	1	2025-09-02	9	1	
214	8	1	2	1	2025-09-03	9	1	
215	8	1	2	1	2025-09-04	9	1	
216	8	1	2	1	2025-09-05	9	1	
217	8	1	2	1	2025-09-06	9	1	
218	8	1	2	1	2025-09-07	9	1	weekoffs
219	8	1	2	1	2025-09-08	9	1	weekoffs
220	8	1	2	1	2025-09-09	9	1	
221	8	1	2	1	2025-09-10	9	1	
222	8	1	2	1	2025-09-11	9	1	
223	8	1	2	1	2025-09-12	9	1	
224	8	1	2	1	2025-09-13	9	1	
225	8	1	2	1	2025-09-14	9	1	weekoffs
226	8	1	2	1	2025-09-15	9	1	weekoffs
227	8	1	2	1	2025-09-16	9	1	
228	8	1	2	1	2025-09-17	9	1	
229	8	1	2	1	2025-09-18	9	1	
230	8	1	2	1	2025-09-19	9	1	
231	8	1	2	1	2025-09-20	9	1	
232	8	1	2	1	2025-09-21	9	1	weekoffs
233	8	1	2	1	2025-09-22	9	1	weekoffs
234	8	1	2	1	2025-09-23	9	1	
235	8	1	2	1	2025-09-24	9	1	
236	8	1	2	1	2025-09-25	9	1	
237	8	1	2	1	2025-09-26	9	1	
238	8	1	2	1	2025-09-27	9	1	
239	8	1	2	1	2025-09-28	9	1	weekoffs
240	8	1	2	1	2025-09-29	9	1	weekoffs
241	9	1	2	2	2025-08-31	9	1	weekoffs
242	9	1	2	2	2025-09-01	9	1	weekoffs
243	9	1	2	2	2025-09-02	9	1	
244	9	1	2	2	2025-09-03	9	1	
245	9	1	2	2	2025-09-04	9	1	
246	9	1	2	2	2025-09-05	9	1	
247	9	1	2	2	2025-09-06	9	1	
248	9	1	2	2	2025-09-07	9	1	weekoffs
249	9	1	2	2	2025-09-08	9	1	weekoffs
250	9	1	2	2	2025-09-09	9	1	
251	9	1	2	2	2025-09-10	9	1	
252	9	1	2	2	2025-09-11	9	1	
253	9	1	2	2	2025-09-12	9	1	
254	9	1	2	2	2025-09-13	9	1	
255	9	1	2	2	2025-09-14	9	1	weekoffs
256	9	1	2	2	2025-09-15	9	1	weekoffs
257	9	1	2	2	2025-09-16	9	1	
258	9	1	2	2	2025-09-17	9	1	
259	9	1	2	2	2025-09-18	9	1	
260	9	1	2	2	2025-09-19	9	1	
261	9	1	2	2	2025-09-20	9	1	
262	9	1	2	2	2025-09-21	9	1	weekoffs
263	9	1	2	2	2025-09-22	9	1	weekoffs
264	9	1	2	2	2025-09-23	9	1	
265	9	1	2	2	2025-09-24	9	1	
266	9	1	2	2	2025-09-25	9	1	
267	9	1	2	2	2025-09-26	9	1	
268	9	1	2	2	2025-09-27	9	1	
269	9	1	2	2	2025-09-28	9	1	weekoffs
270	9	1	2	2	2025-09-29	9	1	weekoffs
271	10	1	2	2	2025-08-31	9	1	weekoffs
272	10	1	2	2	2025-09-01	9	1	weekoffs
273	10	1	2	2	2025-09-02	9	1	
274	10	1	2	2	2025-09-03	9	1	
275	10	1	2	2	2025-09-04	9	1	
276	10	1	2	2	2025-09-05	9	1	
277	10	1	2	2	2025-09-06	9	1	
278	10	1	2	2	2025-09-07	9	1	weekoffs
279	10	1	2	2	2025-09-08	9	1	weekoffs
280	10	1	2	2	2025-09-09	9	1	
281	10	1	2	2	2025-09-10	9	1	
282	10	1	2	2	2025-09-11	9	1	
283	10	1	2	2	2025-09-12	9	1	
284	10	1	2	2	2025-09-13	9	1	
285	10	1	2	2	2025-09-14	9	1	weekoffs
286	10	1	2	2	2025-09-15	9	1	weekoffs
287	10	1	2	2	2025-09-16	9	1	
288	10	1	2	2	2025-09-17	9	1	
289	10	1	2	2	2025-09-18	9	1	
290	10	1	2	2	2025-09-19	9	1	
291	10	1	2	2	2025-09-20	9	1	
292	10	1	2	2	2025-09-21	9	1	weekoffs
293	10	1	2	2	2025-09-22	9	1	weekoffs
294	10	1	2	2	2025-09-23	9	1	
295	10	1	2	2	2025-09-24	9	1	
296	10	1	2	2	2025-09-25	9	1	
297	10	1	2	2	2025-09-26	9	1	
298	10	1	2	2	2025-09-27	9	1	
299	10	1	2	2	2025-09-28	9	1	weekoffs
300	10	1	2	2	2025-09-29	9	1	weekoffs
301	11	1	2	3	2025-08-31	9	1	weekoffs
302	11	1	2	3	2025-09-01	9	1	weekoffs
303	11	1	2	3	2025-09-02	9	1	
304	11	1	2	3	2025-09-03	9	1	
305	11	1	2	3	2025-09-04	9	1	
306	11	1	2	3	2025-09-05	9	1	
307	11	1	2	3	2025-09-06	9	1	
308	11	1	2	3	2025-09-07	9	1	weekoffs
309	11	1	2	3	2025-09-08	9	1	weekoffs
310	11	1	2	3	2025-09-09	9	1	
311	11	1	2	3	2025-09-10	9	1	
312	11	1	2	3	2025-09-11	9	1	
313	11	1	2	3	2025-09-12	9	1	
314	11	1	2	3	2025-09-13	9	1	
315	11	1	2	3	2025-09-14	9	1	weekoffs
316	11	1	2	3	2025-09-15	9	1	weekoffs
317	11	1	2	3	2025-09-16	9	1	
318	11	1	2	3	2025-09-17	9	1	
319	11	1	2	3	2025-09-18	9	1	
320	11	1	2	3	2025-09-19	9	1	
321	11	1	2	3	2025-09-20	9	1	
322	11	1	2	3	2025-09-21	9	1	weekoffs
323	11	1	2	3	2025-09-22	9	1	weekoffs
324	11	1	2	3	2025-09-23	9	1	
325	11	1	2	3	2025-09-24	9	1	
326	11	1	2	3	2025-09-25	9	1	
327	11	1	2	3	2025-09-26	9	1	
328	11	1	2	3	2025-09-27	9	1	
329	11	1	2	3	2025-09-28	9	1	weekoffs
330	11	1	2	3	2025-09-29	9	1	weekoffs
331	12	1	2	3	2025-08-31	9	1	weekoffs
332	12	1	2	3	2025-09-01	9	1	weekoffs
333	12	1	2	3	2025-09-02	9	1	
334	12	1	2	3	2025-09-03	9	1	
335	12	1	2	3	2025-09-04	9	1	
336	12	1	2	3	2025-09-05	9	1	
337	12	1	2	3	2025-09-06	9	1	
338	12	1	2	3	2025-09-07	9	1	weekoffs
339	12	1	2	3	2025-09-08	9	1	weekoffs
340	12	1	2	3	2025-09-09	9	1	
341	12	1	2	3	2025-09-10	9	1	
342	12	1	2	3	2025-09-11	9	1	
343	12	1	2	3	2025-09-12	9	1	
344	12	1	2	3	2025-09-13	9	1	
345	12	1	2	3	2025-09-14	9	1	weekoffs
346	12	1	2	3	2025-09-15	9	1	weekoffs
347	12	1	2	3	2025-09-16	9	1	
348	12	1	2	3	2025-09-17	9	1	
349	12	1	2	3	2025-09-18	9	1	
350	12	1	2	3	2025-09-19	9	1	
351	12	1	2	3	2025-09-20	9	1	
352	12	1	2	3	2025-09-21	9	1	weekoffs
353	12	1	2	3	2025-09-22	9	1	weekoffs
354	12	1	2	3	2025-09-23	9	1	
355	12	1	2	3	2025-09-24	9	1	
356	12	1	2	3	2025-09-25	9	1	
357	12	1	2	3	2025-09-26	9	1	
358	12	1	2	3	2025-09-27	9	1	
359	12	1	2	3	2025-09-28	9	1	weekoffs
360	12	1	2	3	2025-09-29	9	1	weekoffs
361	13	1	3	1	2025-08-31	9	1	
362	13	1	3	1	2025-09-01	9	1	
363	13	1	3	1	2025-09-02	9	1	weekoffs
364	13	1	3	1	2025-09-03	9	1	weekoffs
365	13	1	3	1	2025-09-04	9	1	
366	13	1	3	1	2025-09-05	9	1	
367	13	1	3	1	2025-09-06	9	1	
368	13	1	3	1	2025-09-07	9	1	
369	13	1	3	1	2025-09-08	9	1	
370	13	1	3	1	2025-09-09	9	1	weekoffs
371	13	1	3	1	2025-09-10	9	1	weekoffs
372	13	1	3	1	2025-09-11	9	1	
373	13	1	3	1	2025-09-12	9	1	
374	13	1	3	1	2025-09-13	9	1	
375	13	1	3	1	2025-09-14	9	1	
376	13	1	3	1	2025-09-15	9	1	
377	13	1	3	1	2025-09-16	9	1	weekoffs
378	13	1	3	1	2025-09-17	9	1	weekoffs
379	13	1	3	1	2025-09-18	9	1	
380	13	1	3	1	2025-09-19	9	1	
381	13	1	3	1	2025-09-20	9	1	
382	13	1	3	1	2025-09-21	9	1	
383	13	1	3	1	2025-09-22	9	1	
384	13	1	3	1	2025-09-23	9	1	weekoffs
385	13	1	3	1	2025-09-24	9	1	weekoffs
386	13	1	3	1	2025-09-25	9	1	
387	13	1	3	1	2025-09-26	9	1	
388	13	1	3	1	2025-09-27	9	1	
389	13	1	3	1	2025-09-28	9	1	
390	13	1	3	1	2025-09-29	9	1	
391	14	1	3	1	2025-08-31	9	1	
392	14	1	3	1	2025-09-01	9	1	
393	14	1	3	1	2025-09-02	9	1	weekoffs
394	14	1	3	1	2025-09-03	9	1	weekoffs
395	14	1	3	1	2025-09-04	9	1	
396	14	1	3	1	2025-09-05	9	1	
397	14	1	3	1	2025-09-06	9	1	
398	14	1	3	1	2025-09-07	9	1	
399	14	1	3	1	2025-09-08	9	1	
400	14	1	3	1	2025-09-09	9	1	weekoffs
401	14	1	3	1	2025-09-10	9	1	weekoffs
402	14	1	3	1	2025-09-11	9	1	
403	14	1	3	1	2025-09-12	9	1	
404	14	1	3	1	2025-09-13	9	1	
405	14	1	3	1	2025-09-14	9	1	
406	14	1	3	1	2025-09-15	9	1	
407	14	1	3	1	2025-09-16	9	1	weekoffs
408	14	1	3	1	2025-09-17	9	1	weekoffs
409	14	1	3	1	2025-09-18	9	1	
410	14	1	3	1	2025-09-19	9	1	
411	14	1	3	1	2025-09-20	9	1	
412	14	1	3	1	2025-09-21	9	1	
413	14	1	3	1	2025-09-22	9	1	
414	14	1	3	1	2025-09-23	9	1	weekoffs
415	14	1	3	1	2025-09-24	9	1	weekoffs
416	14	1	3	1	2025-09-25	9	1	
417	14	1	3	1	2025-09-26	9	1	
418	14	1	3	1	2025-09-27	9	1	
419	14	1	3	1	2025-09-28	9	1	
420	14	1	3	1	2025-09-29	9	1	
421	15	1	3	2	2025-08-31	9	1	
422	15	1	3	2	2025-09-01	9	1	
423	15	1	3	2	2025-09-02	9	1	weekoffs
424	15	1	3	2	2025-09-03	9	1	weekoffs
425	15	1	3	2	2025-09-04	9	1	
426	15	1	3	2	2025-09-05	9	1	
427	15	1	3	2	2025-09-06	9	1	
428	15	1	3	2	2025-09-07	9	1	
429	15	1	3	2	2025-09-08	9	1	
430	15	1	3	2	2025-09-09	9	1	weekoffs
431	15	1	3	2	2025-09-10	9	1	weekoffs
432	15	1	3	2	2025-09-11	9	1	
433	15	1	3	2	2025-09-12	9	1	
434	15	1	3	2	2025-09-13	9	1	
435	15	1	3	2	2025-09-14	9	1	
436	15	1	3	2	2025-09-15	9	1	
437	15	1	3	2	2025-09-16	9	1	weekoffs
438	15	1	3	2	2025-09-17	9	1	weekoffs
439	15	1	3	2	2025-09-18	9	1	
440	15	1	3	2	2025-09-19	9	1	
441	15	1	3	2	2025-09-20	9	1	
442	15	1	3	2	2025-09-21	9	1	
443	15	1	3	2	2025-09-22	9	1	
444	15	1	3	2	2025-09-23	9	1	weekoffs
445	15	1	3	2	2025-09-24	9	1	weekoffs
446	15	1	3	2	2025-09-25	9	1	
447	15	1	3	2	2025-09-26	9	1	
448	15	1	3	2	2025-09-27	9	1	
449	15	1	3	2	2025-09-28	9	1	
450	15	1	3	2	2025-09-29	9	1	
451	16	1	3	2	2025-08-31	9	1	
452	16	1	3	2	2025-09-01	9	1	
453	16	1	3	2	2025-09-02	9	1	weekoffs
454	16	1	3	2	2025-09-03	9	1	weekoffs
455	16	1	3	2	2025-09-04	9	1	
456	16	1	3	2	2025-09-05	9	1	
457	16	1	3	2	2025-09-06	9	1	
458	16	1	3	2	2025-09-07	9	1	
459	16	1	3	2	2025-09-08	9	1	
460	16	1	3	2	2025-09-09	9	1	weekoffs
461	16	1	3	2	2025-09-10	9	1	weekoffs
462	16	1	3	2	2025-09-11	9	1	
463	16	1	3	2	2025-09-12	9	1	
464	16	1	3	2	2025-09-13	9	1	
465	16	1	3	2	2025-09-14	9	1	
466	16	1	3	2	2025-09-15	9	1	
467	16	1	3	2	2025-09-16	9	1	weekoffs
468	16	1	3	2	2025-09-17	9	1	weekoffs
469	16	1	3	2	2025-09-18	9	1	
470	16	1	3	2	2025-09-19	9	1	
471	16	1	3	2	2025-09-20	9	1	
472	16	1	3	2	2025-09-21	9	1	
473	16	1	3	2	2025-09-22	9	1	
474	16	1	3	2	2025-09-23	9	1	weekoffs
475	16	1	3	2	2025-09-24	9	1	weekoffs
476	16	1	3	2	2025-09-25	9	1	
477	16	1	3	2	2025-09-26	9	1	
478	16	1	3	2	2025-09-27	9	1	
479	16	1	3	2	2025-09-28	9	1	
480	16	1	3	2	2025-09-29	9	1	
481	17	1	3	3	2025-08-31	9	1	
482	17	1	3	3	2025-09-01	9	1	
483	17	1	3	3	2025-09-02	9	1	weekoffs
484	17	1	3	3	2025-09-03	9	1	weekoffs
485	17	1	3	3	2025-09-04	9	1	
486	17	1	3	3	2025-09-05	9	1	
487	17	1	3	3	2025-09-06	9	1	
488	17	1	3	3	2025-09-07	9	1	
489	17	1	3	3	2025-09-08	9	1	
490	17	1	3	3	2025-09-09	9	1	weekoffs
491	17	1	3	3	2025-09-10	9	1	weekoffs
492	17	1	3	3	2025-09-11	9	1	
493	17	1	3	3	2025-09-12	9	1	
494	17	1	3	3	2025-09-13	9	1	
495	17	1	3	3	2025-09-14	9	1	
496	17	1	3	3	2025-09-15	9	1	
497	17	1	3	3	2025-09-16	9	1	weekoffs
498	17	1	3	3	2025-09-17	9	1	weekoffs
499	17	1	3	3	2025-09-18	9	1	
500	17	1	3	3	2025-09-19	9	1	
501	17	1	3	3	2025-09-20	9	1	
502	17	1	3	3	2025-09-21	9	1	
503	17	1	3	3	2025-09-22	9	1	
504	17	1	3	3	2025-09-23	9	1	weekoffs
505	17	1	3	3	2025-09-24	9	1	weekoffs
506	17	1	3	3	2025-09-25	9	1	
507	17	1	3	3	2025-09-26	9	1	
508	17	1	3	3	2025-09-27	9	1	
509	17	1	3	3	2025-09-28	9	1	
510	17	1	3	3	2025-09-29	9	1	
511	18	1	3	3	2025-08-31	9	1	
512	18	1	3	3	2025-09-01	9	1	
513	18	1	3	3	2025-09-02	9	1	weekoffs
514	18	1	3	3	2025-09-03	9	1	weekoffs
515	18	1	3	3	2025-09-04	9	1	
516	18	1	3	3	2025-09-05	9	1	
517	18	1	3	3	2025-09-06	9	1	
518	18	1	3	3	2025-09-07	9	1	
519	18	1	3	3	2025-09-08	9	1	
520	18	1	3	3	2025-09-09	9	1	weekoffs
521	18	1	3	3	2025-09-10	9	1	weekoffs
522	18	1	3	3	2025-09-11	9	1	
523	18	1	3	3	2025-09-12	9	1	
524	18	1	3	3	2025-09-13	9	1	
525	18	1	3	3	2025-09-14	9	1	
526	18	1	3	3	2025-09-15	9	1	
527	18	1	3	3	2025-09-16	9	1	weekoffs
528	18	1	3	3	2025-09-17	9	1	weekoffs
529	18	1	3	3	2025-09-18	9	1	
530	18	1	3	3	2025-09-19	9	1	
531	18	1	3	3	2025-09-20	9	1	
532	18	1	3	3	2025-09-21	9	1	
533	18	1	3	3	2025-09-22	9	1	
534	18	1	3	3	2025-09-23	9	1	weekoffs
535	18	1	3	3	2025-09-24	9	1	weekoffs
536	18	1	3	3	2025-09-25	9	1	
537	18	1	3	3	2025-09-26	9	1	
538	18	1	3	3	2025-09-27	9	1	
539	18	1	3	3	2025-09-28	9	1	
540	18	1	3	3	2025-09-29	9	1	
601	1	1	1	1	2025-10-01	9	1	
602	1	1	1	1	2025-10-02	9	1	
603	1	1	1	1	2025-10-03	9	1	
604	1	1	1	1	2025-10-04	9	1	
605	1	1	1	1	2025-10-05	9	1	weekoffs
606	1	1	1	1	2025-10-06	9	1	weekoffs
607	1	1	1	1	2025-10-07	9	1	
608	1	1	1	1	2025-10-08	9	1	
609	1	1	1	1	2025-10-09	9	1	
610	1	1	1	1	2025-10-10	9	1	
611	1	1	1	1	2025-10-11	9	1	
612	1	1	1	1	2025-10-12	9	1	weekoffs
613	1	1	1	1	2025-10-13	9	1	weekoffs
614	1	1	1	1	2025-10-14	9	1	
615	1	1	1	1	2025-10-15	9	1	
616	1	1	1	1	2025-10-16	9	1	
617	1	1	1	1	2025-10-17	9	1	
618	1	1	1	1	2025-10-18	9	1	
619	1	1	1	1	2025-10-19	9	1	weekoffs
620	1	1	1	1	2025-10-20	9	1	weekoffs
621	1	1	1	1	2025-10-21	9	1	
622	1	1	1	1	2025-10-22	9	1	
623	1	1	1	1	2025-10-23	9	1	
624	1	1	1	1	2025-10-24	9	1	
625	1	1	1	1	2025-10-25	9	1	
626	1	1	1	1	2025-10-26	9	1	weekoffs
627	1	1	1	1	2025-10-27	9	1	weekoffs
628	1	1	1	1	2025-10-28	9	1	
629	1	1	1	1	2025-10-29	9	1	
630	2	1	1	1	2025-10-30	9	1	
631	2	1	1	1	2025-10-01	9	1	
632	2	1	1	1	2025-10-02	9	1	
633	2	1	1	1	2025-10-03	9	1	
634	2	1	1	1	2025-10-04	9	1	
635	2	1	1	1	2025-10-05	9	1	weekoffs
636	2	1	1	1	2025-10-06	9	1	weekoffs
637	2	1	1	1	2025-10-07	9	1	
638	2	1	1	1	2025-10-08	9	1	
639	2	1	1	1	2025-10-09	9	1	
640	2	1	1	1	2025-10-10	9	1	
641	2	1	1	1	2025-10-11	9	1	
642	2	1	1	1	2025-10-12	9	1	weekoffs
643	2	1	1	1	2025-10-13	9	1	weekoffs
644	2	1	1	1	2025-10-14	9	1	
645	2	1	1	1	2025-10-15	9	1	
646	2	1	1	1	2025-10-16	9	1	
647	2	1	1	1	2025-10-17	9	1	
648	2	1	1	1	2025-10-18	9	1	
649	2	1	1	1	2025-10-19	9	1	weekoffs
650	2	1	1	1	2025-10-20	9	1	weekoffs
651	2	1	1	1	2025-10-21	9	1	
652	2	1	1	1	2025-10-22	9	1	
653	2	1	1	1	2025-10-23	9	1	
654	2	1	1	1	2025-10-24	9	1	
655	2	1	1	1	2025-10-25	9	1	
656	2	1	1	1	2025-10-26	9	1	weekoffs
657	2	1	1	1	2025-10-27	9	1	weekoffs
658	2	1	1	1	2025-10-28	9	1	
659	2	1	1	1	2025-10-29	9	1	
660	3	1	1	2	2025-10-30	9	1	
661	3	1	1	2	2025-10-01	9	1	
662	3	1	1	2	2025-10-02	9	1	
663	3	1	1	2	2025-10-03	9	1	
664	3	1	1	2	2025-10-04	9	1	
665	3	1	1	2	2025-10-05	9	1	weekoffs
666	3	1	1	2	2025-10-06	9	1	weekoffs
667	3	1	1	2	2025-10-07	9	1	
668	3	1	1	2	2025-10-08	9	1	
669	3	1	1	2	2025-10-09	9	1	
670	3	1	1	2	2025-10-10	9	1	
671	3	1	1	2	2025-10-11	9	1	
672	3	1	1	2	2025-10-12	9	1	weekoffs
673	3	1	1	2	2025-10-13	9	1	weekoffs
674	3	1	1	2	2025-10-14	9	1	
675	3	1	1	2	2025-10-15	9	1	
676	3	1	1	2	2025-10-16	9	1	
677	3	1	1	2	2025-10-17	9	1	
678	3	1	1	2	2025-10-18	9	1	
679	3	1	1	2	2025-10-19	9	1	weekoffs
680	3	1	1	2	2025-10-20	9	1	weekoffs
681	3	1	1	2	2025-10-21	9	1	
682	3	1	1	2	2025-10-22	9	1	
683	3	1	1	2	2025-10-23	9	1	
684	3	1	1	2	2025-10-24	9	1	
685	3	1	1	2	2025-10-25	9	1	
686	3	1	1	2	2025-10-26	9	1	weekoffs
687	3	1	1	2	2025-10-27	9	1	weekoffs
688	3	1	1	2	2025-10-28	9	1	
689	3	1	1	2	2025-10-29	9	1	
690	4	1	1	2	2025-10-30	9	1	
691	4	1	1	2	2025-10-01	9	1	
692	4	1	1	2	2025-10-02	9	1	
693	4	1	1	2	2025-10-03	9	1	
694	4	1	1	2	2025-10-04	9	1	
695	4	1	1	2	2025-10-05	9	1	weekoffs
696	4	1	1	2	2025-10-06	9	1	weekoffs
697	4	1	1	2	2025-10-07	9	1	
698	4	1	1	2	2025-10-08	9	1	
699	4	1	1	2	2025-10-09	9	1	
700	4	1	1	2	2025-10-10	9	1	
701	4	1	1	2	2025-10-11	9	1	
702	4	1	1	2	2025-10-12	9	1	weekoffs
703	4	1	1	2	2025-10-13	9	1	weekoffs
704	4	1	1	2	2025-10-14	9	1	
705	4	1	1	2	2025-10-15	9	1	
706	4	1	1	2	2025-10-16	9	1	
707	4	1	1	2	2025-10-17	9	1	
708	4	1	1	2	2025-10-18	9	1	
709	4	1	1	2	2025-10-19	9	1	weekoffs
710	4	1	1	2	2025-10-20	9	1	weekoffs
711	4	1	1	2	2025-10-21	9	1	
712	4	1	1	2	2025-10-22	9	1	
713	4	1	1	2	2025-10-23	9	1	
714	4	1	1	2	2025-10-24	9	1	
715	4	1	1	2	2025-10-25	9	1	
716	4	1	1	2	2025-10-26	9	1	weekoffs
717	4	1	1	2	2025-10-27	9	1	weekoffs
718	4	1	1	2	2025-10-28	9	1	
719	4	1	1	2	2025-10-29	9	1	
720	5	1	1	3	2025-10-30	9	1	
721	5	1	1	3	2025-10-01	9	1	
722	5	1	1	3	2025-10-02	9	1	
723	5	1	1	3	2025-10-03	9	1	
724	5	1	1	3	2025-10-04	9	1	
725	5	1	1	3	2025-10-05	9	1	weekoffs
726	5	1	1	3	2025-10-06	9	1	weekoffs
727	5	1	1	3	2025-10-07	9	1	
728	5	1	1	3	2025-10-08	9	1	
729	5	1	1	3	2025-10-09	9	1	
730	5	1	1	3	2025-10-10	9	1	
731	5	1	1	3	2025-10-11	9	1	
732	5	1	1	3	2025-10-12	9	1	weekoffs
733	5	1	1	3	2025-10-13	9	1	weekoffs
734	5	1	1	3	2025-10-14	9	1	
735	5	1	1	3	2025-10-15	9	1	
736	5	1	1	3	2025-10-16	9	1	
737	5	1	1	3	2025-10-17	9	1	
738	5	1	1	3	2025-10-18	9	1	
739	5	1	1	3	2025-10-19	9	1	weekoffs
740	5	1	1	3	2025-10-20	9	1	weekoffs
741	5	1	1	3	2025-10-21	9	1	
742	5	1	1	3	2025-10-22	9	1	
743	5	1	1	3	2025-10-23	9	1	
744	5	1	1	3	2025-10-24	9	1	
745	5	1	1	3	2025-10-25	9	1	
746	5	1	1	3	2025-10-26	9	1	weekoffs
747	5	1	1	3	2025-10-27	9	1	weekoffs
748	5	1	1	3	2025-10-28	9	1	
749	5	1	1	3	2025-10-29	9	1	
750	6	1	1	3	2025-10-30	9	1	
751	6	1	1	3	2025-10-01	9	1	
752	6	1	1	3	2025-10-02	9	1	
753	6	1	1	3	2025-10-03	9	1	
754	6	1	1	3	2025-10-04	9	1	
755	6	1	1	3	2025-10-05	9	1	weekoffs
756	6	1	1	3	2025-10-06	9	1	weekoffs
757	6	1	1	3	2025-10-07	9	1	
758	6	1	1	3	2025-10-08	9	1	
759	6	1	1	3	2025-10-09	9	1	
760	6	1	1	3	2025-10-10	9	1	
761	6	1	1	3	2025-10-11	9	1	
762	6	1	1	3	2025-10-12	9	1	weekoffs
763	6	1	1	3	2025-10-13	9	1	weekoffs
764	6	1	1	3	2025-10-14	9	1	
765	6	1	1	3	2025-10-15	9	1	
766	6	1	1	3	2025-10-16	9	1	
767	6	1	1	3	2025-10-17	9	1	
768	6	1	1	3	2025-10-18	9	1	
769	6	1	1	3	2025-10-19	9	1	weekoffs
770	6	1	1	3	2025-10-20	9	1	weekoffs
771	6	1	1	3	2025-10-21	9	1	
772	6	1	1	3	2025-10-22	9	1	
773	6	1	1	3	2025-10-23	9	1	
774	6	1	1	3	2025-10-24	9	1	
775	6	1	1	3	2025-10-25	9	1	
776	6	1	1	3	2025-10-26	9	1	weekoffs
777	6	1	1	3	2025-10-27	9	1	weekoffs
778	6	1	1	3	2025-10-28	9	1	
779	6	1	1	3	2025-10-29	9	1	
780	7	1	2	1	2025-10-30	9	1	weekoffs
781	7	1	2	1	2025-10-01	9	1	weekoffs
782	7	1	2	1	2025-10-02	9	1	
783	7	1	2	1	2025-10-03	9	1	
784	7	1	2	1	2025-10-04	9	1	
785	7	1	2	1	2025-10-05	9	1	
786	7	1	2	1	2025-10-06	9	1	
787	7	1	2	1	2025-10-07	9	1	weekoffs
788	7	1	2	1	2025-10-08	9	1	weekoffs
789	7	1	2	1	2025-10-09	9	1	
790	7	1	2	1	2025-10-10	9	1	
791	7	1	2	1	2025-10-11	9	1	
792	7	1	2	1	2025-10-12	9	1	
793	7	1	2	1	2025-10-13	9	1	
794	7	1	2	1	2025-10-14	9	1	weekoffs
795	7	1	2	1	2025-10-15	9	1	weekoffs
796	7	1	2	1	2025-10-16	9	1	
797	7	1	2	1	2025-10-17	9	1	
798	7	1	2	1	2025-10-18	9	1	
799	7	1	2	1	2025-10-19	9	1	
800	7	1	2	1	2025-10-20	9	1	
801	7	1	2	1	2025-10-21	9	1	weekoffs
802	7	1	2	1	2025-10-22	9	1	weekoffs
803	7	1	2	1	2025-10-23	9	1	
804	7	1	2	1	2025-10-24	9	1	
805	7	1	2	1	2025-10-25	9	1	
806	7	1	2	1	2025-10-26	9	1	
807	7	1	2	1	2025-10-27	9	1	
808	7	1	2	1	2025-10-28	9	1	weekoffs
809	7	1	2	1	2025-10-29	9	1	weekoffs
810	8	1	2	1	2025-10-30	9	1	weekoffs
811	8	1	2	1	2025-10-01	9	1	weekoffs
812	8	1	2	1	2025-10-02	9	1	
813	8	1	2	1	2025-10-03	9	1	
814	8	1	2	1	2025-10-04	9	1	
815	8	1	2	1	2025-10-05	9	1	
816	8	1	2	1	2025-10-06	9	1	
817	8	1	2	1	2025-10-07	9	1	weekoffs
818	8	1	2	1	2025-10-08	9	1	weekoffs
819	8	1	2	1	2025-10-09	9	1	
820	8	1	2	1	2025-10-10	9	1	
821	8	1	2	1	2025-10-11	9	1	
822	8	1	2	1	2025-10-12	9	1	
823	8	1	2	1	2025-10-13	9	1	
824	8	1	2	1	2025-10-14	9	1	weekoffs
825	8	1	2	1	2025-10-15	9	1	weekoffs
826	8	1	2	1	2025-10-16	9	1	
827	8	1	2	1	2025-10-17	9	1	
828	8	1	2	1	2025-10-18	9	1	
829	8	1	2	1	2025-10-19	9	1	
830	8	1	2	1	2025-10-20	9	1	
831	8	1	2	1	2025-10-21	9	1	weekoffs
832	8	1	2	1	2025-10-22	9	1	weekoffs
833	8	1	2	1	2025-10-23	9	1	
834	8	1	2	1	2025-10-24	9	1	
835	8	1	2	1	2025-10-25	9	1	
836	8	1	2	1	2025-10-26	9	1	
837	8	1	2	1	2025-10-27	9	1	
838	8	1	2	1	2025-10-28	9	1	weekoffs
839	8	1	2	1	2025-10-29	9	1	weekoffs
840	9	1	2	2	2025-10-30	9	1	weekoffs
841	9	1	2	2	2025-10-01	9	1	weekoffs
842	9	1	2	2	2025-10-02	9	1	
843	9	1	2	2	2025-10-03	9	1	
844	9	1	2	2	2025-10-04	9	1	
845	9	1	2	2	2025-10-05	9	1	
846	9	1	2	2	2025-10-06	9	1	
847	9	1	2	2	2025-10-07	9	1	weekoffs
848	9	1	2	2	2025-10-08	9	1	weekoffs
849	9	1	2	2	2025-10-09	9	1	
850	9	1	2	2	2025-10-10	9	1	
851	9	1	2	2	2025-10-11	9	1	
852	9	1	2	2	2025-10-12	9	1	
853	9	1	2	2	2025-10-13	9	1	
854	9	1	2	2	2025-10-14	9	1	weekoffs
855	9	1	2	2	2025-10-15	9	1	weekoffs
856	9	1	2	2	2025-10-16	9	1	
857	9	1	2	2	2025-10-17	9	1	
858	9	1	2	2	2025-10-18	9	1	
859	9	1	2	2	2025-10-19	9	1	
860	9	1	2	2	2025-10-20	9	1	
861	9	1	2	2	2025-10-21	9	1	weekoffs
862	9	1	2	2	2025-10-22	9	1	weekoffs
863	9	1	2	2	2025-10-23	9	1	
864	9	1	2	2	2025-10-24	9	1	
865	9	1	2	2	2025-10-25	9	1	
866	9	1	2	2	2025-10-26	9	1	
867	9	1	2	2	2025-10-27	9	1	
868	9	1	2	2	2025-10-28	9	1	weekoffs
869	9	1	2	2	2025-10-29	9	1	weekoffs
870	10	1	2	2	2025-10-30	9	1	weekoffs
871	10	1	2	2	2025-10-01	9	1	weekoffs
872	10	1	2	2	2025-10-02	9	1	
873	10	1	2	2	2025-10-03	9	1	
874	10	1	2	2	2025-10-04	9	1	
875	10	1	2	2	2025-10-05	9	1	
876	10	1	2	2	2025-10-06	9	1	
877	10	1	2	2	2025-10-07	9	1	weekoffs
878	10	1	2	2	2025-10-08	9	1	weekoffs
879	10	1	2	2	2025-10-09	9	1	
880	10	1	2	2	2025-10-10	9	1	
881	10	1	2	2	2025-10-11	9	1	
882	10	1	2	2	2025-10-12	9	1	
883	10	1	2	2	2025-10-13	9	1	
884	10	1	2	2	2025-10-14	9	1	weekoffs
885	10	1	2	2	2025-10-15	9	1	weekoffs
886	10	1	2	2	2025-10-16	9	1	
887	10	1	2	2	2025-10-17	9	1	
888	10	1	2	2	2025-10-18	9	1	
889	10	1	2	2	2025-10-19	9	1	
890	10	1	2	2	2025-10-20	9	1	
891	10	1	2	2	2025-10-21	9	1	weekoffs
892	10	1	2	2	2025-10-22	9	1	weekoffs
893	10	1	2	2	2025-10-23	9	1	
894	10	1	2	2	2025-10-24	9	1	
895	10	1	2	2	2025-10-25	9	1	
896	10	1	2	2	2025-10-26	9	1	
897	10	1	2	2	2025-10-27	9	1	
898	10	1	2	2	2025-10-28	9	1	weekoffs
899	10	1	2	2	2025-10-29	9	1	weekoffs
900	11	1	2	3	2025-10-30	9	1	weekoffs
901	11	1	2	3	2025-10-01	9	1	weekoffs
902	11	1	2	3	2025-10-02	9	1	
903	11	1	2	3	2025-10-03	9	1	
904	11	1	2	3	2025-10-04	9	1	
905	11	1	2	3	2025-10-05	9	1	
906	11	1	2	3	2025-10-06	9	1	
907	11	1	2	3	2025-10-07	9	1	weekoffs
908	11	1	2	3	2025-10-08	9	1	weekoffs
909	11	1	2	3	2025-10-09	9	1	
910	11	1	2	3	2025-10-10	9	1	
911	11	1	2	3	2025-10-11	9	1	
912	11	1	2	3	2025-10-12	9	1	
913	11	1	2	3	2025-10-13	9	1	
914	11	1	2	3	2025-10-14	9	1	weekoffs
915	11	1	2	3	2025-10-15	9	1	weekoffs
916	11	1	2	3	2025-10-16	9	1	
917	11	1	2	3	2025-10-17	9	1	
918	11	1	2	3	2025-10-18	9	1	
919	11	1	2	3	2025-10-19	9	1	
920	11	1	2	3	2025-10-20	9	1	
921	11	1	2	3	2025-10-21	9	1	weekoffs
922	11	1	2	3	2025-10-22	9	1	weekoffs
923	11	1	2	3	2025-10-23	9	1	
924	11	1	2	3	2025-10-24	9	1	
925	11	1	2	3	2025-10-25	9	1	
926	11	1	2	3	2025-10-26	9	1	
927	11	1	2	3	2025-10-27	9	1	
928	11	1	2	3	2025-10-28	9	1	weekoffs
929	11	1	2	3	2025-10-29	9	1	weekoffs
930	12	1	2	3	2025-10-30	9	1	weekoffs
931	12	1	2	3	2025-10-01	9	1	weekoffs
932	12	1	2	3	2025-10-02	9	1	
933	12	1	2	3	2025-10-03	9	1	
934	12	1	2	3	2025-10-04	9	1	
935	12	1	2	3	2025-10-05	9	1	
936	12	1	2	3	2025-10-06	9	1	
937	12	1	2	3	2025-10-07	9	1	weekoffs
938	12	1	2	3	2025-10-08	9	1	weekoffs
939	12	1	2	3	2025-10-09	9	1	
940	12	1	2	3	2025-10-10	9	1	
941	12	1	2	3	2025-10-11	9	1	
942	12	1	2	3	2025-10-12	9	1	
943	12	1	2	3	2025-10-13	9	1	
944	12	1	2	3	2025-10-14	9	1	weekoffs
945	12	1	2	3	2025-10-15	9	1	weekoffs
946	12	1	2	3	2025-10-16	9	1	
947	12	1	2	3	2025-10-17	9	1	
948	12	1	2	3	2025-10-18	9	1	
949	12	1	2	3	2025-10-19	9	1	
950	12	1	2	3	2025-10-20	9	1	
951	12	1	2	3	2025-10-21	9	1	weekoffs
952	12	1	2	3	2025-10-22	9	1	weekoffs
953	12	1	2	3	2025-10-23	9	1	
954	12	1	2	3	2025-10-24	9	1	
955	12	1	2	3	2025-10-25	9	1	
956	12	1	2	3	2025-10-26	9	1	
957	12	1	2	3	2025-10-27	9	1	
958	12	1	2	3	2025-10-28	9	1	weekoffs
959	12	1	2	3	2025-10-29	9	1	weekoffs
960	13	1	3	1	2025-10-30	9	1	
961	13	1	3	1	2025-10-01	9	1	
962	13	1	3	1	2025-10-02	9	1	weekoffs
963	13	1	3	1	2025-10-03	9	1	weekoffs
964	13	1	3	1	2025-10-04	9	1	
965	13	1	3	1	2025-10-05	9	1	
966	13	1	3	1	2025-10-06	9	1	
967	13	1	3	1	2025-10-07	9	1	
968	13	1	3	1	2025-10-08	9	1	
969	13	1	3	1	2025-10-09	9	1	weekoffs
970	13	1	3	1	2025-10-10	9	1	weekoffs
971	13	1	3	1	2025-10-11	9	1	
972	13	1	3	1	2025-10-12	9	1	
973	13	1	3	1	2025-10-13	9	1	
974	13	1	3	1	2025-10-14	9	1	
975	13	1	3	1	2025-10-15	9	1	
976	13	1	3	1	2025-10-16	9	1	weekoffs
977	13	1	3	1	2025-10-17	9	1	weekoffs
978	13	1	3	1	2025-10-18	9	1	
979	13	1	3	1	2025-10-19	9	1	
980	13	1	3	1	2025-10-20	9	1	
981	13	1	3	1	2025-10-21	9	1	
982	13	1	3	1	2025-10-22	9	1	
983	13	1	3	1	2025-10-23	9	1	weekoffs
984	13	1	3	1	2025-10-24	9	1	weekoffs
985	13	1	3	1	2025-10-25	9	1	
986	13	1	3	1	2025-10-26	9	1	
987	13	1	3	1	2025-10-27	9	1	
988	13	1	3	1	2025-10-28	9	1	
989	13	1	3	1	2025-10-29	9	1	
990	14	1	3	1	2025-10-30	9	1	
991	14	1	3	1	2025-10-01	9	1	
992	14	1	3	1	2025-10-02	9	1	weekoffs
993	14	1	3	1	2025-10-03	9	1	weekoffs
994	14	1	3	1	2025-10-04	9	1	
995	14	1	3	1	2025-10-05	9	1	
996	14	1	3	1	2025-10-06	9	1	
997	14	1	3	1	2025-10-07	9	1	
998	14	1	3	1	2025-10-08	9	1	
999	14	1	3	1	2025-10-09	9	1	weekoffs
1000	14	1	3	1	2025-10-10	9	1	weekoffs
1001	14	1	3	1	2025-10-11	9	1	
1002	14	1	3	1	2025-10-12	9	1	
1003	14	1	3	1	2025-10-13	9	1	
1004	14	1	3	1	2025-10-14	9	1	
1005	14	1	3	1	2025-10-15	9	1	
1006	14	1	3	1	2025-10-16	9	1	weekoffs
1007	14	1	3	1	2025-10-17	9	1	weekoffs
1008	14	1	3	1	2025-10-18	9	1	
1009	14	1	3	1	2025-10-19	9	1	
1010	14	1	3	1	2025-10-20	9	1	
1011	14	1	3	1	2025-10-21	9	1	
1012	14	1	3	1	2025-10-22	9	1	
1013	14	1	3	1	2025-10-23	9	1	weekoffs
1014	14	1	3	1	2025-10-24	9	1	weekoffs
1015	14	1	3	1	2025-10-25	9	1	
1016	14	1	3	1	2025-10-26	9	1	
1017	14	1	3	1	2025-10-27	9	1	
1018	14	1	3	1	2025-10-28	9	1	
1019	14	1	3	1	2025-10-29	9	1	
1020	15	1	3	2	2025-10-30	9	1	
1021	15	1	3	2	2025-10-01	9	1	
1022	15	1	3	2	2025-10-02	9	1	weekoffs
1023	15	1	3	2	2025-10-03	9	1	weekoffs
1024	15	1	3	2	2025-10-04	9	1	
1025	15	1	3	2	2025-10-05	9	1	
1026	15	1	3	2	2025-10-06	9	1	
1027	15	1	3	2	2025-10-07	9	1	
1028	15	1	3	2	2025-10-08	9	1	
1029	15	1	3	2	2025-10-09	9	1	weekoffs
1030	15	1	3	2	2025-10-10	9	1	weekoffs
1031	15	1	3	2	2025-10-11	9	1	
1032	15	1	3	2	2025-10-12	9	1	
1033	15	1	3	2	2025-10-13	9	1	
1034	15	1	3	2	2025-10-14	9	1	
1035	15	1	3	2	2025-10-15	9	1	
1036	15	1	3	2	2025-10-16	9	1	weekoffs
1037	15	1	3	2	2025-10-17	9	1	weekoffs
1038	15	1	3	2	2025-10-18	9	1	
1039	15	1	3	2	2025-10-19	9	1	
1040	15	1	3	2	2025-10-20	9	1	
1041	15	1	3	2	2025-10-21	9	1	
1042	15	1	3	2	2025-10-22	9	1	
1043	15	1	3	2	2025-10-23	9	1	weekoffs
1044	15	1	3	2	2025-10-24	9	1	weekoffs
1045	15	1	3	2	2025-10-25	9	1	
1046	15	1	3	2	2025-10-26	9	1	
1047	15	1	3	2	2025-10-27	9	1	
1048	15	1	3	2	2025-10-28	9	1	
1049	15	1	3	2	2025-10-29	9	1	
1050	16	1	3	2	2025-10-30	9	1	
1051	16	1	3	2	2025-10-01	9	1	
1052	16	1	3	2	2025-10-02	9	1	weekoffs
1053	16	1	3	2	2025-10-03	9	1	weekoffs
1054	16	1	3	2	2025-10-04	9	1	
1055	16	1	3	2	2025-10-05	9	1	
1056	16	1	3	2	2025-10-06	9	1	
1057	16	1	3	2	2025-10-07	9	1	
1058	16	1	3	2	2025-10-08	9	1	
1059	16	1	3	2	2025-10-09	9	1	weekoffs
1060	16	1	3	2	2025-10-10	9	1	weekoffs
1061	16	1	3	2	2025-10-11	9	1	
1062	16	1	3	2	2025-10-12	9	1	
1063	16	1	3	2	2025-10-13	9	1	
1064	16	1	3	2	2025-10-14	9	1	
1065	16	1	3	2	2025-10-15	9	1	
1066	16	1	3	2	2025-10-16	9	1	weekoffs
1067	16	1	3	2	2025-10-17	9	1	weekoffs
1068	16	1	3	2	2025-10-18	9	1	
1069	16	1	3	2	2025-10-19	9	1	
1070	16	1	3	2	2025-10-20	9	1	
1071	16	1	3	2	2025-10-21	9	1	
1072	16	1	3	2	2025-10-22	9	1	
1073	16	1	3	2	2025-10-23	9	1	weekoffs
1074	16	1	3	2	2025-10-24	9	1	weekoffs
1075	16	1	3	2	2025-10-25	9	1	
1076	16	1	3	2	2025-10-26	9	1	
1077	16	1	3	2	2025-10-27	9	1	
1078	16	1	3	2	2025-10-28	9	1	
1079	16	1	3	2	2025-10-29	9	1	
1080	17	1	3	3	2025-10-30	9	1	
1081	17	1	3	3	2025-10-01	9	1	
1082	17	1	3	3	2025-10-02	9	1	weekoffs
1083	17	1	3	3	2025-10-03	9	1	weekoffs
1084	17	1	3	3	2025-10-04	9	1	
1085	17	1	3	3	2025-10-05	9	1	
1086	17	1	3	3	2025-10-06	9	1	
1087	17	1	3	3	2025-10-07	9	1	
1088	17	1	3	3	2025-10-08	9	1	
1089	17	1	3	3	2025-10-09	9	1	weekoffs
1090	17	1	3	3	2025-10-10	9	1	weekoffs
1091	17	1	3	3	2025-10-11	9	1	
1092	17	1	3	3	2025-10-12	9	1	
1093	17	1	3	3	2025-10-13	9	1	
1094	17	1	3	3	2025-10-14	9	1	
1095	17	1	3	3	2025-10-15	9	1	
1096	17	1	3	3	2025-10-16	9	1	weekoffs
1097	17	1	3	3	2025-10-17	9	1	weekoffs
1098	17	1	3	3	2025-10-18	9	1	
1099	17	1	3	3	2025-10-19	9	1	
1100	17	1	3	3	2025-10-20	9	1	
1101	17	1	3	3	2025-10-21	9	1	
1102	17	1	3	3	2025-10-22	9	1	
1103	17	1	3	3	2025-10-23	9	1	weekoffs
1104	17	1	3	3	2025-10-24	9	1	weekoffs
1105	17	1	3	3	2025-10-25	9	1	
1106	17	1	3	3	2025-10-26	9	1	
1107	17	1	3	3	2025-10-27	9	1	
1108	17	1	3	3	2025-10-28	9	1	
1109	17	1	3	3	2025-10-29	9	1	
1110	18	1	3	3	2025-10-30	9	1	
1111	18	1	3	3	2025-10-01	9	1	
1112	18	1	3	3	2025-10-02	9	1	weekoffs
1113	18	1	3	3	2025-10-03	9	1	weekoffs
1114	18	1	3	3	2025-10-04	9	1	
1115	18	1	3	3	2025-10-05	9	1	
1116	18	1	3	3	2025-10-06	9	1	
1117	18	1	3	3	2025-10-07	9	1	
1118	18	1	3	3	2025-10-08	9	1	
1119	18	1	3	3	2025-10-09	9	1	weekoffs
1120	18	1	3	3	2025-10-10	9	1	weekoffs
1121	18	1	3	3	2025-10-11	9	1	
1122	18	1	3	3	2025-10-12	9	1	
1123	18	1	3	3	2025-10-13	9	1	
1124	18	1	3	3	2025-10-14	9	1	
1125	18	1	3	3	2025-10-15	9	1	
1126	18	1	3	3	2025-10-16	9	1	weekoffs
1127	18	1	3	3	2025-10-17	9	1	weekoffs
1128	18	1	3	3	2025-10-18	9	1	
1129	18	1	3	3	2025-10-19	9	1	
1130	18	1	3	3	2025-10-20	9	1	
1131	18	1	3	3	2025-10-21	9	1	
1132	18	1	3	3	2025-10-22	9	1	
1133	18	1	3	3	2025-10-23	9	1	weekoffs
1134	18	1	3	3	2025-10-24	9	1	weekoffs
1135	18	1	3	3	2025-10-25	9	1	
1136	18	1	3	3	2025-10-26	9	1	
1137	18	1	3	3	2025-10-27	9	1	
1138	18	1	3	3	2025-10-28	9	1	
1139	18	1	3	3	2025-10-29	9	1	
\.


--
-- Data for Name: preferences; Type: TABLE DATA; Schema: schedule; Owner: ak682a
--

COPY schedule.preferences (preference_id, employee_id, preferred_shifts, weekoffs, notes) FROM stdin;
\.


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: schedule; Owner: ak682a
--

COPY schedule.shifts (shift_id, shift_name, start_time, end_time, overlap_minutes) FROM stdin;
1	Morning	06:00:00	15:00:00	60
2	Afternoon	14:00:00	23:00:00	60
3	Night	22:00:00	07:00:00	60
\.


--
-- Data for Name: shifts_group; Type: TABLE DATA; Schema: schedule; Owner: ak682a
--

COPY schedule.shifts_group (group_id, groupname, project_id, week_off_1, week_off_2) FROM stdin;
1	Alpha	1	Friday	Saturday
2	Beta	1	Sunday	Monday
3	Delta	1	Tuesday	Wednesday
\.


--
-- Name: leave_requests_leave_id_seq; Type: SEQUENCE SET; Schema: approvals; Owner: ak682a
--

SELECT pg_catalog.setval('approvals.leave_requests_leave_id_seq', 1, false);


--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE SET; Schema: approvals; Owner: ak682a
--

SELECT pg_catalog.setval('approvals.leave_types_leave_type_id_seq', 1, false);


--
-- Name: swaps_swap_id_seq; Type: SEQUENCE SET; Schema: approvals; Owner: ak682a
--

SELECT pg_catalog.setval('approvals.swaps_swap_id_seq', 50, true);


--
-- Name: permissions_permission_id_seq; Type: SEQUENCE SET; Schema: iam; Owner: ak682a
--

SELECT pg_catalog.setval('iam.permissions_permission_id_seq', 42, true);


--
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: iam; Owner: ak682a
--

SELECT pg_catalog.setval('iam.roles_role_id_seq', 6, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: iam; Owner: ak682a
--

SELECT pg_catalog.setval('iam.users_user_id_seq', 8, true);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: notify; Owner: ak682a
--

SELECT pg_catalog.setval('notify.notifications_notification_id_seq', 1, false);


--
-- Name: employee_skills_emp_skill_id_seq; Type: SEQUENCE SET; Schema: organization; Owner: ak682a
--

SELECT pg_catalog.setval('organization.employee_skills_emp_skill_id_seq', 1, false);


--
-- Name: employees_employee_id_seq; Type: SEQUENCE SET; Schema: organization; Owner: ak682a
--

SELECT pg_catalog.setval('organization.employees_employee_id_seq', 262, true);


--
-- Name: manager_projects_manager_project_id_seq; Type: SEQUENCE SET; Schema: organization; Owner: ak682a
--

SELECT pg_catalog.setval('organization.manager_projects_manager_project_id_seq', 1, false);


--
-- Name: projects_project_id_seq; Type: SEQUENCE SET; Schema: organization; Owner: ak682a
--

SELECT pg_catalog.setval('organization.projects_project_id_seq', 1, false);


--
-- Name: skills_skill_id_seq; Type: SEQUENCE SET; Schema: organization; Owner: ak682a
--

SELECT pg_catalog.setval('organization.skills_skill_id_seq', 1, false);


--
-- Name: assignments_assignment_id_seq; Type: SEQUENCE SET; Schema: schedule; Owner: ak682a
--

SELECT pg_catalog.setval('schedule.assignments_assignment_id_seq', 1139, true);


--
-- Name: preferences_preference_id_seq; Type: SEQUENCE SET; Schema: schedule; Owner: ak682a
--

SELECT pg_catalog.setval('schedule.preferences_preference_id_seq', 1, false);


--
-- Name: shifts_group_group_id_seq; Type: SEQUENCE SET; Schema: schedule; Owner: ak682a
--

SELECT pg_catalog.setval('schedule.shifts_group_group_id_seq', 1, false);


--
-- Name: shifts_shift_id_seq; Type: SEQUENCE SET; Schema: schedule; Owner: ak682a
--

SELECT pg_catalog.setval('schedule.shifts_shift_id_seq', 1, false);


--
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (leave_id);


--
-- Name: leave_types leave_types_leave_name_key; Type: CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_types
    ADD CONSTRAINT leave_types_leave_name_key UNIQUE (leave_name);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (leave_type_id);


--
-- Name: swap_type_lookup swap_type_lookup_pkey; Type: CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swap_type_lookup
    ADD CONSTRAINT swap_type_lookup_pkey PRIMARY KEY (swap_type_id);


--
-- Name: swaps swaps_pkey; Type: CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_pkey PRIMARY KEY (swap_id);


--
-- Name: permissions permissions_permission_name_key; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.permissions
    ADD CONSTRAINT permissions_permission_name_key UNIQUE (permission_name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (permission_id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: notify; Owner: ak682a
--

ALTER TABLE ONLY notify.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: employee_skills employee_skills_employee_id_skill_id_key; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employee_skills
    ADD CONSTRAINT employee_skills_employee_id_skill_id_key UNIQUE (employee_id, skill_id);


--
-- Name: employee_skills employee_skills_pkey; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employee_skills
    ADD CONSTRAINT employee_skills_pkey PRIMARY KEY (emp_skill_id);


--
-- Name: employees employees_email_key; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employees
    ADD CONSTRAINT employees_email_key UNIQUE (email);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: manager_projects manager_projects_manager_id_project_id_key; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.manager_projects
    ADD CONSTRAINT manager_projects_manager_id_project_id_key UNIQUE (manager_id, project_id);


--
-- Name: manager_projects manager_projects_pkey; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.manager_projects
    ADD CONSTRAINT manager_projects_pkey PRIMARY KEY (manager_project_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: projects projects_project_name_key; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.projects
    ADD CONSTRAINT projects_project_name_key UNIQUE (project_name);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (skill_id);


--
-- Name: skills skills_skill_name_key; Type: CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.skills
    ADD CONSTRAINT skills_skill_name_key UNIQUE (skill_name);


--
-- Name: assignments assignments_employee_id_assignment_date_key; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_employee_id_assignment_date_key UNIQUE (employee_id, assignment_date);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: preferences preferences_employee_id_key; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.preferences
    ADD CONSTRAINT preferences_employee_id_key UNIQUE (employee_id);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (preference_id);


--
-- Name: shifts_group shifts_group_pkey; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts_group
    ADD CONSTRAINT shifts_group_pkey PRIMARY KEY (group_id);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (shift_id);


--
-- Name: shifts shifts_shift_name_key; Type: CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts
    ADD CONSTRAINT shifts_shift_name_key UNIQUE (shift_name);


--
-- Name: idx_approvals_leave_requests_approver_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_approvals_leave_requests_approver_id ON approvals.leave_requests USING btree (approver_id);


--
-- Name: idx_approvals_leave_requests_date_range; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_approvals_leave_requests_date_range ON approvals.leave_requests USING btree (from_date, to_date);


--
-- Name: idx_approvals_leave_requests_employee_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_approvals_leave_requests_employee_id ON approvals.leave_requests USING btree (employee_id);


--
-- Name: idx_approvals_leave_requests_leave_type_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_approvals_leave_requests_leave_type_id ON approvals.leave_requests USING btree (leave_type_id);


--
-- Name: idx_approvals_leave_requests_status; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_approvals_leave_requests_status ON approvals.leave_requests USING btree (status);


--
-- Name: idx_approvals_leave_types_leave_name; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE UNIQUE INDEX idx_approvals_leave_types_leave_name ON approvals.leave_types USING btree (leave_name);


--
-- Name: idx_swaps_from_emp; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_from_emp ON approvals.swaps USING btree (from_emp);


--
-- Name: idx_swaps_from_shift_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_from_shift_id ON approvals.swaps USING btree (from_shift_id);


--
-- Name: idx_swaps_manager_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_manager_id ON approvals.swaps USING btree (manager_id);


--
-- Name: idx_swaps_project_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_project_id ON approvals.swaps USING btree (project_id);


--
-- Name: idx_swaps_to_emp; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_to_emp ON approvals.swaps USING btree (to_emp);


--
-- Name: idx_swaps_to_shift_id; Type: INDEX; Schema: approvals; Owner: ak682a
--

CREATE INDEX idx_swaps_to_shift_id ON approvals.swaps USING btree (to_shift_id);


--
-- Name: idx_iam_permissions_permission_name; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE UNIQUE INDEX idx_iam_permissions_permission_name ON iam.permissions USING btree (permission_name);


--
-- Name: idx_iam_role_permissions_permission_id; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE INDEX idx_iam_role_permissions_permission_id ON iam.role_permissions USING btree (permission_id);


--
-- Name: idx_iam_role_permissions_role_id; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE INDEX idx_iam_role_permissions_role_id ON iam.role_permissions USING btree (role_id);


--
-- Name: idx_iam_roles_role_name; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE UNIQUE INDEX idx_iam_roles_role_name ON iam.roles USING btree (role_name);


--
-- Name: idx_iam_users_employee_id; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE INDEX idx_iam_users_employee_id ON iam.users USING btree (employee_id);


--
-- Name: idx_iam_users_is_active; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE INDEX idx_iam_users_is_active ON iam.users USING btree (is_active);


--
-- Name: idx_iam_users_role_id; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE INDEX idx_iam_users_role_id ON iam.users USING btree (role_id);


--
-- Name: idx_iam_users_username; Type: INDEX; Schema: iam; Owner: ak682a
--

CREATE UNIQUE INDEX idx_iam_users_username ON iam.users USING btree (username);


--
-- Name: idx_notify_notifications_employee_id; Type: INDEX; Schema: notify; Owner: ak682a
--

CREATE INDEX idx_notify_notifications_employee_id ON notify.notifications USING btree (employee_id);


--
-- Name: idx_notify_notifications_employee_status_unread; Type: INDEX; Schema: notify; Owner: ak682a
--

CREATE INDEX idx_notify_notifications_employee_status_unread ON notify.notifications USING btree (employee_id, status) WHERE ((status)::text = 'Unread'::text);


--
-- Name: idx_notify_notifications_status; Type: INDEX; Schema: notify; Owner: ak682a
--

CREATE INDEX idx_notify_notifications_status ON notify.notifications USING btree (status);


--
-- Name: idx_notify_notifications_type; Type: INDEX; Schema: notify; Owner: ak682a
--

CREATE INDEX idx_notify_notifications_type ON notify.notifications USING btree (type);


--
-- Name: idx_organization_employee_skills_employee_id; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_employee_skills_employee_id ON organization.employee_skills USING btree (employee_id);


--
-- Name: idx_organization_employee_skills_skill_id; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_employee_skills_skill_id ON organization.employee_skills USING btree (skill_id);


--
-- Name: idx_organization_employee_skills_unique; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE UNIQUE INDEX idx_organization_employee_skills_unique ON organization.employee_skills USING btree (employee_id, skill_id);


--
-- Name: idx_organization_employees_email; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE UNIQUE INDEX idx_organization_employees_email ON organization.employees USING btree (email);


--
-- Name: idx_organization_employees_name; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_employees_name ON organization.employees USING btree (last_name, first_name);


--
-- Name: idx_organization_employees_role_id; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_employees_role_id ON organization.employees USING btree (role_id);


--
-- Name: idx_organization_employees_status; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_employees_status ON organization.employees USING btree (status);


--
-- Name: idx_organization_manager_projects_manager_id; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_manager_projects_manager_id ON organization.manager_projects USING btree (manager_id);


--
-- Name: idx_organization_manager_projects_project_id; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE INDEX idx_organization_manager_projects_project_id ON organization.manager_projects USING btree (project_id);


--
-- Name: idx_organization_manager_projects_unique; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE UNIQUE INDEX idx_organization_manager_projects_unique ON organization.manager_projects USING btree (manager_id, project_id);


--
-- Name: idx_organization_projects_project_name; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE UNIQUE INDEX idx_organization_projects_project_name ON organization.projects USING btree (project_name);


--
-- Name: idx_organization_skills_skill_name; Type: INDEX; Schema: organization; Owner: ak682a
--

CREATE UNIQUE INDEX idx_organization_skills_skill_name ON organization.skills USING btree (skill_name);


--
-- Name: idx_schedule_assignments_date; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_date ON schedule.assignments USING btree (assignment_date);


--
-- Name: idx_schedule_assignments_employee_date_range; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_employee_date_range ON schedule.assignments USING btree (employee_id, assignment_date);


--
-- Name: idx_schedule_assignments_employee_group_date_range; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_employee_group_date_range ON schedule.assignments USING btree (employee_id, group_id, assignment_date);


--
-- Name: idx_schedule_assignments_employee_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_employee_id ON schedule.assignments USING btree (employee_id);


--
-- Name: idx_schedule_assignments_group_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_group_id ON schedule.assignments USING btree (group_id);


--
-- Name: idx_schedule_assignments_project_date_range; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_project_date_range ON schedule.assignments USING btree (project_id, assignment_date);


--
-- Name: idx_schedule_assignments_project_group_date_range; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_project_group_date_range ON schedule.assignments USING btree (project_id, group_id, assignment_date);


--
-- Name: idx_schedule_assignments_project_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_project_id ON schedule.assignments USING btree (project_id);


--
-- Name: idx_schedule_assignments_shift_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_shift_id ON schedule.assignments USING btree (shift_id);


--
-- Name: idx_schedule_assignments_status; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_assignments_status ON schedule.assignments USING btree (status);


--
-- Name: idx_schedule_preferences_employee_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE UNIQUE INDEX idx_schedule_preferences_employee_id ON schedule.preferences USING btree (employee_id);


--
-- Name: idx_schedule_shift_group_group_project; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_shift_group_group_project ON schedule.shifts_group USING btree (group_id, project_id);


--
-- Name: idx_schedule_shifts_shift_name; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE UNIQUE INDEX idx_schedule_shifts_shift_name ON schedule.shifts USING btree (shift_name);


--
-- Name: idx_schedule_shifts_time_range; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_schedule_shifts_time_range ON schedule.shifts USING btree (start_time, end_time);


--
-- Name: idx_shifts_group_group_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_shifts_group_group_id ON schedule.shifts_group USING btree (group_id);


--
-- Name: idx_shifts_group_project_id; Type: INDEX; Schema: schedule; Owner: ak682a
--

CREATE INDEX idx_shifts_group_project_id ON schedule.shifts_group USING btree (project_id);


--
-- Name: leave_requests leave_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_requests
    ADD CONSTRAINT leave_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES organization.employees(employee_id) ON DELETE SET NULL;


--
-- Name: leave_requests leave_requests_employee_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_requests
    ADD CONSTRAINT leave_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: leave_requests leave_requests_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.leave_requests
    ADD CONSTRAINT leave_requests_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES approvals.leave_types(leave_type_id);


--
-- Name: swaps swaps_from_emp_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_from_emp_fkey FOREIGN KEY (from_emp) REFERENCES organization.employees(employee_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_from_shift_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_from_shift_id_fkey FOREIGN KEY (from_shift_id) REFERENCES schedule.shifts(shift_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_manager_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES organization.employees(employee_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_project_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_project_id_fkey FOREIGN KEY (project_id) REFERENCES organization.projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_swap_type_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_swap_type_fkey FOREIGN KEY (swap_type) REFERENCES approvals.swap_type_lookup(swap_type_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_to_emp_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_to_emp_fkey FOREIGN KEY (to_emp) REFERENCES organization.employees(employee_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: swaps swaps_to_shift_id_fkey; Type: FK CONSTRAINT; Schema: approvals; Owner: ak682a
--

ALTER TABLE ONLY approvals.swaps
    ADD CONSTRAINT swaps_to_shift_id_fkey FOREIGN KEY (to_shift_id) REFERENCES schedule.shifts(shift_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES iam.permissions(permission_id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES iam.roles(role_id) ON DELETE CASCADE;


--
-- Name: users users_employee_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.users
    ADD CONSTRAINT users_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: iam; Owner: ak682a
--

ALTER TABLE ONLY iam.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES iam.roles(role_id);


--
-- Name: notifications notifications_employee_id_fkey; Type: FK CONSTRAINT; Schema: notify; Owner: ak682a
--

ALTER TABLE ONLY notify.notifications
    ADD CONSTRAINT notifications_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: employee_skills employee_skills_employee_id_fkey; Type: FK CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employee_skills
    ADD CONSTRAINT employee_skills_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: employee_skills employee_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employee_skills
    ADD CONSTRAINT employee_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES organization.skills(skill_id) ON DELETE CASCADE;


--
-- Name: employees employees_role_id_fkey; Type: FK CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.employees
    ADD CONSTRAINT employees_role_id_fkey FOREIGN KEY (role_id) REFERENCES iam.roles(role_id);


--
-- Name: manager_projects manager_projects_manager_id_fkey; Type: FK CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.manager_projects
    ADD CONSTRAINT manager_projects_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: manager_projects manager_projects_project_id_fkey; Type: FK CONSTRAINT; Schema: organization; Owner: ak682a
--

ALTER TABLE ONLY organization.manager_projects
    ADD CONSTRAINT manager_projects_project_id_fkey FOREIGN KEY (project_id) REFERENCES organization.projects(project_id) ON DELETE CASCADE;


--
-- Name: assignments assignments_employee_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: assignments assignments_group_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_group_id_fkey FOREIGN KEY (group_id) REFERENCES schedule.shifts_group(group_id) ON DELETE CASCADE;


--
-- Name: assignments assignments_project_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_project_id_fkey FOREIGN KEY (project_id) REFERENCES organization.projects(project_id) ON DELETE CASCADE;


--
-- Name: assignments assignments_shift_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.assignments
    ADD CONSTRAINT assignments_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES schedule.shifts(shift_id) ON DELETE CASCADE;


--
-- Name: preferences preferences_employee_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.preferences
    ADD CONSTRAINT preferences_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES organization.employees(employee_id) ON DELETE CASCADE;


--
-- Name: shifts_group shifts_group_project_id_fkey; Type: FK CONSTRAINT; Schema: schedule; Owner: ak682a
--

ALTER TABLE ONLY schedule.shifts_group
    ADD CONSTRAINT shifts_group_project_id_fkey FOREIGN KEY (project_id) REFERENCES organization.projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict TMapmpA8c9rkZh4zKm6Jv6aCl1phviUVfcWnDR51G0rEsl0aiia33ARxc8K7ngv

