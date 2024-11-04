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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: content_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_visibility AS ENUM (
    'draft',
    'internal',
    'published',
    'archived',
    'blocked'
);


--
-- Name: date_to_text(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.date_to_text(timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$ select to_char($1, 'YYYY-MM-DD'); $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id character varying NOT NULL,
    blob_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blob_id uuid NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    address character varying,
    lat numeric,
    long numeric,
    name character varying NOT NULL,
    url text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description character varying,
    country_code character varying NOT NULL,
    geocoded_address jsonb DEFAULT '{}'::jsonb NOT NULL,
    visibility public.content_visibility DEFAULT 'internal'::public.content_visibility NOT NULL,
    date date
);


--
-- Name: logins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_yid character varying NOT NULL,
    ip_address character varying NOT NULL,
    user_agent text NOT NULL,
    device_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    roles text[] DEFAULT '{}'::text[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    user_yid character varying NOT NULL,
    visibility public.content_visibility DEFAULT 'published'::public.content_visibility NOT NULL
);


--
-- Name: memories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memories (
    yid character varying NOT NULL,
    memo text NOT NULL,
    team_yid character varying NOT NULL,
    location_yid character varying,
    picture_yid character varying,
    weblink_yid character varying,
    visibility public.content_visibility DEFAULT 'draft'::public.content_visibility NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    thought_yid character varying
);


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pg_search_documents (
    id bigint NOT NULL,
    content text NOT NULL,
    searchable_type character varying NOT NULL,
    searchable_id character varying NOT NULL,
    team_yid character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pg_search_documents_id_seq OWNED BY public.pg_search_documents.id;


--
-- Name: pictures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pictures (
    name character varying,
    date date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    visibility public.content_visibility DEFAULT 'internal'::public.content_visibility NOT NULL
);


--
-- Name: record_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.record_histories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event character varying NOT NULL,
    record_type character varying NOT NULL,
    record_yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    user_yid character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    done_by_admin boolean DEFAULT false NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    name character varying NOT NULL,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    yid character varying NOT NULL
);


--
-- Name: thoughts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thoughts (
    yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    text text NOT NULL,
    date date,
    name character varying GENERATED ALWAYS AS ((("substring"(text, 0, 60) || '... '::text) || public.date_to_text((date)::timestamp without time zone))) STORED,
    visibility public.content_visibility DEFAULT 'internal'::public.content_visibility NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    name character varying NOT NULL,
    nickname character varying,
    email character varying NOT NULL,
    password_digest character varying NOT NULL,
    temp_auth_token text,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    yid character varying NOT NULL,
    role character varying DEFAULT 'user'::character varying NOT NULL
);


--
-- Name: weblinks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weblinks (
    yid character varying NOT NULL,
    team_yid character varying NOT NULL,
    url text NOT NULL,
    name character varying NOT NULL,
    description text,
    preview_snippet json DEFAULT '{}'::json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    visibility public.content_visibility DEFAULT 'internal'::public.content_visibility NOT NULL,
    date date
);


--
-- Name: pg_search_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents ALTER COLUMN id SET DEFAULT nextval('public.pg_search_documents_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (yid);


--
-- Name: logins logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logins
    ADD CONSTRAINT logins_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (yid);


--
-- Name: memories memories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT memories_pkey PRIMARY KEY (yid);


--
-- Name: pg_search_documents pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: pictures pictures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pictures
    ADD CONSTRAINT pictures_pkey PRIMARY KEY (yid);


--
-- Name: record_histories record_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_histories
    ADD CONSTRAINT record_histories_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (yid);


--
-- Name: thoughts thoughts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thoughts
    ADD CONSTRAINT thoughts_pkey PRIMARY KEY (yid);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (yid);


--
-- Name: weblinks weblinks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weblinks
    ADD CONSTRAINT weblinks_pkey PRIMARY KEY (yid);


--
-- Name: idx_on_done_by_admin_user_yid_record_type_f814bc5185; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_done_by_admin_user_yid_record_type_f814bc5185 ON public.record_histories USING btree (done_by_admin, user_yid, record_type);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_locations_on_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_country_code ON public.locations USING btree (country_code);


--
-- Name: index_locations_on_team_yid_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_locations_on_team_yid_and_name ON public.locations USING btree (team_yid, name);


--
-- Name: index_logins_on_user_yid_and_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_logins_on_user_yid_and_device_id ON public.logins USING btree (user_yid, device_id);


--
-- Name: index_members_on_team_yid_and_user_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_team_yid_and_user_yid ON public.members USING btree (team_yid, user_yid);


--
-- Name: index_members_on_user_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_user_yid ON public.members USING btree (user_yid);


--
-- Name: index_memories_on_team_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memories_on_team_yid ON public.memories USING btree (team_yid);


--
-- Name: index_pg_search_documents_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_searchable ON public.pg_search_documents USING btree (searchable_type, searchable_id);


--
-- Name: index_pg_search_documents_on_team_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_team_yid ON public.pg_search_documents USING btree (team_yid, searchable_type);


--
-- Name: index_pictures_on_team_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pictures_on_team_yid ON public.pictures USING btree (team_yid);


--
-- Name: index_record_histories_by_team_and_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_histories_by_team_and_record ON public.record_histories USING btree (team_yid, record_type, record_yid);


--
-- Name: index_record_histories_on_event_and_record_type_and_team_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_histories_on_event_and_record_type_and_team_yid ON public.record_histories USING btree (event, record_type, team_yid);


--
-- Name: index_record_histories_on_event_and_record_type_and_user_yid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_record_histories_on_event_and_record_type_and_user_yid ON public.record_histories USING btree (event, record_type, user_yid);


--
-- Name: index_teams_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_on_name ON public.teams USING btree (name);


--
-- Name: index_thoughts_on_team_yid_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_thoughts_on_team_yid_and_date ON public.thoughts USING btree (team_yid, date);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_nickname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_nickname ON public.users USING btree (nickname);


--
-- Name: index_users_on_temp_auth_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_temp_auth_token ON public.users USING btree (temp_auth_token);


--
-- Name: index_weblinks_on_team_yid_and_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_weblinks_on_team_yid_and_url ON public.weblinks USING btree (team_yid, url);


--
-- Name: weblinks fk_rails_002c4539d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weblinks
    ADD CONSTRAINT fk_rails_002c4539d9 FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: memories fk_rails_03a02381d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_03a02381d6 FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: memories fk_rails_27265945be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_27265945be FOREIGN KEY (weblink_yid) REFERENCES public.weblinks(yid);


--
-- Name: memories fk_rails_33f7ee7b52; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_33f7ee7b52 FOREIGN KEY (picture_yid) REFERENCES public.pictures(yid);


--
-- Name: pictures fk_rails_3aa12f9163; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pictures
    ADD CONSTRAINT fk_rails_3aa12f9163 FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: pg_search_documents fk_rails_3f9424448b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents
    ADD CONSTRAINT fk_rails_3f9424448b FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: logins fk_rails_84b60ee5b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logins
    ADD CONSTRAINT fk_rails_84b60ee5b9 FOREIGN KEY (user_yid) REFERENCES public.users(yid);


--
-- Name: locations fk_rails_8a6c01384d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT fk_rails_8a6c01384d FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: members fk_rails_9dca871716; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_9dca871716 FOREIGN KEY (user_yid) REFERENCES public.users(yid);


--
-- Name: memories fk_rails_af1a11f472; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_af1a11f472 FOREIGN KEY (thought_yid) REFERENCES public.thoughts(yid);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: members fk_rails_d51f76f670; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_d51f76f670 FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- Name: memories fk_rails_d6fe143bd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memories
    ADD CONSTRAINT fk_rails_d6fe143bd0 FOREIGN KEY (location_yid) REFERENCES public.locations(yid);


--
-- Name: thoughts fk_rails_e05c4e3b5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thoughts
    ADD CONSTRAINT fk_rails_e05c4e3b5d FOREIGN KEY (team_yid) REFERENCES public.teams(yid);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20241104193138'),
('20241104193000'),
('20241104192139'),
('20240424191640'),
('20240419151535'),
('20240327101123'),
('20240327101103'),
('20240324205926'),
('20240323232748'),
('20240323124211'),
('20240323091155'),
('20240318233643'),
('20240318213655'),
('20240318104926'),
('20231223182812'),
('20231218220400'),
('20231028161740'),
('20231028105652'),
('20231001185110'),
('20230725150420'),
('20221227155442'),
('20221227155441'),
('20221227155440'),
('20221226181603'),
('20221226175607'),
('20221216234332'),
('20221216225837'),
('20221216205648'),
('20221216004224');

