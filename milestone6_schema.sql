--
-- PostgreSQL database dump
--

\restrict fwTcOWRQVu1wUcM74uiogOdkf2HBlsgdpyx4WqWYktSorGVuaCeTChxJdv51KyX

-- Dumped from database version 16.12 (Debian 16.12-1.pgdg13+1)
-- Dumped by pg_dump version 16.12 (Debian 16.12-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: account_kind; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.account_kind AS ENUM (
    'demo',
    'personal_live',
    'prop_challenge',
    'prop_verification',
    'prop_funded'
);


ALTER TYPE public.account_kind OWNER TO tradebot;

--
-- Name: approval_decision; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.approval_decision AS ENUM (
    'approve',
    'reject',
    'snooze'
);


ALTER TYPE public.approval_decision OWNER TO tradebot;

--
-- Name: broker_code; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.broker_code AS ENUM (
    'vantage',
    'ftmo',
    'traderscale',
    'fundednext',
    'startrader',
    'vtmarkets'
);


ALTER TYPE public.broker_code OWNER TO tradebot;

--
-- Name: channel_kind; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.channel_kind AS ENUM (
    'forex',
    'crypto',
    'indices',
    'mixed'
);


ALTER TYPE public.channel_kind OWNER TO tradebot;

--
-- Name: exec_status; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.exec_status AS ENUM (
    'queued',
    'sent',
    'accepted',
    'rejected',
    'partial',
    'filled',
    'modified',
    'closed',
    'error'
);


ALTER TYPE public.exec_status OWNER TO tradebot;

--
-- Name: intent_status; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.intent_status AS ENUM (
    'received',
    'parsed',
    'candidate_pending',
    'pending_update',
    'planned',
    'awaiting_approval',
    'approved',
    'rejected',
    'executing',
    'executed',
    'failed',
    'cancelled'
);


ALTER TYPE public.intent_status OWNER TO tradebot;

--
-- Name: leg_role; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.leg_role AS ENUM (
    'tp',
    'runner',
    'single'
);


ALTER TYPE public.leg_role OWNER TO tradebot;

--
-- Name: order_type; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.order_type AS ENUM (
    'market',
    'limit',
    'stop'
);


ALTER TYPE public.order_type OWNER TO tradebot;

--
-- Name: platform_code; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.platform_code AS ENUM (
    'mt4',
    'mt5'
);


ALTER TYPE public.platform_code OWNER TO tradebot;

--
-- Name: policy_outcome; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.policy_outcome AS ENUM (
    'allow',
    'require_approval',
    'block'
);


ALTER TYPE public.policy_outcome OWNER TO tradebot;

--
-- Name: provider_code; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.provider_code AS ENUM (
    'fredtrading',
    'billionaire_club',
    'mubeen'
);


ALTER TYPE public.provider_code OWNER TO tradebot;

--
-- Name: risk_tag; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.risk_tag AS ENUM (
    'unknown',
    'normal',
    'half',
    'tiny',
    'high'
);


ALTER TYPE public.risk_tag OWNER TO tradebot;

--
-- Name: trade_side; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.trade_side AS ENUM (
    'buy',
    'sell'
);


ALTER TYPE public.trade_side OWNER TO tradebot;

--
-- Name: update_kind; Type: TYPE; Schema: public; Owner: tradebot
--

CREATE TYPE public.update_kind AS ENUM (
    'set_sl_tp',
    'move_sl_to_entry',
    'move_tp',
    'close_partial',
    'close_all',
    'reenter'
);


ALTER TYPE public.update_kind OWNER TO tradebot;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_risk_state; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.account_risk_state (
    snapshot_id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    as_of timestamp with time zone NOT NULL,
    balance numeric(18,2),
    equity numeric(18,2),
    floating_pl numeric(18,2),
    daily_pl numeric(18,2),
    daily_dd numeric(18,2),
    total_dd numeric(18,2),
    source text DEFAULT 'terminal'::text NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.account_risk_state OWNER TO tradebot;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO tradebot;

--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.app_settings OWNER TO tradebot;

--
-- Name: approvals; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.approvals (
    approval_id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    control_chat_id bigint,
    control_message_id bigint,
    requested_by_user_id uuid,
    decision_by_telegram_user_id bigint,
    decision public.approval_decision,
    decided_at timestamp with time zone,
    snooze_until timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.approvals OWNER TO tradebot;

--
-- Name: broker_accounts; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.broker_accounts (
    account_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    broker public.broker_code NOT NULL,
    platform public.platform_code NOT NULL,
    kind public.account_kind NOT NULL,
    label text NOT NULL,
    prop_firm public.broker_code,
    prop_phase text,
    base_currency text DEFAULT 'USD'::text NOT NULL,
    equity_start numeric(18,2),
    is_active boolean DEFAULT true NOT NULL,
    allowed_providers public.provider_code[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.broker_accounts OWNER TO tradebot;

--
-- Name: broker_credentials; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.broker_credentials (
    cred_id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    login text,
    server text,
    password_cipher bytea,
    password_nonce bytea,
    kek_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.broker_credentials OWNER TO tradebot;

--
-- Name: control_actions; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.control_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    telegram_user_id bigint,
    control_chat_id bigint,
    control_message_id bigint,
    action text NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL
);


ALTER TABLE public.control_actions OWNER TO tradebot;

--
-- Name: entry_jitter_policies; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.entry_jitter_policies (
    jitter_id uuid DEFAULT gen_random_uuid() NOT NULL,
    broker public.broker_code NOT NULL,
    platform public.platform_code NOT NULL,
    canonical text NOT NULL,
    max_jitter numeric(18,10) NOT NULL,
    leg_step numeric(18,10) NOT NULL,
    apply_to text DEFAULT 'limit_stop'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.entry_jitter_policies OWNER TO tradebot;

--
-- Name: execution_batches; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.execution_batches (
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    account_id uuid NOT NULL,
    executor_node text NOT NULL,
    request_id text NOT NULL,
    status public.exec_status DEFAULT 'queued'::public.exec_status NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.execution_batches OWNER TO tradebot;

--
-- Name: execution_events; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.execution_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    leg_id uuid,
    status public.exec_status NOT NULL,
    terminal_order_id bigint,
    terminal_position_id bigint,
    fill_price numeric(18,10),
    filled_lots numeric(18,4),
    message text,
    raw_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.execution_events OWNER TO tradebot;

--
-- Name: lot_sizing_profiles; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.lot_sizing_profiles (
    profile_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider public.provider_code NOT NULL,
    broker public.broker_code NOT NULL,
    account_size integer NOT NULL,
    lot_total numeric(18,4) NOT NULL,
    legs_hint integer,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.lot_sizing_profiles OWNER TO tradebot;

--
-- Name: open_positions; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.open_positions (
    pos_id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    broker_symbol text NOT NULL,
    symbol_canonical text,
    side public.trade_side NOT NULL,
    entry_price numeric(18,10),
    sl_price numeric(18,10),
    tp_price numeric(18,10),
    lots numeric(18,4),
    terminal_position_id bigint,
    terminal_order_id bigint,
    linked_leg_id uuid,
    linked_plan_id uuid,
    opened_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_open boolean DEFAULT true NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.open_positions OWNER TO tradebot;

--
-- Name: plan_risk_checks; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.plan_risk_checks (
    check_id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    ruleset_id uuid,
    as_of_snapshot_id uuid,
    est_sl_loss_ccy numeric(18,2),
    est_sl_loss_pct numeric(6,3),
    outcome public.policy_outcome NOT NULL,
    reasons text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.plan_risk_checks OWNER TO tradebot;

--
-- Name: prop_rulesets; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.prop_rulesets (
    ruleset_id uuid DEFAULT gen_random_uuid() NOT NULL,
    broker public.broker_code NOT NULL,
    phase text NOT NULL,
    currency text DEFAULT 'USD'::text NOT NULL,
    max_daily_loss_pct numeric(6,3),
    max_total_loss_pct numeric(6,3),
    profit_target_pct numeric(6,3),
    min_trading_days integer,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.prop_rulesets OWNER TO tradebot;

--
-- Name: provider_account_routes; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.provider_account_routes (
    id integer NOT NULL,
    provider_code text NOT NULL,
    broker_account_id uuid NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.provider_account_routes OWNER TO tradebot;

--
-- Name: provider_account_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: tradebot
--

CREATE SEQUENCE public.provider_account_routes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.provider_account_routes_id_seq OWNER TO tradebot;

--
-- Name: provider_account_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tradebot
--

ALTER SEQUENCE public.provider_account_routes_id_seq OWNED BY public.provider_account_routes.id;


--
-- Name: providers; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.providers (
    provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code public.provider_code NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.providers OWNER TO tradebot;

--
-- Name: risk_multipliers; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.risk_multipliers (
    provider public.provider_code NOT NULL,
    tag public.risk_tag NOT NULL,
    multiplier numeric(6,3) NOT NULL,
    requires_approval boolean DEFAULT false NOT NULL
);


ALTER TABLE public.risk_multipliers OWNER TO tradebot;

--
-- Name: routing_decisions; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.routing_decisions (
    id bigint NOT NULL,
    telegram_message_id bigint,
    chat_id bigint NOT NULL,
    provider_code text,
    broker_account_id uuid,
    decision text NOT NULL,
    reason text,
    message_ts timestamp with time zone,
    raw_meta jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    message_id integer NOT NULL,
    telegram_msg_pk uuid
);


ALTER TABLE public.routing_decisions OWNER TO tradebot;

--
-- Name: COLUMN routing_decisions.decision; Type: COMMENT; Schema: public; Owner: tradebot
--

COMMENT ON COLUMN public.routing_decisions.decision IS '"ROUTED" | "IGNORED_UNKNOWN_CHAT" | "IGNORED_NO_ACCOUNT"';


--
-- Name: routing_decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: tradebot
--

CREATE SEQUENCE public.routing_decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.routing_decisions_id_seq OWNER TO tradebot;

--
-- Name: routing_decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tradebot
--

ALTER SEQUENCE public.routing_decisions_id_seq OWNED BY public.routing_decisions.id;


--
-- Name: symbol_mappings; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.symbol_mappings (
    mapping_id uuid DEFAULT gen_random_uuid() NOT NULL,
    broker public.broker_code NOT NULL,
    platform public.platform_code NOT NULL,
    canonical text NOT NULL,
    broker_symbol text NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.symbol_mappings OWNER TO tradebot;

--
-- Name: symbols; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.symbols (
    symbol_id uuid DEFAULT gen_random_uuid() NOT NULL,
    canonical text NOT NULL,
    asset_class text NOT NULL,
    pip_size numeric(18,10),
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.symbols OWNER TO tradebot;

--
-- Name: telegram_chats; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.telegram_chats (
    chat_id bigint NOT NULL,
    title text,
    username text,
    provider_code public.provider_code,
    channel_kind public.channel_kind DEFAULT 'mixed'::public.channel_kind NOT NULL,
    is_control_chat boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.telegram_chats OWNER TO tradebot;

--
-- Name: telegram_messages; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.telegram_messages (
    msg_pk uuid DEFAULT gen_random_uuid() NOT NULL,
    chat_id bigint NOT NULL,
    message_id bigint NOT NULL,
    sender_id bigint,
    sent_at timestamp with time zone,
    text text,
    raw_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_edited boolean DEFAULT false NOT NULL,
    edited_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.telegram_messages OWNER TO tradebot;

--
-- Name: trade_families; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.trade_families (
    family_id uuid DEFAULT gen_random_uuid() NOT NULL,
    intent_id uuid NOT NULL,
    plan_id uuid,
    provider text NOT NULL,
    account_id uuid,
    chat_id bigint,
    source_msg_pk uuid NOT NULL,
    symbol_canonical text,
    side text,
    entry_price numeric(18,10),
    sl_price numeric(18,10),
    tp_count integer DEFAULT 0 NOT NULL,
    state text DEFAULT 'OPEN'::text NOT NULL,
    is_stub boolean DEFAULT false NOT NULL,
    management_rules json DEFAULT '{}'::jsonb NOT NULL,
    meta json DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.trade_families OWNER TO tradebot;

--
-- Name: trade_intents; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.trade_intents (
    intent_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    provider public.provider_code NOT NULL,
    chat_id bigint NOT NULL,
    source_msg_pk uuid NOT NULL,
    source_message_id bigint NOT NULL,
    dedupe_hash text NOT NULL,
    parse_confidence numeric(4,3) DEFAULT 0.0 NOT NULL,
    status public.intent_status DEFAULT 'received'::public.intent_status NOT NULL,
    symbol_canonical text,
    symbol_raw text,
    side public.trade_side,
    order_type public.order_type,
    entry_price numeric(18,10),
    sl_price numeric(18,10),
    tp_prices numeric(18,10)[],
    has_runner boolean DEFAULT false NOT NULL,
    risk_tag public.risk_tag DEFAULT 'unknown'::public.risk_tag NOT NULL,
    is_scalp boolean DEFAULT false NOT NULL,
    is_swing boolean DEFAULT false NOT NULL,
    is_unofficial boolean DEFAULT false NOT NULL,
    reenter_tag boolean DEFAULT false NOT NULL,
    instructions text,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.trade_intents OWNER TO tradebot;

--
-- Name: trade_legs; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.trade_legs (
    leg_id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    idx integer NOT NULL,
    role public.leg_role DEFAULT 'tp'::public.leg_role NOT NULL,
    entry_price numeric(18,10),
    sl_price numeric(18,10),
    tp_price numeric(18,10),
    lots numeric(18,4) NOT NULL,
    entry_jitter_applied numeric(18,10),
    entry_jitter_policy_id uuid,
    move_sl_to_entry_at_tp1 boolean DEFAULT true NOT NULL,
    is_tp1 boolean DEFAULT false NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    family_id uuid,
    leg_index integer,
    state text DEFAULT 'OPEN'::text NOT NULL
);


ALTER TABLE public.trade_legs OWNER TO tradebot;

--
-- Name: trade_plans; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.trade_plans (
    plan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    intent_id uuid NOT NULL,
    account_id uuid NOT NULL,
    policy_outcome public.policy_outcome NOT NULL,
    requires_approval boolean DEFAULT false NOT NULL,
    lot_total numeric(18,4),
    lot_per_leg numeric(18,4),
    legs_count integer DEFAULT 1 NOT NULL,
    candidate_expires_at timestamp with time zone,
    policy_reasons text[],
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.trade_plans OWNER TO tradebot;

--
-- Name: trade_updates; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.trade_updates (
    update_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider public.provider_code NOT NULL,
    chat_id bigint NOT NULL,
    source_msg_pk uuid NOT NULL,
    kind public.update_kind NOT NULL,
    symbol_canonical text,
    target_intent_id uuid,
    target_plan_id uuid,
    new_entry_price numeric(18,10),
    new_sl_price numeric(18,10),
    new_tp_prices numeric(18,10)[],
    instruction_text text,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.trade_updates OWNER TO tradebot;

--
-- Name: users; Type: TABLE; Schema: public; Owner: tradebot
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    telegram_user_id bigint,
    display_name text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO tradebot;

--
-- Name: provider_account_routes id; Type: DEFAULT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.provider_account_routes ALTER COLUMN id SET DEFAULT nextval('public.provider_account_routes_id_seq'::regclass);


--
-- Name: routing_decisions id; Type: DEFAULT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.routing_decisions ALTER COLUMN id SET DEFAULT nextval('public.routing_decisions_id_seq'::regclass);


--
-- Name: account_risk_state account_risk_state_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.account_risk_state
    ADD CONSTRAINT account_risk_state_pkey PRIMARY KEY (snapshot_id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: approvals approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_pkey PRIMARY KEY (approval_id);


--
-- Name: broker_accounts broker_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_accounts
    ADD CONSTRAINT broker_accounts_pkey PRIMARY KEY (account_id);


--
-- Name: broker_accounts broker_accounts_user_id_broker_platform_label_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_accounts
    ADD CONSTRAINT broker_accounts_user_id_broker_platform_label_key UNIQUE (user_id, broker, platform, label);


--
-- Name: broker_credentials broker_credentials_account_id_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_credentials
    ADD CONSTRAINT broker_credentials_account_id_key UNIQUE (account_id);


--
-- Name: broker_credentials broker_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_credentials
    ADD CONSTRAINT broker_credentials_pkey PRIMARY KEY (cred_id);


--
-- Name: control_actions control_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.control_actions
    ADD CONSTRAINT control_actions_pkey PRIMARY KEY (id);


--
-- Name: entry_jitter_policies entry_jitter_policies_broker_platform_canonical_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.entry_jitter_policies
    ADD CONSTRAINT entry_jitter_policies_broker_platform_canonical_key UNIQUE (broker, platform, canonical);


--
-- Name: entry_jitter_policies entry_jitter_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.entry_jitter_policies
    ADD CONSTRAINT entry_jitter_policies_pkey PRIMARY KEY (jitter_id);


--
-- Name: execution_batches execution_batches_account_id_request_id_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_batches
    ADD CONSTRAINT execution_batches_account_id_request_id_key UNIQUE (account_id, request_id);


--
-- Name: execution_batches execution_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_batches
    ADD CONSTRAINT execution_batches_pkey PRIMARY KEY (batch_id);


--
-- Name: execution_events execution_events_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_events
    ADD CONSTRAINT execution_events_pkey PRIMARY KEY (event_id);


--
-- Name: lot_sizing_profiles lot_sizing_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.lot_sizing_profiles
    ADD CONSTRAINT lot_sizing_profiles_pkey PRIMARY KEY (profile_id);


--
-- Name: lot_sizing_profiles lot_sizing_profiles_provider_broker_account_size_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.lot_sizing_profiles
    ADD CONSTRAINT lot_sizing_profiles_provider_broker_account_size_key UNIQUE (provider, broker, account_size);


--
-- Name: open_positions open_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.open_positions
    ADD CONSTRAINT open_positions_pkey PRIMARY KEY (pos_id);


--
-- Name: plan_risk_checks plan_risk_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.plan_risk_checks
    ADD CONSTRAINT plan_risk_checks_pkey PRIMARY KEY (check_id);


--
-- Name: prop_rulesets prop_rulesets_broker_phase_currency_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.prop_rulesets
    ADD CONSTRAINT prop_rulesets_broker_phase_currency_key UNIQUE (broker, phase, currency);


--
-- Name: prop_rulesets prop_rulesets_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.prop_rulesets
    ADD CONSTRAINT prop_rulesets_pkey PRIMARY KEY (ruleset_id);


--
-- Name: provider_account_routes provider_account_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.provider_account_routes
    ADD CONSTRAINT provider_account_routes_pkey PRIMARY KEY (id);


--
-- Name: providers providers_code_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.providers
    ADD CONSTRAINT providers_code_key UNIQUE (code);


--
-- Name: providers providers_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.providers
    ADD CONSTRAINT providers_pkey PRIMARY KEY (provider_id);


--
-- Name: risk_multipliers risk_multipliers_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.risk_multipliers
    ADD CONSTRAINT risk_multipliers_pkey PRIMARY KEY (provider, tag);


--
-- Name: routing_decisions routing_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.routing_decisions
    ADD CONSTRAINT routing_decisions_pkey PRIMARY KEY (id);


--
-- Name: symbol_mappings symbol_mappings_broker_platform_broker_symbol_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbol_mappings
    ADD CONSTRAINT symbol_mappings_broker_platform_broker_symbol_key UNIQUE (broker, platform, broker_symbol);


--
-- Name: symbol_mappings symbol_mappings_broker_platform_canonical_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbol_mappings
    ADD CONSTRAINT symbol_mappings_broker_platform_canonical_key UNIQUE (broker, platform, canonical);


--
-- Name: symbol_mappings symbol_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbol_mappings
    ADD CONSTRAINT symbol_mappings_pkey PRIMARY KEY (mapping_id);


--
-- Name: symbols symbols_canonical_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbols
    ADD CONSTRAINT symbols_canonical_key UNIQUE (canonical);


--
-- Name: symbols symbols_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbols
    ADD CONSTRAINT symbols_pkey PRIMARY KEY (symbol_id);


--
-- Name: telegram_chats telegram_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.telegram_chats
    ADD CONSTRAINT telegram_chats_pkey PRIMARY KEY (chat_id);


--
-- Name: telegram_messages telegram_messages_chat_id_message_id_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT telegram_messages_chat_id_message_id_key UNIQUE (chat_id, message_id);


--
-- Name: telegram_messages telegram_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT telegram_messages_pkey PRIMARY KEY (msg_pk);


--
-- Name: trade_families trade_families_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_families
    ADD CONSTRAINT trade_families_pkey PRIMARY KEY (family_id);


--
-- Name: trade_intents trade_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_pkey PRIMARY KEY (intent_id);


--
-- Name: trade_intents trade_intents_provider_chat_id_source_message_id_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_provider_chat_id_source_message_id_key UNIQUE (provider, chat_id, source_message_id);


--
-- Name: trade_legs trade_legs_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_legs
    ADD CONSTRAINT trade_legs_pkey PRIMARY KEY (leg_id);


--
-- Name: trade_plans trade_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_plans
    ADD CONSTRAINT trade_plans_pkey PRIMARY KEY (plan_id);


--
-- Name: trade_updates trade_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_pkey PRIMARY KEY (update_id);


--
-- Name: provider_account_routes uq_provider_account_routes_provider_account; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.provider_account_routes
    ADD CONSTRAINT uq_provider_account_routes_provider_account UNIQUE (provider_code, broker_account_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_telegram_user_id_key; Type: CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_telegram_user_id_key UNIQUE (telegram_user_id);


--
-- Name: idx_account_risk_state_account_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_account_risk_state_account_time ON public.account_risk_state USING btree (account_id, as_of DESC);


--
-- Name: idx_approvals_decision; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_approvals_decision ON public.approvals USING btree (decision, decided_at DESC);


--
-- Name: idx_approvals_plan; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_approvals_plan ON public.approvals USING btree (plan_id);


--
-- Name: idx_broker_accounts_active; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_broker_accounts_active ON public.broker_accounts USING btree (is_active);


--
-- Name: idx_broker_accounts_broker_platform; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_broker_accounts_broker_platform ON public.broker_accounts USING btree (broker, platform);


--
-- Name: idx_control_actions_status_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_control_actions_status_time ON public.control_actions USING btree (status, created_at DESC);


--
-- Name: idx_execution_batches_plan; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_execution_batches_plan ON public.execution_batches USING btree (plan_id);


--
-- Name: idx_execution_events_batch_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_execution_events_batch_time ON public.execution_events USING btree (batch_id, created_at DESC);


--
-- Name: idx_execution_events_leg; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_execution_events_leg ON public.execution_events USING btree (leg_id);


--
-- Name: idx_open_positions_account_open; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_open_positions_account_open ON public.open_positions USING btree (account_id, is_open);


--
-- Name: idx_open_positions_plan; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_open_positions_plan ON public.open_positions USING btree (linked_plan_id);


--
-- Name: idx_plan_risk_checks_plan; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_plan_risk_checks_plan ON public.plan_risk_checks USING btree (plan_id);


--
-- Name: idx_symbol_mappings_enabled; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_symbol_mappings_enabled ON public.symbol_mappings USING btree (broker, platform, is_enabled);


--
-- Name: idx_telegram_chats_provider; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_telegram_chats_provider ON public.telegram_chats USING btree (provider_code);


--
-- Name: idx_telegram_messages_chat_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_telegram_messages_chat_time ON public.telegram_messages USING btree (chat_id, sent_at DESC);


--
-- Name: idx_trade_families_provider_symbol_state; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_families_provider_symbol_state ON public.trade_families USING btree (provider, symbol_canonical, state);


--
-- Name: idx_trade_intents_dedupe_hash; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_intents_dedupe_hash ON public.trade_intents USING btree (dedupe_hash);


--
-- Name: idx_trade_intents_provider_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_intents_provider_time ON public.trade_intents USING btree (provider, created_at DESC);


--
-- Name: idx_trade_intents_status; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_intents_status ON public.trade_intents USING btree (status);


--
-- Name: idx_trade_legs_plan; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_legs_plan ON public.trade_legs USING btree (plan_id);


--
-- Name: idx_trade_plans_account_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_plans_account_time ON public.trade_plans USING btree (account_id, created_at DESC);


--
-- Name: idx_trade_plans_intent; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_plans_intent ON public.trade_plans USING btree (intent_id);


--
-- Name: idx_trade_updates_provider_time; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_updates_provider_time ON public.trade_updates USING btree (provider, created_at DESC);


--
-- Name: idx_trade_updates_target_intent; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX idx_trade_updates_target_intent ON public.trade_updates USING btree (target_intent_id);


--
-- Name: ix_routing_decisions_chat_id; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX ix_routing_decisions_chat_id ON public.routing_decisions USING btree (chat_id);


--
-- Name: ix_routing_decisions_provider_code; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX ix_routing_decisions_provider_code ON public.routing_decisions USING btree (provider_code);


--
-- Name: ix_routing_decisions_telegram_msg_pk; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE INDEX ix_routing_decisions_telegram_msg_pk ON public.routing_decisions USING btree (telegram_msg_pk);


--
-- Name: uq_provider_account_routes_one_active; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_provider_account_routes_one_active ON public.provider_account_routes USING btree (provider_code) WHERE (is_active = true);


--
-- Name: uq_routing_decisions_chat_message; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_routing_decisions_chat_message ON public.routing_decisions USING btree (chat_id, message_id);


--
-- Name: uq_trade_families_source_msg_pk; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_trade_families_source_msg_pk ON public.trade_families USING btree (source_msg_pk);


--
-- Name: uq_trade_intents_source_msg_pk; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_trade_intents_source_msg_pk ON public.trade_intents USING btree (source_msg_pk);


--
-- Name: uq_trade_legs_plan_idx; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_trade_legs_plan_idx ON public.trade_legs USING btree (plan_id, idx);


--
-- Name: uq_trade_updates_source_msg_pk; Type: INDEX; Schema: public; Owner: tradebot
--

CREATE UNIQUE INDEX uq_trade_updates_source_msg_pk ON public.trade_updates USING btree (source_msg_pk);


--
-- Name: account_risk_state account_risk_state_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.account_risk_state
    ADD CONSTRAINT account_risk_state_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.broker_accounts(account_id) ON DELETE CASCADE;


--
-- Name: approvals approvals_control_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_control_chat_id_fkey FOREIGN KEY (control_chat_id) REFERENCES public.telegram_chats(chat_id);


--
-- Name: approvals approvals_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.trade_plans(plan_id) ON DELETE CASCADE;


--
-- Name: approvals approvals_requested_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.approvals
    ADD CONSTRAINT approvals_requested_by_user_id_fkey FOREIGN KEY (requested_by_user_id) REFERENCES public.users(user_id);


--
-- Name: broker_accounts broker_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_accounts
    ADD CONSTRAINT broker_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: broker_credentials broker_credentials_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.broker_credentials
    ADD CONSTRAINT broker_credentials_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.broker_accounts(account_id) ON DELETE CASCADE;


--
-- Name: entry_jitter_policies entry_jitter_policies_canonical_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.entry_jitter_policies
    ADD CONSTRAINT entry_jitter_policies_canonical_fkey FOREIGN KEY (canonical) REFERENCES public.symbols(canonical) ON DELETE CASCADE;


--
-- Name: execution_batches execution_batches_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_batches
    ADD CONSTRAINT execution_batches_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.broker_accounts(account_id);


--
-- Name: execution_batches execution_batches_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_batches
    ADD CONSTRAINT execution_batches_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.trade_plans(plan_id) ON DELETE CASCADE;


--
-- Name: execution_events execution_events_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_events
    ADD CONSTRAINT execution_events_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.execution_batches(batch_id) ON DELETE CASCADE;


--
-- Name: execution_events execution_events_leg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.execution_events
    ADD CONSTRAINT execution_events_leg_id_fkey FOREIGN KEY (leg_id) REFERENCES public.trade_legs(leg_id) ON DELETE SET NULL;


--
-- Name: routing_decisions fk_routing_decisions_telegram_msg_pk; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.routing_decisions
    ADD CONSTRAINT fk_routing_decisions_telegram_msg_pk FOREIGN KEY (telegram_msg_pk) REFERENCES public.telegram_messages(msg_pk) ON DELETE SET NULL;


--
-- Name: open_positions open_positions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.open_positions
    ADD CONSTRAINT open_positions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.broker_accounts(account_id) ON DELETE CASCADE;


--
-- Name: open_positions open_positions_linked_leg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.open_positions
    ADD CONSTRAINT open_positions_linked_leg_id_fkey FOREIGN KEY (linked_leg_id) REFERENCES public.trade_legs(leg_id);


--
-- Name: open_positions open_positions_linked_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.open_positions
    ADD CONSTRAINT open_positions_linked_plan_id_fkey FOREIGN KEY (linked_plan_id) REFERENCES public.trade_plans(plan_id);


--
-- Name: open_positions open_positions_symbol_canonical_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.open_positions
    ADD CONSTRAINT open_positions_symbol_canonical_fkey FOREIGN KEY (symbol_canonical) REFERENCES public.symbols(canonical);


--
-- Name: plan_risk_checks plan_risk_checks_as_of_snapshot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.plan_risk_checks
    ADD CONSTRAINT plan_risk_checks_as_of_snapshot_id_fkey FOREIGN KEY (as_of_snapshot_id) REFERENCES public.account_risk_state(snapshot_id);


--
-- Name: plan_risk_checks plan_risk_checks_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.plan_risk_checks
    ADD CONSTRAINT plan_risk_checks_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.trade_plans(plan_id) ON DELETE CASCADE;


--
-- Name: plan_risk_checks plan_risk_checks_ruleset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.plan_risk_checks
    ADD CONSTRAINT plan_risk_checks_ruleset_id_fkey FOREIGN KEY (ruleset_id) REFERENCES public.prop_rulesets(ruleset_id);


--
-- Name: provider_account_routes provider_account_routes_broker_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.provider_account_routes
    ADD CONSTRAINT provider_account_routes_broker_account_id_fkey FOREIGN KEY (broker_account_id) REFERENCES public.broker_accounts(account_id) ON DELETE RESTRICT;


--
-- Name: symbol_mappings symbol_mappings_canonical_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.symbol_mappings
    ADD CONSTRAINT symbol_mappings_canonical_fkey FOREIGN KEY (canonical) REFERENCES public.symbols(canonical) ON DELETE CASCADE;


--
-- Name: telegram_messages telegram_messages_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT telegram_messages_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.telegram_chats(chat_id);


--
-- Name: trade_families trade_families_intent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_families
    ADD CONSTRAINT trade_families_intent_id_fkey FOREIGN KEY (intent_id) REFERENCES public.trade_intents(intent_id) ON DELETE CASCADE;


--
-- Name: trade_families trade_families_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_families
    ADD CONSTRAINT trade_families_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.trade_plans(plan_id) ON DELETE SET NULL;


--
-- Name: trade_intents trade_intents_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.telegram_chats(chat_id);


--
-- Name: trade_intents trade_intents_source_msg_pk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_source_msg_pk_fkey FOREIGN KEY (source_msg_pk) REFERENCES public.telegram_messages(msg_pk) ON DELETE CASCADE;


--
-- Name: trade_intents trade_intents_symbol_canonical_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_symbol_canonical_fkey FOREIGN KEY (symbol_canonical) REFERENCES public.symbols(canonical);


--
-- Name: trade_intents trade_intents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_intents
    ADD CONSTRAINT trade_intents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: trade_legs trade_legs_entry_jitter_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_legs
    ADD CONSTRAINT trade_legs_entry_jitter_policy_id_fkey FOREIGN KEY (entry_jitter_policy_id) REFERENCES public.entry_jitter_policies(jitter_id);


--
-- Name: trade_legs trade_legs_family_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_legs
    ADD CONSTRAINT trade_legs_family_id_fkey FOREIGN KEY (family_id) REFERENCES public.trade_families(family_id) ON DELETE CASCADE;


--
-- Name: trade_legs trade_legs_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_legs
    ADD CONSTRAINT trade_legs_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.trade_plans(plan_id) ON DELETE CASCADE;


--
-- Name: trade_plans trade_plans_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_plans
    ADD CONSTRAINT trade_plans_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.broker_accounts(account_id);


--
-- Name: trade_plans trade_plans_intent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_plans
    ADD CONSTRAINT trade_plans_intent_id_fkey FOREIGN KEY (intent_id) REFERENCES public.trade_intents(intent_id) ON DELETE CASCADE;


--
-- Name: trade_updates trade_updates_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.telegram_chats(chat_id);


--
-- Name: trade_updates trade_updates_source_msg_pk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_source_msg_pk_fkey FOREIGN KEY (source_msg_pk) REFERENCES public.telegram_messages(msg_pk) ON DELETE CASCADE;


--
-- Name: trade_updates trade_updates_symbol_canonical_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_symbol_canonical_fkey FOREIGN KEY (symbol_canonical) REFERENCES public.symbols(canonical);


--
-- Name: trade_updates trade_updates_target_intent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_target_intent_id_fkey FOREIGN KEY (target_intent_id) REFERENCES public.trade_intents(intent_id);


--
-- Name: trade_updates trade_updates_target_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tradebot
--

ALTER TABLE ONLY public.trade_updates
    ADD CONSTRAINT trade_updates_target_plan_id_fkey FOREIGN KEY (target_plan_id) REFERENCES public.trade_plans(plan_id);


--
-- PostgreSQL database dump complete
--

\unrestrict fwTcOWRQVu1wUcM74uiogOdkf2HBlsgdpyx4WqWYktSorGVuaCeTChxJdv51KyX

