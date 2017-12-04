CREATE TABLE logintable (
    loginpermissions character(50)
);

CREATE TABLE schedules (
    id character varying(40) NOT NULL,
    description character varying(200),
    calendar character varying(30),
    effectivedate date,
    terminationdate date,
    frequency character varying(20),
    convention character varying(30),
    terminationdateconvention character varying(30),
    dategenerationrule character varying(20),
    endofmonth boolean
);

CREATE TABLE termstructuredefinition_points (
    termstructure character varying(40) NOT NULL,
    point character varying(40) NOT NULL
);

CREATE TABLE termstructuredefinitions (
    id character varying(40) NOT NULL,
    description character varying(200),
    daycounter character varying(20),
    interpolator character varying(40),
    bootstraptrait character varying(20)
);

CREATE TABLE termstructurejumps (
    termstructure character varying(40) NOT NULL,
    date date NOT NULL,
    rate numeric
);

CREATE TABLE termstructurepoints (
    id character varying(40) NOT NULL,
    type character varying(10),
    tenortimeunit character varying(12),
    tenornumber integer,
    fixingdays integer,
    monthstostart integer,
    monthstoend integer,
    futurestartdate date,
    futuremonths integer,
    swfixedlegfrequency character varying(20),
    swfixedlegconvention character varying(30),
    swfixedlegdaycounter character varying(20),
    swfloatinglegindex character varying(20),
    faceamount numeric,
    schedule character varying(40),
    couponrate numeric,
    redemption numeric,
    issuedate date,
    startdate date,
    enddate date,
    calendar character varying(30),
    businessdayconvention character varying(30),
    daycounter character varying(20),
    overnightindex character varying(20),
    description character varying(200)
);

CREATE TABLE termstructurerates (
    pointid character varying(40) NOT NULL,
    date date NOT NULL,
    rate numeric
);

ALTER TABLE ONLY schedules
    ADD CONSTRAINT schedule_pkey PRIMARY KEY (id);

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_pkey PRIMARY KEY (termstructure, point);


ALTER TABLE ONLY termstructurejumps
    ADD CONSTRAINT termstructuredefinitionjumps_pkey PRIMARY KEY (termstructure, date);

ALTER TABLE ONLY termstructurerates
    ADD CONSTRAINT termstructuredefinitionrates_pkey PRIMARY KEY (pointid, date);

ALTER TABLE ONLY termstructuredefinitions
    ADD CONSTRAINT termstructuredefinitions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY termstructurepoints
    ADD CONSTRAINT termstructurepoint_pkey PRIMARY KEY (id);

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_point_fkey FOREIGN KEY (point) REFERENCES termstructurepoints(id);

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_termstructure_fkey FOREIGN KEY (termstructure) REFERENCES termstructuredefinitions(id);

ALTER TABLE ONLY termstructurejumps
    ADD CONSTRAINT termstructuredefinitionjumps_termstructure_fkey FOREIGN KEY (termstructure) REFERENCES termstructuredefinitions(id);

ALTER TABLE ONLY termstructurerates
    ADD CONSTRAINT termstructuredefinitionrates_termstructurepoint_fkey FOREIGN KEY (pointid) REFERENCES termstructurepoints(id);

ALTER TABLE ONLY termstructurepoints
    ADD CONSTRAINT termstructurepoint_schedule_fkey FOREIGN KEY (schedule) REFERENCES schedules(id);
