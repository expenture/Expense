--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_identifiers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type character varying,
    account_uid character varying,
    identifier character varying NOT NULL,
    sample_transaction_description text,
    sample_transaction_party_name character varying,
    sample_transaction_amount integer,
    sample_transaction_datetime timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_identifiers_id_seq OWNED BY account_identifiers.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE accounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    uid character varying NOT NULL,
    kind character varying,
    type character varying DEFAULT 'cash'::character varying NOT NULL,
    name character varying NOT NULL,
    currency character varying DEFAULT 'TWD'::character varying NOT NULL,
    balance integer DEFAULT 0 NOT NULL,
    synchronizer_uid character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE oauth_access_grants (
    id integer NOT NULL,
    resource_owner_id integer NOT NULL,
    application_id integer NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_grants_id_seq OWNED BY oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE oauth_access_tokens (
    id integer NOT NULL,
    resource_owner_id integer,
    application_id integer NOT NULL,
    token text NOT NULL,
    refresh_token text,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_tokens_id_seq OWNED BY oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE oauth_applications (
    id integer NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying,
    type character varying,
    contact_code character varying
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_applications_id_seq OWNED BY oauth_applications.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE settings (
    id integer NOT NULL,
    var character varying NOT NULL,
    value text,
    thing_id integer,
    thing_type character varying(30),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: synchronizer_collected_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE synchronizer_collected_pages (
    id integer NOT NULL,
    synchronizer_uid character varying NOT NULL,
    attribute_1 character varying,
    attribute_2 character varying,
    header text,
    body text,
    parsed_at timestamp without time zone,
    skipped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: synchronizer_collected_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE synchronizer_collected_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synchronizer_collected_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE synchronizer_collected_pages_id_seq OWNED BY synchronizer_collected_pages.id;


--
-- Name: synchronizer_parsed_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE synchronizer_parsed_data (
    id integer NOT NULL,
    collected_page_id integer,
    synchronizer_uid character varying NOT NULL,
    uid character varying NOT NULL,
    attribute_1 character varying,
    attribute_2 character varying,
    raw_data text,
    organized_at timestamp without time zone,
    skipped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: synchronizer_parsed_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE synchronizer_parsed_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synchronizer_parsed_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE synchronizer_parsed_data_id_seq OWNED BY synchronizer_parsed_data.id;


--
-- Name: synchronizers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE synchronizers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    uid character varying NOT NULL,
    type character varying NOT NULL,
    name character varying,
    enabled boolean DEFAULT true NOT NULL,
    schedule character varying DEFAULT 'normal'::character varying NOT NULL,
    encrypted_passcode_1 character varying,
    encrypted_passcode_2 character varying,
    encrypted_passcode_3 character varying,
    encrypted_passcode_4 character varying,
    passcode_encrypt_salt character varying NOT NULL,
    status character varying DEFAULT 'new'::character varying NOT NULL,
    job_uid character varying,
    last_scheduled_at timestamp without time zone,
    last_collected_at timestamp without time zone,
    last_parsed_at timestamp without time zone,
    last_synced_at timestamp without time zone,
    last_errored_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: synchronizers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE synchronizers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synchronizers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE synchronizers_id_seq OWNED BY synchronizers.id;


--
-- Name: transaction_categorization_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE transaction_categorization_cases (
    id integer NOT NULL,
    user_id integer,
    words character varying,
    category_code character varying,
    transaction_uid character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: transaction_categorization_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transaction_categorization_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_categorization_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transaction_categorization_cases_id_seq OWNED BY transaction_categorization_cases.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE transactions (
    id integer NOT NULL,
    uid character varying NOT NULL,
    account_uid character varying NOT NULL,
    kind character varying,
    amount integer NOT NULL,
    description text,
    category_code character varying,
    tags character varying,
    note text,
    datetime timestamp without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    party_type character varying,
    party_code character varying,
    party_name character varying,
    external_image_url character varying,
    separated boolean DEFAULT false NOT NULL,
    separate_transaction_uid character varying,
    on_record boolean,
    record_transaction_uid character varying,
    synchronizer_parsed_data_uid character varying,
    ignore_in_statistics boolean DEFAULT false NOT NULL,
    manually_edited_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    CONSTRAINT on_record_type_and_value_match CHECK (((((kind)::text = 'not_on_record'::text) AND (on_record = false)) OR (((kind)::text <> 'not_on_record'::text) AND (on_record = true)))),
    CONSTRAINT only_virtual_transaction_can_have_separate_transaction_uid CHECK (((((kind)::text <> 'virtual'::text) AND (separate_transaction_uid IS NULL)) OR (((kind)::text = 'virtual'::text) AND (separate_transaction_uid IS NOT NULL)))),
    CONSTRAINT virtual_transaction_can_not_be_seperated CHECK ((((kind)::text <> 'virtual'::text) OR (((kind)::text = 'virtual'::text) AND (separated = false))))
);


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transactions_id_seq OWNED BY transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    password_set_at timestamp without time zone,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    unconfirmed_email character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    mobile character varying,
    unconfirmed_mobile character varying,
    mobile_confirmation_token character varying,
    mobile_confirmation_sent_at timestamp without time zone,
    mobile_confirm_tries integer DEFAULT 0 NOT NULL,
    external_profile_picture_url character varying,
    external_cover_photo_url character varying,
    fb_id character varying,
    fb_email character varying,
    fb_access_token text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_account_uid character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_identifiers ALTER COLUMN id SET DEFAULT nextval('account_identifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('oauth_access_grants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_access_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_applications ALTER COLUMN id SET DEFAULT nextval('oauth_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizer_collected_pages ALTER COLUMN id SET DEFAULT nextval('synchronizer_collected_pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizer_parsed_data ALTER COLUMN id SET DEFAULT nextval('synchronizer_parsed_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizers ALTER COLUMN id SET DEFAULT nextval('synchronizers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transaction_categorization_cases ALTER COLUMN id SET DEFAULT nextval('transaction_categorization_cases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transactions ALTER COLUMN id SET DEFAULT nextval('transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: account_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_identifiers
    ADD CONSTRAINT account_identifiers_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: synchronizer_collected_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizer_collected_pages
    ADD CONSTRAINT synchronizer_collected_pages_pkey PRIMARY KEY (id);


--
-- Name: synchronizer_parsed_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizer_parsed_data
    ADD CONSTRAINT synchronizer_parsed_data_pkey PRIMARY KEY (id);


--
-- Name: synchronizers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizers
    ADD CONSTRAINT synchronizers_pkey PRIMARY KEY (id);


--
-- Name: transaction_categorization_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transaction_categorization_cases
    ADD CONSTRAINT transaction_categorization_cases_pkey PRIMARY KEY (id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_account_identifiers_on_account_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_identifiers_on_account_uid ON account_identifiers USING btree (account_uid);


--
-- Name: index_account_identifiers_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_identifiers_on_identifier ON account_identifiers USING btree (identifier);


--
-- Name: index_account_identifiers_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_identifiers_on_type ON account_identifiers USING btree (type);


--
-- Name: index_account_identifiers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_identifiers_on_user_id ON account_identifiers USING btree (user_id);


--
-- Name: index_accounts_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_deleted_at ON accounts USING btree (deleted_at);


--
-- Name: index_accounts_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_kind ON accounts USING btree (kind);


--
-- Name: index_accounts_on_synchronizer_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_synchronizer_uid ON accounts USING btree (synchronizer_uid);


--
-- Name: index_accounts_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_type ON accounts USING btree (type);


--
-- Name: index_accounts_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_uid ON accounts USING btree (uid);


--
-- Name: index_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_user_id ON accounts USING btree (user_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_applications_on_owner_id_and_owner_type ON oauth_applications USING btree (owner_id, owner_type);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON oauth_applications USING btree (uid);


--
-- Name: index_settings_on_thing_type_and_thing_id_and_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_thing_type_and_thing_id_and_var ON settings USING btree (thing_type, thing_id, var);


--
-- Name: index_synchronizer_collected_pages_on_parsed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_collected_pages_on_parsed_at ON synchronizer_collected_pages USING btree (parsed_at);


--
-- Name: index_synchronizer_collected_pages_on_skipped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_collected_pages_on_skipped_at ON synchronizer_collected_pages USING btree (skipped_at);


--
-- Name: index_synchronizer_collected_pages_on_synchronizer_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_collected_pages_on_synchronizer_uid ON synchronizer_collected_pages USING btree (synchronizer_uid);


--
-- Name: index_synchronizer_parsed_data_on_collected_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_parsed_data_on_collected_page_id ON synchronizer_parsed_data USING btree (collected_page_id);


--
-- Name: index_synchronizer_parsed_data_on_organized_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_parsed_data_on_organized_at ON synchronizer_parsed_data USING btree (organized_at);


--
-- Name: index_synchronizer_parsed_data_on_skipped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_parsed_data_on_skipped_at ON synchronizer_parsed_data USING btree (skipped_at);


--
-- Name: index_synchronizer_parsed_data_on_synchronizer_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizer_parsed_data_on_synchronizer_uid ON synchronizer_parsed_data USING btree (synchronizer_uid);


--
-- Name: index_synchronizer_parsed_data_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_synchronizer_parsed_data_on_uid ON synchronizer_parsed_data USING btree (uid);


--
-- Name: index_synchronizers_on_last_errored_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizers_on_last_errored_at ON synchronizers USING btree (last_errored_at);


--
-- Name: index_synchronizers_on_last_synced_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizers_on_last_synced_at ON synchronizers USING btree (last_synced_at);


--
-- Name: index_synchronizers_on_schedule; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizers_on_schedule ON synchronizers USING btree (schedule);


--
-- Name: index_synchronizers_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizers_on_type ON synchronizers USING btree (type);


--
-- Name: index_synchronizers_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_synchronizers_on_uid ON synchronizers USING btree (uid);


--
-- Name: index_synchronizers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronizers_on_user_id ON synchronizers USING btree (user_id);


--
-- Name: index_transaction_categorization_cases_on_category_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_categorization_cases_on_category_code ON transaction_categorization_cases USING btree (category_code);


--
-- Name: index_transaction_categorization_cases_on_transaction_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_categorization_cases_on_transaction_uid ON transaction_categorization_cases USING btree (transaction_uid);


--
-- Name: index_transaction_categorization_cases_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_categorization_cases_on_user_id ON transaction_categorization_cases USING btree (user_id);


--
-- Name: index_transactions_on_account_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_account_uid ON transactions USING btree (account_uid);


--
-- Name: index_transactions_on_category_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_category_code ON transactions USING btree (category_code);


--
-- Name: index_transactions_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_deleted_at ON transactions USING btree (deleted_at);


--
-- Name: index_transactions_on_ignore_in_statistics; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_ignore_in_statistics ON transactions USING btree (ignore_in_statistics);


--
-- Name: index_transactions_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_kind ON transactions USING btree (kind);


--
-- Name: index_transactions_on_manually_edited_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_manually_edited_at ON transactions USING btree (manually_edited_at);


--
-- Name: index_transactions_on_on_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_on_record ON transactions USING btree (on_record);


--
-- Name: index_transactions_on_record_transaction_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_record_transaction_uid ON transactions USING btree (record_transaction_uid);


--
-- Name: index_transactions_on_separate_transaction_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_separate_transaction_uid ON transactions USING btree (separate_transaction_uid);


--
-- Name: index_transactions_on_separated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_separated ON transactions USING btree (separated);


--
-- Name: index_transactions_on_synchronizer_parsed_data_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_synchronizer_parsed_data_uid ON transactions USING btree (synchronizer_parsed_data_uid);


--
-- Name: index_transactions_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transactions_on_uid ON transactions USING btree (uid);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_default_account_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_default_account_uid ON users USING btree (default_account_uid);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_fb_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_fb_email ON users USING btree (fb_email);


--
-- Name: index_users_on_fb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_fb_id ON users USING btree (fb_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_rails_5d4d224157; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronizers
    ADD CONSTRAINT fk_rails_5d4d224157 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_8fb4f0213e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_identifiers
    ADD CONSTRAINT fk_rails_8fb4f0213e FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_rails_aab1858596; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT fk_rails_aab1858596 FOREIGN KEY (account_uid) REFERENCES accounts(uid) ON DELETE CASCADE;


--
-- Name: fk_rails_b1e30bebc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_b1e30bebc8 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES oauth_applications(id) ON DELETE CASCADE;


--
-- Name: fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160219134605'), ('20160221210444'), ('20160221210951'), ('20160224142347'), ('20160224153424'), ('20160226144407'), ('20160228064613'), ('20160301184459'), ('20160313182018'), ('20160314001457'), ('20160314114631'), ('20160323223854'), ('20160515034624'), ('20160515043500'), ('20160520195839'), ('20160520195919');


