--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA api;


ALTER SCHEMA api OWNER TO postgres;

--
-- Name: basic_auth; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA basic_auth;


ALTER SCHEMA basic_auth OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA public;


--
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


SET search_path = basic_auth, pg_catalog;

--
-- Name: jwt_token; Type: TYPE; Schema: basic_auth; Owner: postgres
--

CREATE TYPE jwt_token AS (
	token text
);


ALTER TYPE jwt_token OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: jwt_token; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE jwt_token AS (
	token text
);


ALTER TYPE jwt_token OWNER TO postgres;

SET search_path = api, pg_catalog;

--
-- Name: login(text, text); Type: FUNCTION; Schema: api; Owner: postgres
--

CREATE FUNCTION login(email text, pass text) RETURNS basic_auth.jwt_token
    LANGUAGE plpgsql
    AS $$
declare
  _role name;
  result basic_auth.jwt_token;
begin
  -- check email and password
  select basic_auth.user_role(email, pass) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;

  select sign(
      row_to_json(r), 'aSecurePassword'
    ) as token
    from (
      select _role as role, login.email as email,
         extract(epoch from now())::integer + 60*60 as exp
    ) r
    into result;
  return result;
end;
$$;


ALTER FUNCTION api.login(email text, pass text) OWNER TO postgres;

SET search_path = basic_auth, pg_catalog;

--
-- Name: check_role_exists(); Type: FUNCTION; Schema: basic_auth; Owner: postgres
--

CREATE FUNCTION check_role_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;


ALTER FUNCTION basic_auth.check_role_exists() OWNER TO postgres;

--
-- Name: encrypt_pass(); Type: FUNCTION; Schema: basic_auth; Owner: postgres
--

CREATE FUNCTION encrypt_pass() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$;


ALTER FUNCTION basic_auth.encrypt_pass() OWNER TO postgres;

--
-- Name: user_role(text, text); Type: FUNCTION; Schema: basic_auth; Owner: postgres
--

CREATE FUNCTION user_role(username text, pass text) RETURNS name
    LANGUAGE plpgsql
    AS $$
begin
  return (
  select role from basic_auth.users
   where users.username = user_role.username
     and users.pass = crypt(user_role.pass, users.pass)
  );
end;
$$;


ALTER FUNCTION basic_auth.user_role(username text, pass text) OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: login(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION login(username text, pass text) RETURNS basic_auth.jwt_token
    LANGUAGE plpgsql
    AS $$
declare
  _role name;
  result basic_auth.jwt_token;
begin
  -- check username and password
  select basic_auth.user_role(username, pass) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;

  select sign(
      row_to_json(r), 'reallyreallyreallyreallyverysafe'
    ) as token
    from (
      select _role as role, login.username as username,
         extract(epoch from now())::integer + 60*60 as exp
    ) r
    into result;
  return result;
end;
$$;


ALTER FUNCTION public.login(username text, pass text) OWNER TO postgres;

SET search_path = api, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logintable; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

CREATE TABLE logintable (
    loginpermissions character(50)
);


ALTER TABLE logintable OWNER TO postgres;

--
-- Name: schedules; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

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


ALTER TABLE schedules OWNER TO postgres;

--
-- Name: termstructuredefinition_points; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

CREATE TABLE termstructuredefinition_points (
    termstructure character varying(40) NOT NULL,
    point character varying(40) NOT NULL
);


ALTER TABLE termstructuredefinition_points OWNER TO postgres;

--
-- Name: termstructuredefinitions; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

CREATE TABLE termstructuredefinitions (
    id character varying(40) NOT NULL,
    description character varying(200),
    daycounter character varying(20),
    interpolator character varying(40),
    bootstraptrait character varying(20)
);


ALTER TABLE termstructuredefinitions OWNER TO postgres;

--
-- Name: termstructurejumps; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

CREATE TABLE termstructurejumps (
    termstructure character varying(40) NOT NULL,
    date date NOT NULL,
    rate numeric
);


ALTER TABLE termstructurejumps OWNER TO postgres;

--
-- Name: termstructurepoints; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

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


ALTER TABLE termstructurepoints OWNER TO postgres;

--
-- Name: termstructurerates; Type: TABLE; Schema: api; Owner: postgres; Tablespace: 
--

CREATE TABLE termstructurerates (
    pointid character varying(40) NOT NULL,
    date date NOT NULL,
    rate numeric
);


ALTER TABLE termstructurerates OWNER TO postgres;

SET search_path = basic_auth, pg_catalog;

--
-- Name: users; Type: TABLE; Schema: basic_auth; Owner: postgres; Tablespace: 
--

CREATE TABLE users (
    username text NOT NULL,
    pass text NOT NULL,
    role name NOT NULL,
    CONSTRAINT users_pass_check CHECK ((length(pass) < 512)),
    CONSTRAINT users_pass_check1 CHECK ((length(pass) < 512)),
    CONSTRAINT users_role_check CHECK ((length((role)::text) < 512))
);


ALTER TABLE users OWNER TO postgres;

SET search_path = api, pg_catalog;

--
-- Name: schedule_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY schedules
    ADD CONSTRAINT schedule_pkey PRIMARY KEY (id);


--
-- Name: termstructuredefinition_points_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_pkey PRIMARY KEY (termstructure, point);


--
-- Name: termstructuredefinitionjumps_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY termstructurejumps
    ADD CONSTRAINT termstructuredefinitionjumps_pkey PRIMARY KEY (termstructure, date);


--
-- Name: termstructuredefinitionrates_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY termstructurerates
    ADD CONSTRAINT termstructuredefinitionrates_pkey PRIMARY KEY (pointid, date);


--
-- Name: termstructuredefinitions_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY termstructuredefinitions
    ADD CONSTRAINT termstructuredefinitions_pkey PRIMARY KEY (id);


--
-- Name: termstructurepoint_pkey; Type: CONSTRAINT; Schema: api; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY termstructurepoints
    ADD CONSTRAINT termstructurepoint_pkey PRIMARY KEY (id);


SET search_path = basic_auth, pg_catalog;

--
-- Name: users_pkey; Type: CONSTRAINT; Schema: basic_auth; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: encrypt_pass; Type: TRIGGER; Schema: basic_auth; Owner: postgres
--

CREATE TRIGGER encrypt_pass BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE encrypt_pass();


SET search_path = api, pg_catalog;

--
-- Name: termstructuredefinition_points_point_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_point_fkey FOREIGN KEY (point) REFERENCES termstructurepoints(id);


--
-- Name: termstructuredefinition_points_termstructure_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY termstructuredefinition_points
    ADD CONSTRAINT termstructuredefinition_points_termstructure_fkey FOREIGN KEY (termstructure) REFERENCES termstructuredefinitions(id);


--
-- Name: termstructuredefinitionjumps_termstructure_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY termstructurejumps
    ADD CONSTRAINT termstructuredefinitionjumps_termstructure_fkey FOREIGN KEY (termstructure) REFERENCES termstructuredefinitions(id);


--
-- Name: termstructuredefinitionrates_termstructurepoint_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY termstructurerates
    ADD CONSTRAINT termstructuredefinitionrates_termstructurepoint_fkey FOREIGN KEY (pointid) REFERENCES termstructurepoints(id);


--
-- Name: termstructurepoint_schedule_fkey; Type: FK CONSTRAINT; Schema: api; Owner: postgres
--

ALTER TABLE ONLY termstructurepoints
    ADD CONSTRAINT termstructurepoint_schedule_fkey FOREIGN KEY (schedule) REFERENCES schedules(id);


--
-- Name: api; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA api FROM PUBLIC;
REVOKE ALL ON SCHEMA api FROM postgres;
GRANT ALL ON SCHEMA api TO postgres;
GRANT USAGE ON SCHEMA api TO anon;
GRANT USAGE ON SCHEMA api TO write_user;
GRANT USAGE ON SCHEMA api TO read_user;


--
-- Name: basic_auth; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA basic_auth FROM PUBLIC;
REVOKE ALL ON SCHEMA basic_auth FROM postgres;
GRANT ALL ON SCHEMA basic_auth TO postgres;
GRANT USAGE ON SCHEMA basic_auth TO anon;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO anon;


SET search_path = public, pg_catalog;

--
-- Name: login(text, text); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION login(username text, pass text) FROM PUBLIC;
REVOKE ALL ON FUNCTION login(username text, pass text) FROM postgres;
GRANT ALL ON FUNCTION login(username text, pass text) TO postgres;
GRANT ALL ON FUNCTION login(username text, pass text) TO PUBLIC;
GRANT ALL ON FUNCTION login(username text, pass text) TO anon;


SET search_path = api, pg_catalog;

--
-- Name: logintable; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE logintable FROM PUBLIC;
REVOKE ALL ON TABLE logintable FROM postgres;
GRANT ALL ON TABLE logintable TO postgres;
GRANT SELECT ON TABLE logintable TO read_user;
GRANT ALL ON TABLE logintable TO write_user;
GRANT SELECT ON TABLE logintable TO anon;


--
-- Name: schedules; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE schedules FROM PUBLIC;
REVOKE ALL ON TABLE schedules FROM postgres;
GRANT ALL ON TABLE schedules TO postgres;
GRANT SELECT ON TABLE schedules TO anon;
GRANT ALL ON TABLE schedules TO write_user;
GRANT SELECT ON TABLE schedules TO read_user;


--
-- Name: termstructuredefinition_points; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE termstructuredefinition_points FROM PUBLIC;
REVOKE ALL ON TABLE termstructuredefinition_points FROM postgres;
GRANT ALL ON TABLE termstructuredefinition_points TO postgres;
GRANT ALL ON TABLE termstructuredefinition_points TO write_user;
GRANT SELECT ON TABLE termstructuredefinition_points TO read_user;
GRANT SELECT ON TABLE termstructuredefinition_points TO anon;


--
-- Name: termstructuredefinitions; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE termstructuredefinitions FROM PUBLIC;
REVOKE ALL ON TABLE termstructuredefinitions FROM postgres;
GRANT ALL ON TABLE termstructuredefinitions TO postgres;
GRANT ALL ON TABLE termstructuredefinitions TO write_user;
GRANT SELECT ON TABLE termstructuredefinitions TO read_user;
GRANT SELECT ON TABLE termstructuredefinitions TO anon;


--
-- Name: termstructurejumps; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE termstructurejumps FROM PUBLIC;
REVOKE ALL ON TABLE termstructurejumps FROM postgres;
GRANT ALL ON TABLE termstructurejumps TO postgres;
GRANT ALL ON TABLE termstructurejumps TO write_user;
GRANT SELECT ON TABLE termstructurejumps TO read_user;
GRANT SELECT ON TABLE termstructurejumps TO anon;


--
-- Name: termstructurepoints; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE termstructurepoints FROM PUBLIC;
REVOKE ALL ON TABLE termstructurepoints FROM postgres;
GRANT ALL ON TABLE termstructurepoints TO postgres;
GRANT SELECT ON TABLE termstructurepoints TO anon;
GRANT ALL ON TABLE termstructurepoints TO write_user;
GRANT SELECT ON TABLE termstructurepoints TO read_user;


--
-- Name: termstructurerates; Type: ACL; Schema: api; Owner: postgres
--

REVOKE ALL ON TABLE termstructurerates FROM PUBLIC;
REVOKE ALL ON TABLE termstructurerates FROM postgres;
GRANT ALL ON TABLE termstructurerates TO postgres;
GRANT ALL ON TABLE termstructurerates TO write_user;
GRANT SELECT ON TABLE termstructurerates TO read_user;
GRANT SELECT ON TABLE termstructurerates TO anon;


SET search_path = basic_auth, pg_catalog;

--
-- Name: users; Type: ACL; Schema: basic_auth; Owner: postgres
--

REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM postgres;
GRANT ALL ON TABLE users TO postgres;
GRANT SELECT ON TABLE users TO anon;


--
-- PostgreSQL database dump complete
--

