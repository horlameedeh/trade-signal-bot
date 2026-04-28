--
-- PostgreSQL database dump
--

\restrict FzxLCeGNmGEGVVAdCHRa3pZE8UIaU42ttaXn210nzQjtTChkKhayElvJsmLYYn0

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
-- Data for Name: account_risk_state; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.account_risk_state (snapshot_id, account_id, as_of, balance, equity, floating_pl, daily_pl, daily_dd, total_dd, source, meta, created_at) FROM stdin;
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.alembic_version (version_num) FROM stdin;
3051ce82147d
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.app_settings (key, value, updated_at) FROM stdin;
control_chat_id	-5211338635	2026-02-21 20:20:43.890081+00
\.


--
-- Data for Name: approvals; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.approvals (approval_id, plan_id, control_chat_id, control_message_id, requested_by_user_id, decision_by_telegram_user_id, decision, decided_at, snooze_until, notes, created_at) FROM stdin;
c698b76b-076e-419b-ab5c-83e821bdcca8	035b82f2-cc26-425a-a09e-a0b6c102de4f	-5211338635	369	\N	7622982526	approve	2026-04-03 20:12:35.156825+00	\N	🟡 Approval Required\n\nProvider: mubeen\nCategory: HIGH_RISK\nSymbol: XAUUSD\nSide: BUY\nEntry: 4603\nSL: 4597\nTPs: 4606, 4610, 4613, 4626\nRisk: high\nReason: mubeen_high_risk_requires_approval\nFingerprint: c4356c89c79a03ec424154fb4b0e022d288233906b3567a14169333061155c0f	2026-04-03 20:12:24.251697+00
6f8c5713-9d9e-407d-b55c-5887b1a0d0bc	8c8d99e5-a236-41b3-b84e-324e13e3d226	\N	\N	\N	\N	\N	\N	\N	🟡 Approval Required\n\nProvider: mubeen\nCategory: HIGH_RISK\nSymbol: XAUUSD\nSide: BUY\nEntry: 4603\nSL: 4597\nTPs: 4606\nRisk: high\nReason: mubeen_high_risk_requires_approval\nFingerprint: e22cad4f83eec8e49b7c3bb931bbad51b8b3c0671f21f07d46e1715d607daadd	2026-04-03 20:20:09.447733+00
93c31ca2-2c34-41d1-9922-18a3ee744f52	7666787c-02fb-4424-9cdd-9148cb4fe64e	\N	\N	\N	\N	\N	\N	\N	🟡 Approval Required\n\nProvider: mubeen\nCategory: HIGH_RISK\nSymbol: XAUUSD\nSide: BUY\nEntry: 4603\nSL: 4597\nTPs: 4606\nRisk: high\nReason: mubeen_high_risk_requires_approval\nFingerprint: b21cbfedc9c872f1703a0fabeec02bb55e6980998fc1d378322d6e2477d3be3a	2026-04-03 20:20:09.454022+00
\.


--
-- Data for Name: broker_accounts; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.broker_accounts (account_id, user_id, broker, platform, kind, label, prop_firm, prop_phase, base_currency, equity_start, is_active, allowed_providers, created_at, updated_at) FROM stdin;
21ef5d9a-3798-4990-9839-32e1e8dd37ba	\N	ftmo	mt5	prop_funded	FTMO - Execution	ftmo	funded	USD	\N	t	{fredtrading}	2026-02-21 20:56:19.026241+00	2026-02-21 20:56:19.026241+00
d072812f-88e8-4870-8f5c-3dd0d3772164	\N	traderscale	mt5	prop_funded	Traderscale - Execution	traderscale	funded	USD	\N	t	{billionaire_club}	2026-02-21 20:56:19.026241+00	2026-02-21 20:56:19.026241+00
7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7	\N	fundednext	mt5	prop_funded	FundedNext - Execution	fundednext	funded	USD	\N	t	{mubeen}	2026-02-21 20:56:19.026241+00	2026-02-21 20:56:19.026241+00
ef3bd7d6-22da-45cf-b583-969d1221cf16	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 21:58:57.242996+00	2026-02-23 21:58:57.242996+00
4599014d-6053-4eee-813c-5846e6385938	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 21:58:57.242996+00	2026-02-23 21:58:57.242996+00
3ebd7ba0-cdb6-480b-bb6d-5d0d10ed7ca8	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 21:58:57.258107+00	2026-02-23 21:58:57.258107+00
f9267f49-f39a-4246-9edb-2641f9e0a3f6	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:19.64201+00	2026-02-23 22:00:19.64201+00
1d122ac1-97fc-4b79-a1a8-bbe8ac80d7de	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:19.64201+00	2026-02-23 22:00:19.64201+00
dc676f05-2ea2-46a1-83e6-cd94264de918	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:00:19.656192+00	2026-02-23 22:00:19.656192+00
d914974e-753e-4418-b5d9-8ec71ac7354d	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:02:16.219745+00	2026-02-23 22:02:16.219745+00
90b89d6f-39f8-45a5-96bd-c095c935da44	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:02:16.219745+00	2026-02-23 22:02:16.219745+00
9037fb24-f837-4585-9c80-8f3cb39ea02b	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:02:16.263706+00	2026-02-23 22:02:16.263706+00
a7de8947-1b38-40bc-bc9a-1ac068b29342	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:02:16.274448+00	2026-02-23 22:02:16.274448+00
9c346e8c-8cec-4204-8a50-4a8cfb465e1b	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:03:53.143385+00	2026-02-23 22:03:53.143385+00
c149afb9-bcf8-4d4d-8709-62d1e288e9d2	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:03:53.143385+00	2026-02-23 22:03:53.143385+00
3f677a60-eeac-45f4-8682-eb194af483b0	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:03:53.158897+00	2026-02-23 22:03:53.158897+00
ebdefb0c-b209-4fe6-9cc2-59cd76f85ed4	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:53.166347+00	2026-02-23 22:03:53.166347+00
1e11640f-3c6c-45f2-9654-0722b8d5c7f3	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:53.18185+00	2026-02-23 22:03:53.18185+00
2591181b-cf8c-45d6-a54a-239a107cf80c	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:53.196917+00	2026-02-23 22:03:53.196917+00
3cdae7ee-098f-4184-83a0-24e2e9e1a3b0	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:23.88498+00	2026-02-23 22:19:23.88498+00
3bf57164-1b10-468d-a996-9a200c45fdb2	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:23.88498+00	2026-02-23 22:19:23.88498+00
0c165ea1-7bed-4861-a98e-84fad61934cf	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:19:23.898665+00	2026-02-23 22:19:23.898665+00
b4d8dfe9-0a1c-4982-9381-da404895b43c	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:23.929316+00	2026-02-23 22:19:23.929316+00
6603ac98-b0b2-4320-8b07-b8135b97b133	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:23.929316+00	2026-02-23 22:19:23.929316+00
1c8a4264-3998-477e-afc6-8f3110db39d6	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:39.773811+00	2026-02-23 22:19:39.773811+00
c347530f-9157-44c9-a612-8dd5cd1aedd2	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:39.773811+00	2026-02-23 22:19:39.773811+00
94b23653-e8ac-49a4-94d6-a7a66ece48b3	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:19:39.78576+00	2026-02-23 22:19:39.78576+00
7edb2386-8d41-4441-9e7c-f9762868d020	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:39.803421+00	2026-02-23 22:19:39.803421+00
244d6305-f83f-456d-aa5f-7bfdb17e516f	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:39.803421+00	2026-02-23 22:19:39.803421+00
af59db7a-360d-4501-89e0-2fde151df8a5	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:19:39.816454+00	2026-02-23 22:19:39.816454+00
031f7c17-799d-4359-996d-7a76108c8240	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:19:39.832159+00	2026-02-23 22:19:39.832159+00
5b1f0c8f-2538-4ad7-9189-d9f9813ea968	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:19:39.847377+00	2026-02-23 22:19:39.847377+00
6014c133-ff44-4041-9f65-976e774ae933	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:23:59.823671+00	2026-03-24 15:23:59.823671+00
6d002a8a-4c1b-4b21-8e1f-4d37775d20ea	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:23:59.823671+00	2026-03-24 15:23:59.823671+00
57b5bc4c-ed2a-43be-a7df-7d2351415ab0	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:23:59.841009+00	2026-03-24 15:23:59.841009+00
75d45fc3-8942-44b1-852c-e4fe3eb216b4	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:23:59.866877+00	2026-03-24 15:23:59.866877+00
aaffea7c-4f7a-4efb-92bf-610061f41aeb	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:23:59.866877+00	2026-03-24 15:23:59.866877+00
62ac7883-ff68-4241-9753-cb0cbbb1657b	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:23:59.87361+00	2026-03-24 15:23:59.87361+00
61661b02-e4cd-4cd2-bb28-d359687960a2	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:23:59.884749+00	2026-03-24 15:23:59.884749+00
ab0cfdea-463a-41c7-bb48-954b3979cc85	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:23:59.896349+00	2026-03-24 15:23:59.896349+00
767fdf5a-fcec-4ee0-a8da-eaf8a748d297	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:24:18.230844+00	2026-03-24 15:24:18.230844+00
46fccc78-bcc5-49b4-8314-9bbf952b40f4	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:24:18.239472+00	2026-03-24 15:24:18.239472+00
1827c87e-9755-4cb1-a6ee-12fe0586d604	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:25:04.123941+00	2026-03-24 15:25:04.123941+00
d03acc11-0e6f-42db-bfc0-666910db1241	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:25:04.123941+00	2026-03-24 15:25:04.123941+00
42c23288-8713-473a-b1e7-ff46905a9806	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:25:04.135726+00	2026-03-24 15:25:04.135726+00
79a50bbb-01be-4b69-aa68-28d167c71d2f	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:25:04.159677+00	2026-03-24 15:25:04.159677+00
ce293930-809d-4924-a42b-e6d41e59bfa6	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:25:04.159677+00	2026-03-24 15:25:04.159677+00
76d09504-5bda-4c82-af1f-14cbf93142fa	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:04.166279+00	2026-03-24 15:25:04.166279+00
722c2128-fd74-4f9d-886a-14bd27e5820a	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:04.175058+00	2026-03-24 15:25:04.175058+00
f0f44996-9214-446a-ae82-47f8f77cfd17	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:04.183403+00	2026-03-24 15:25:04.183403+00
0bf2975d-3c7f-4573-b6f2-97d4d6ae3f4a	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 20:59:50.320266+00	2026-02-23 20:59:50.320266+00
61348aed-bacd-4f09-aa79-a7b2ef8a1c68	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:57:06.908968+00	2026-02-23 19:57:06.908968+00
9a992ea5-364a-4ea2-ae58-c8532fcc7d7f	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:57:06.944262+00	2026-02-23 19:57:06.944262+00
2a462fc6-6b04-49d5-90d1-9721345eb999	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:13.582694+00	2026-02-23 19:58:13.582694+00
6661ce90-6c89-45a3-93b2-0243a6feb958	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:13.657604+00	2026-02-23 19:58:13.657604+00
0ccb9e5b-691a-4d2d-8ea1-281c42016f85	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:13.692304+00	2026-02-23 19:58:13.692304+00
208333e7-2f78-47db-a285-250deb1b66f9	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:25:34.11771+00	2026-03-24 15:25:34.11771+00
8c3b5f6f-2bbf-46ae-b5f5-445b5a8c77e6	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:25:34.11771+00	2026-03-24 15:25:34.11771+00
5316578a-44e2-40ee-9a3e-b7c7a2cf7de6	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:25:34.12924+00	2026-03-24 15:25:34.12924+00
67af3231-48cf-4afb-b153-4b7e6bdbb7e3	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:25:34.153266+00	2026-03-24 15:25:34.153266+00
025afd62-a8b1-457b-a49f-36619b6051a2	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:51.829572+00	2026-02-23 19:58:51.829572+00
4fdc4c79-b470-4ae3-bbbb-6bbf792baa58	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:51.844039+00	2026-02-23 19:58:51.844039+00
7c168232-3c64-455d-b3c6-2e1edc53e939	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:58:51.854354+00	2026-02-23 19:58:51.854354+00
9887a4cd-760f-4288-910a-3c0695fcfe0d	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:59:21.839749+00	2026-02-23 19:59:21.839749+00
01693744-d158-4907-b3e8-09c9e8b1bd3a	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:59:21.855316+00	2026-02-23 19:59:21.855316+00
f2ba9eec-6e2b-47ac-a513-182995f3435f	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 19:59:21.86619+00	2026-02-23 19:59:21.86619+00
d23bf106-b4be-457a-b0b6-74cc4311c793	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:02:47.574228+00	2026-02-23 20:02:47.574228+00
f2ebc53b-8c1a-4577-a674-824efbf86b00	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:02:47.591875+00	2026-02-23 20:02:47.591875+00
8743d11d-de7a-46ce-9574-91dbc0b4e5f2	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:02:47.603828+00	2026-02-23 20:02:47.603828+00
eb477b04-ba0e-4c1f-a9e5-632fb1aadc76	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:03:36.373843+00	2026-02-23 20:03:36.373843+00
43760b71-f654-484e-96e6-32cc9aa31bed	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:03:36.388857+00	2026-02-23 20:03:36.388857+00
9a08fb03-513e-42a3-a80a-61e87abb9d83	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:03:36.399691+00	2026-02-23 20:03:36.399691+00
204c8adb-1780-42e0-8d33-a60832cf23dc	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:04:06.007774+00	2026-02-23 20:04:06.007774+00
ab270d91-9b58-419b-8b50-b278b7fbd2fd	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:04:06.026518+00	2026-02-23 20:04:06.026518+00
cf9b4386-f15b-4d0b-8dee-a00022cf7e34	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:04:06.040117+00	2026-02-23 20:04:06.040117+00
a81d7582-8c41-44db-b9ff-e149fa975b96	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:49.750866+00	2026-02-23 20:05:49.750866+00
eab94a48-d86d-4b71-8cb8-514c5c3cda0c	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:49.767795+00	2026-02-23 20:05:49.767795+00
e4386063-b3c5-49d4-a62c-532eb9a483ab	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:49.780564+00	2026-02-23 20:05:49.780564+00
081d0703-8166-4034-a03b-4f12c389eb42	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:50.883097+00	2026-02-23 20:05:50.883097+00
36cf55ba-b378-4391-9a13-ae561e301985	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:50.903211+00	2026-02-23 20:05:50.903211+00
4c78e55b-b89c-48b3-975a-b8fba7370e10	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:05:50.915237+00	2026-02-23 20:05:50.915237+00
0c98379b-55ba-4630-8435-2ef82c965033	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:10:25.101626+00	2026-02-23 20:10:25.101626+00
549def7f-22a6-454e-a44a-c3d8c8c3b15f	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:10:25.117489+00	2026-02-23 20:10:25.117489+00
fc4c9169-8dc5-41b9-a239-65374c025d9f	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:10:25.13113+00	2026-02-23 20:10:25.13113+00
0dc785ac-03e4-4d43-823d-2baf7943b816	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:19:46.596062+00	2026-02-23 20:19:46.596062+00
50639768-c49b-47bd-a0a9-4c09cb3cf5be	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:19:46.611424+00	2026-02-23 20:19:46.611424+00
84ae6451-c235-4f91-a058-7d9d6a72ff13	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:19:46.625428+00	2026-02-23 20:19:46.625428+00
2cd74608-1305-46d2-b6d4-bc3dded79f9d	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:45:46.747304+00	2026-02-23 20:45:46.747304+00
0d1b6295-71e1-4478-b6a2-330b3ae7d9a8	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:45:46.762381+00	2026-02-23 20:45:46.762381+00
2d25b5e4-d585-4551-b320-d2a1363feb35	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:45:46.775068+00	2026-02-23 20:45:46.775068+00
6fb96082-a6b2-47fa-af56-62d807740a28	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:56:48.893398+00	2026-02-23 20:56:48.893398+00
1cfc6a56-6b38-448d-a3ce-86935d20ef20	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:56:48.906766+00	2026-02-23 20:56:48.906766+00
eccb3356-c998-4e3a-9f93-383157a09edb	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:56:48.920541+00	2026-02-23 20:56:48.920541+00
fee93fab-f19c-4301-a18f-be6025d9dafe	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:59:50.291654+00	2026-02-23 20:59:50.291654+00
66928c28-2331-4e91-b2c4-1142886d5d51	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	f	{fredtrading}	2026-02-23 20:59:50.306646+00	2026-02-23 20:59:50.306646+00
694b1256-7b7f-4af5-b123-21f7aee87add	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:04.247031+00	2026-02-23 22:00:04.247031+00
fbef469b-8aa1-4c40-a128-4ca242b0d659	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:04.247031+00	2026-02-23 22:00:04.247031+00
3da1f70b-e2c5-4adf-8538-36a1b08a7c1d	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:00:04.261461+00	2026-02-23 22:00:04.261461+00
d4d9c22a-3d13-424f-971d-7173402c6cfe	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:27.068704+00	2026-02-23 22:00:27.068704+00
3e91f7af-0cef-4618-a641-65b0d690a30c	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:00:27.068704+00	2026-02-23 22:00:27.068704+00
563ffbe2-e136-465a-8e63-67ef65eb7dc1	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:00:27.081187+00	2026-02-23 22:00:27.081187+00
13b8515c-51ce-4830-a242-dbb69e4c4829	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:03:02.821391+00	2026-02-23 22:03:02.821391+00
7f8d54ff-4cd5-420f-a7e8-bb91013af615	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:03:02.821391+00	2026-02-23 22:03:02.821391+00
fa651957-cab2-4265-a5f1-ab6e89047520	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:03:02.832598+00	2026-02-23 22:03:02.832598+00
3b2e62c9-44a1-4480-9e93-c0241b0f0910	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:02.840767+00	2026-02-23 22:03:02.840767+00
97b22529-ff06-4788-943c-789be1a53fd0	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:02.855348+00	2026-02-23 22:03:02.855348+00
6444cf0b-293f-4905-a8c6-e14e14485672	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-02-23 22:03:02.869797+00	2026-02-23 22:03:02.869797+00
6ee3b404-e54c-4ad2-bc12-8b9ece9e7d8f	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:18:19.235705+00	2026-02-23 22:18:19.235705+00
8e9d1ef2-8ad3-49e2-a5a8-03af7b8ecd8c	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:18:19.235705+00	2026-02-23 22:18:19.235705+00
b1e7e300-1f6d-4866-8f3d-4afcf833acf7	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:18:19.247548+00	2026-02-23 22:18:19.247548+00
4b48d579-1702-42d8-87cb-24f92959ad4a	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:18:21.120675+00	2026-02-23 22:18:21.120675+00
8f369304-f2e0-48c2-8afd-a47579704735	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:18:21.120675+00	2026-02-23 22:18:21.120675+00
ace5b008-2b73-478b-9ec0-dbecc7743912	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:31.240336+00	2026-02-23 22:19:31.240336+00
4c2fc7ae-3ce4-4482-b648-08bcf8e691df	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-02-23 22:19:31.240336+00	2026-02-23 22:19:31.240336+00
71b365c4-36f6-4247-a2b0-6feb0baa934e	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-02-23 22:19:31.260285+00	2026-02-23 22:19:31.260285+00
b8717482-981e-432d-b35a-0a19b6d1bd52	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:31.280151+00	2026-02-23 22:19:31.280151+00
ec680271-c9b3-4efc-9cb0-a80521892cb7	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-02-23 22:19:31.280151+00	2026-02-23 22:19:31.280151+00
4a5bd11d-6ff7-4713-9b37-abf1ee22ad02	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:24:18.18976+00	2026-03-24 15:24:18.18976+00
e55bb795-6c69-43b4-a35e-33aafdc7d787	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:24:18.18976+00	2026-03-24 15:24:18.18976+00
65cb65a3-61d9-4d45-a3bb-568d616cd648	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:24:18.202551+00	2026-03-24 15:24:18.202551+00
cc2477fc-447f-4e9d-9ccd-2be059ae13c4	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:24:18.21514+00	2026-03-24 15:24:18.21514+00
469fe66e-9101-4354-abc2-b6f067d2107c	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:24:18.21514+00	2026-03-24 15:24:18.21514+00
c3b38133-059a-4f7f-a6fa-568b11e3e61e	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:24:18.221475+00	2026-03-24 15:24:18.221475+00
c12f8cb6-4ff2-48b9-b77a-888acb062a2e	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:25:34.153266+00	2026-03-24 15:25:34.153266+00
d2aef4cf-ad7e-4d98-a66d-f27eee851716	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:34.160311+00	2026-03-24 15:25:34.160311+00
c0bb1266-fd27-4b8c-b57f-edd6bd745372	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:34.169514+00	2026-03-24 15:25:34.169514+00
057df014-c743-4e1e-9483-213602c2b1a3	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:25:34.180223+00	2026-03-24 15:25:34.180223+00
b6a5c828-cf6e-4833-ab99-93efbcf40dd1	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:26:12.412614+00	2026-03-24 15:26:12.412614+00
ceed9318-6324-45cb-b507-2c85eaaa6e65	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:26:12.412614+00	2026-03-24 15:26:12.412614+00
3a52f2e2-9973-4633-af64-5c5e70cc675c	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:26:12.424341+00	2026-03-24 15:26:12.424341+00
7d4416ff-efe6-4793-9c71-98dfd80209e5	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:26:12.447294+00	2026-03-24 15:26:12.447294+00
35dcf60a-53bf-4a93-bd87-909af59306e4	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:26:12.447294+00	2026-03-24 15:26:12.447294+00
3af5a463-d0ab-4a53-bac1-2075ab43e75a	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:12.453736+00	2026-03-24 15:26:12.453736+00
868bfe6d-a6ab-4486-a00d-584239473c23	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:12.462268+00	2026-03-24 15:26:12.462268+00
4b535fb2-9d80-4970-9bbb-3f005d77b4d2	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:12.470589+00	2026-03-24 15:26:12.470589+00
3ddf36ca-94ba-4f06-9bf4-e9118c4f6f7a	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:26:57.728902+00	2026-03-24 15:26:57.728902+00
9b370c0c-8066-4062-8239-3e30b53e82d7	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:26:57.728902+00	2026-03-24 15:26:57.728902+00
1404a98d-0a0f-4b5f-b179-2c47e30f00f3	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:26:57.740972+00	2026-03-24 15:26:57.740972+00
73fee00d-9df9-479f-a774-d5c6d2439a2b	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:26:57.766514+00	2026-03-24 15:26:57.766514+00
4221ce48-1d94-46a5-91ca-560b62dede65	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:26:57.766514+00	2026-03-24 15:26:57.766514+00
ed1a5018-cef4-409b-abbc-20fe3fa0ab88	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:57.773567+00	2026-03-24 15:26:57.773567+00
39def072-f835-407d-8cb9-47ce205b1498	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:57.783251+00	2026-03-24 15:26:57.783251+00
c9ad4ebd-c9a8-4fe3-9e58-d654d0bb04b8	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:26:57.792026+00	2026-03-24 15:26:57.792026+00
fa23e53a-a50c-42ee-aca9-50faa37b53db	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:27:21.44318+00	2026-03-24 15:27:21.44318+00
dc6eabac-d2c1-4be5-8cf3-607ca8569d25	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:27:21.44318+00	2026-03-24 15:27:21.44318+00
1e7093ac-641c-4236-8c17-5d2f9b97d131	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:27:21.455285+00	2026-03-24 15:27:21.455285+00
bc99a4a9-e254-4f7d-9345-d07f12eb27ff	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:27:21.466944+00	2026-03-24 15:27:21.466944+00
bf0f28cc-194e-42b0-b5ab-c5dcf5becd4e	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:27:21.466944+00	2026-03-24 15:27:21.466944+00
8ccbf8e6-f8c4-4ffa-aa71-c2b0020b4110	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:27:21.47325+00	2026-03-24 15:27:21.47325+00
77dc6c00-81c3-4f88-a6eb-7e089379e90b	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:27:21.483589+00	2026-03-24 15:27:21.483589+00
a38b8b83-1cd1-4740-a666-14b69baf7095	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:27:21.492122+00	2026-03-24 15:27:21.492122+00
d3ad0b4f-7ecb-4a84-91f4-e80fdbc8a597	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:28:12.585012+00	2026-03-24 15:28:12.585012+00
518f4c87-8462-4155-92de-ee0c78aa33d5	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:28:12.585012+00	2026-03-24 15:28:12.585012+00
81626efa-82b0-432d-8404-d6294be757b4	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:28:12.592388+00	2026-03-24 15:28:12.592388+00
3f9f8c09-cde0-4f8e-af32-c0d862e56325	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:28:12.615057+00	2026-03-24 15:28:12.615057+00
833a1961-2e95-4b36-8dab-a784026632d6	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:28:12.615057+00	2026-03-24 15:28:12.615057+00
52f0787b-fc17-4f77-9f97-b1b8d0798d50	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:28:12.622173+00	2026-03-24 15:28:12.622173+00
ecb520d6-79df-4657-b806-b52a0f3361db	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:28:12.631525+00	2026-03-24 15:28:12.631525+00
9f79d8ba-1ee8-4e25-ad38-acf720dd555e	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:28:12.640177+00	2026-03-24 15:28:12.640177+00
2c620b0b-9821-48fb-9b27-f952c84ab46a	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:29:15.675414+00	2026-03-24 15:29:15.675414+00
31ef946a-eb3f-4cfc-8fc9-2494923cd7a8	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 15:29:15.675414+00	2026-03-24 15:29:15.675414+00
ca5a6cf7-b80e-456d-8811-98278bf5a861	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 15:29:15.683005+00	2026-03-24 15:29:15.683005+00
adb17f21-4384-497b-b3db-877f5fa1cae0	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:29:15.707234+00	2026-03-24 15:29:15.707234+00
277cba10-9e94-4d95-8b11-588fa3cf2083	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 15:29:15.707234+00	2026-03-24 15:29:15.707234+00
6f3d6c8f-b795-4a61-aa32-0ddc3682d8d7	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:29:15.714355+00	2026-03-24 15:29:15.714355+00
90575ff5-ba36-4765-b17c-22cd57ca1d1c	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:29:15.723684+00	2026-03-24 15:29:15.723684+00
088a6d01-3d06-479f-b27f-ca395f4393c8	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 15:29:15.732283+00	2026-03-24 15:29:15.732283+00
ac9529ea-ef01-4169-ad17-0cc88a2867c3	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:05.976565+00	2026-03-24 16:06:05.976565+00
c1609da7-a45c-4137-84c7-72a1a3b74784	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:05.989222+00	2026-03-24 16:06:05.989222+00
5eb0956c-6479-4916-aae3-c0fbb47f3387	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:06.000481+00	2026-03-24 16:06:06.000481+00
dac10980-e70d-4382-ab78-44340188ad29	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:06:16.610713+00	2026-03-24 16:06:16.610713+00
b7693b7a-2dda-4ff4-881c-a6de8f72f67f	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:06:16.610713+00	2026-03-24 16:06:16.610713+00
c3851abb-50c0-40b2-a870-28cbc5ad1ba6	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:06:16.618092+00	2026-03-24 16:06:16.618092+00
f9ee7234-2eca-4e21-9ca9-7987cb0a5974	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:06:16.642641+00	2026-03-24 16:06:16.642641+00
410cb016-e098-4243-b641-3fb6e8d4198a	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:06:16.642641+00	2026-03-24 16:06:16.642641+00
ccd6d937-223d-4181-bdba-8a927c0213f0	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:16.649428+00	2026-03-24 16:06:16.649428+00
b00b2348-0c3f-46e6-a837-000954f4adc7	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:16.659784+00	2026-03-24 16:06:16.659784+00
fa32dae1-1864-4268-a568-f30df8a8cc59	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:06:16.668825+00	2026-03-24 16:06:16.668825+00
8dfa4bef-4c5d-453c-9e12-4a14d9ab2eb0	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:26:08.70971+00	2026-03-24 16:26:08.70971+00
f9f84603-5a70-4e46-bbde-3ef204f0f5ea	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:26:08.70971+00	2026-03-24 16:26:08.70971+00
e00fee57-b3f1-445b-9632-954e9eebe105	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:26:08.717382+00	2026-03-24 16:26:08.717382+00
7cf7abde-9e1e-4577-a9db-4d09f090dd4f	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:26:08.743871+00	2026-03-24 16:26:08.743871+00
26be5f31-ae83-437d-89f2-ec86ca4284e2	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:26:08.743871+00	2026-03-24 16:26:08.743871+00
cec3388d-fa47-493c-9f3b-a204c2e6480b	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:26:08.750996+00	2026-03-24 16:26:08.750996+00
ed5306b1-d659-492f-960b-cd903b16b341	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:26:08.761077+00	2026-03-24 16:26:08.761077+00
ce3d5d26-e900-4494-a462-4e5658a73d77	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:26:08.770382+00	2026-03-24 16:26:08.770382+00
effaaddd-2d0c-4ff2-b774-87f0bfe9a48c	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:29:46.778625+00	2026-03-24 16:29:46.778625+00
e26d316f-6f84-4c39-92aa-9e0511d9ef5a	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:29:46.778625+00	2026-03-24 16:29:46.778625+00
089eee55-ef36-4ada-a52e-7034627aecdd	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:29:46.792986+00	2026-03-24 16:29:46.792986+00
96d2e6cd-fdfb-4e1f-862f-20ae298658c3	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:29:46.819825+00	2026-03-24 16:29:46.819825+00
90964f23-c7b2-48c9-bc8a-6a9e071bd55d	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:29:46.819825+00	2026-03-24 16:29:46.819825+00
c8e7506a-4e80-49e4-87e6-4d5e90c5ed93	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:29:46.827702+00	2026-03-24 16:29:46.827702+00
770cdb91-23a8-4a01-aa0f-5731af367fd0	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:29:46.838584+00	2026-03-24 16:29:46.838584+00
53a484d9-0bd1-47be-9193-fdfdf1048286	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:29:46.848506+00	2026-03-24 16:29:46.848506+00
2ada7612-e2f7-4dcd-8c12-b4ac69c1fa35	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:30:09.46934+00	2026-03-24 16:30:09.46934+00
8db973bd-85e5-4d17-8cc4-19321e53fad5	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:30:09.46934+00	2026-03-24 16:30:09.46934+00
cabbd7c4-9801-4c5c-8297-0231ad71737f	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:30:09.48609+00	2026-03-24 16:30:09.48609+00
6f378963-0413-4f3e-afbc-c69b90753a38	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:30:09.514786+00	2026-03-24 16:30:09.514786+00
f6b15e29-2d37-40bf-83a5-731567cc0f97	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:30:09.514786+00	2026-03-24 16:30:09.514786+00
1f58b1ba-66af-4054-9605-c4cc7d1149d4	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:09.523696+00	2026-03-24 16:30:09.523696+00
8ba7fd9d-8982-42ba-83d2-d516a4894d29	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:09.536394+00	2026-03-24 16:30:09.536394+00
56606f9f-a668-4b9b-ab5d-f5035d248946	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:09.547732+00	2026-03-24 16:30:09.547732+00
a8efc261-0895-4495-a332-db5061ecfc61	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:30:44.580802+00	2026-03-24 16:30:44.580802+00
9828f38d-0515-45e5-8cc5-5519a3f4f2e3	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:30:44.580802+00	2026-03-24 16:30:44.580802+00
3ec1755f-cc9e-47a8-b7dc-7619369eb4d7	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:30:44.590698+00	2026-03-24 16:30:44.590698+00
4ab6356e-f696-455f-bec3-44e344aad9a3	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:30:44.616692+00	2026-03-24 16:30:44.616692+00
de6bfc4f-4f61-4583-843e-831cb06c510c	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:30:44.616692+00	2026-03-24 16:30:44.616692+00
65d34501-53b5-4782-8fd8-691d7857a0e9	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:44.624327+00	2026-03-24 16:30:44.624327+00
08ee3072-13ca-4d3c-b510-466dd73faedf	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:44.635972+00	2026-03-24 16:30:44.635972+00
1749ab8a-1dc9-4d48-b381-c52f462cc2c7	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:30:44.6457+00	2026-03-24 16:30:44.6457+00
855e07f7-ebfd-4837-889b-02583c33e076	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:34:35.958339+00	2026-03-24 16:34:35.958339+00
6a17193f-2cb2-4201-b293-604889d66481	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:34:36.088486+00	2026-03-24 16:34:36.088486+00
9b79ab6e-8edc-46a4-9718-ad5108dade57	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:34:36.205366+00	2026-03-24 16:34:36.205366+00
3f5d1202-5456-4070-8820-3ff1bd078f52	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:06.375007+00	2026-03-24 16:35:06.375007+00
69be31b6-a299-4a2b-b5e2-ef7cb6a6b27a	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:06.388416+00	2026-03-24 16:35:06.388416+00
c0dd92bd-a797-4ff7-bd0d-33b80564e25e	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:35:06.397616+00	2026-03-24 16:35:06.397616+00
f97878ce-5e11-4d1f-b075-84d1b320c98e	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.02069+00	2026-03-24 16:35:16.02069+00
646c3434-7f9e-497a-bad6-06f7d24e2593	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.032146+00	2026-03-24 16:35:16.032146+00
16ce43af-59a4-4e26-9190-9daf02fa8016	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.041907+00	2026-03-24 16:35:16.041907+00
7c4002aa-1887-45f2-83f2-95108699a5c1	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.064537+00	2026-03-24 16:35:16.064537+00
9deba179-76a1-4093-b814-341e220d2a35	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.064537+00	2026-03-24 16:35:16.064537+00
fd1b33f8-5da7-4cff-b5c7-50431e1d174e	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.073616+00	2026-03-24 16:35:16.073616+00
54672ede-056b-452f-8fbd-571603bcb8d3	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.101014+00	2026-03-24 16:35:16.101014+00
0ff641ed-c835-4fe0-a2f9-23b2ccb382d8	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 16:35:16.101014+00	2026-03-24 16:35:16.101014+00
3792b8ca-fe7b-4619-901b-ff0d0f2f07e1	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:35:16.108785+00	2026-03-24 16:35:16.108785+00
496d5648-16da-4e15-adc6-cf9a606f360a	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:35:16.118814+00	2026-03-24 16:35:16.118814+00
482c4614-2fb8-4861-b664-6bb4019ce4fc	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 16:35:16.128951+00	2026-03-24 16:35:16.128951+00
5d892f7c-6890-40f9-8aef-2a96ca1b3f91	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:31.883996+00	2026-03-24 16:35:31.883996+00
774e6e4e-2384-4260-927e-206ecec4dc69	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 16:35:31.892183+00	2026-03-24 16:35:31.892183+00
40bfb475-7d76-43c0-9c2c-4cc4d38364ad	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 16:35:31.901453+00	2026-03-24 16:35:31.901453+00
e1dcb7f7-d346-4858-8b4b-1a336a5e6289	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:20:39.609162+00	2026-03-24 17:20:39.609162+00
5ec9126d-9d61-4746-9025-74ac3a0cd568	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:20:39.619451+00	2026-03-24 17:20:39.619451+00
ed77ca9d-bdf6-47af-b849-f6590fdd3d72	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:20:39.628334+00	2026-03-24 17:20:39.628334+00
20064908-c6ff-4b51-b796-33b3eebee142	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:22:51.050231+00	2026-03-24 17:22:51.050231+00
fb486da7-4d96-4650-b684-e7c9d9ddd7b9	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:22:51.060511+00	2026-03-24 17:22:51.060511+00
85aa3cda-87e8-4b38-a6f4-ccb535d3dd8d	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:22:51.070083+00	2026-03-24 17:22:51.070083+00
7243e524-9646-44d1-b989-20e60a6704bd	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:23:07.765403+00	2026-03-24 17:23:07.765403+00
1146a8bc-f66e-42cc-87f6-0b1fd9a6980f	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:23:07.774866+00	2026-03-24 17:23:07.774866+00
5ac183f3-9f1b-4bff-80e3-4d1b35250fbe	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:23:07.785739+00	2026-03-24 17:23:07.785739+00
c6299cc3-c810-4cae-90ab-1c0b150c62d1	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:23:47.304062+00	2026-03-24 17:23:47.304062+00
29474a21-092d-476a-a3cf-630ba7ade510	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:23:47.315582+00	2026-03-24 17:23:47.315582+00
b47865c6-8610-4f1d-a9d1-b28d44709dc0	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:23:47.326646+00	2026-03-24 17:23:47.326646+00
9f47d584-40da-4a4b-a289-a7926013327d	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:25:54.29162+00	2026-03-24 17:25:54.29162+00
1a21878c-7216-449d-b930-d89738854d28	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:25:54.309719+00	2026-03-24 17:25:54.309719+00
5fef657e-a2a4-49eb-8776-13bc3e6eabea	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:25:54.322234+00	2026-03-24 17:25:54.322234+00
c528dc81-55a8-45ca-ac72-6115219be07d	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.08202+00	2026-03-24 17:57:29.08202+00
f8573107-8e01-4b71-911e-3acf37d1fc0f	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.091582+00	2026-03-24 17:57:29.091582+00
8a2bded4-04fe-40d2-a652-3a21a7386d83	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.100715+00	2026-03-24 17:57:29.100715+00
037c3556-8796-48d0-92d2-5b262a279370	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.120637+00	2026-03-24 17:57:29.120637+00
b7f68e49-aa4c-4ec2-a9c1-5a3c7a47e449	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.120637+00	2026-03-24 17:57:29.120637+00
d9b749f2-7201-4b8b-81a6-9cd7cc7485fb	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.12802+00	2026-03-24 17:57:29.12802+00
3024de89-bf85-4a5d-a675-b98eb7356cb9	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.161363+00	2026-03-24 17:57:29.161363+00
747fa3b9-05d5-4a82-a568-09fe3cfa1b2e	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:57:29.161363+00	2026-03-24 17:57:29.161363+00
7b9797d7-d844-4da6-9e93-645fc1ca134f	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:29.168571+00	2026-03-24 17:57:29.168571+00
71c4d0ce-7e85-4a55-a4f4-20d0cf7f00dc	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:29.177762+00	2026-03-24 17:57:29.177762+00
80f9b07d-34cf-44a2-bb6f-239e8a2e502b	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:29.18682+00	2026-03-24 17:57:29.18682+00
4d90ea74-d813-4b0f-9ad2-7ac10e4c59b2	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.26768+00	2026-03-24 17:57:43.26768+00
e76dd04a-b82b-40a7-adfb-962cea6cba15	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.275366+00	2026-03-24 17:57:43.275366+00
ef314185-421b-467e-bd47-330c5f9df910	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.284019+00	2026-03-24 17:57:43.284019+00
ab42cd3c-9195-485b-8171-fc3fde5b4d59	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.304512+00	2026-03-24 17:57:43.304512+00
d48144aa-b6c7-4663-aeb2-cd4f493a2ff9	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.304512+00	2026-03-24 17:57:43.304512+00
f5f80e2f-ad14-4d49-9e06-6bf877049924	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.313006+00	2026-03-24 17:57:43.313006+00
830679d2-835e-446d-a666-481102d33168	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.340024+00	2026-03-24 17:57:43.340024+00
64e73ec5-6263-44eb-999b-ec8e9f93ad64	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:57:43.340024+00	2026-03-24 17:57:43.340024+00
430a512a-2be2-4f32-8c49-254a2de04a9c	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:43.346702+00	2026-03-24 17:57:43.346702+00
23e51a78-2b52-4425-85aa-28665d43ee2c	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:43.355512+00	2026-03-24 17:57:43.355512+00
5798007c-3060-4575-90b8-65ec6390412b	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:57:43.364951+00	2026-03-24 17:57:43.364951+00
f4fce66a-71a0-4be4-a2e5-2d117022130f	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.755157+00	2026-03-24 17:58:36.755157+00
cbf82e7b-eaaa-4113-b3e8-032f701c6bf6	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.764988+00	2026-03-24 17:58:36.764988+00
a8703337-8880-4922-aad6-371e991adff1	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.774883+00	2026-03-24 17:58:36.774883+00
47f870e8-6789-4365-9eb7-5da3db26c6ed	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.797952+00	2026-03-24 17:58:36.797952+00
a9c8259b-f6e1-4886-95b1-1b9ad177f4b9	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.797952+00	2026-03-24 17:58:36.797952+00
4eef5584-91ec-4afb-884f-1097041dcfd4	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.806331+00	2026-03-24 17:58:36.806331+00
5844ced6-6be5-48cd-9fd6-ff390a89ff24	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.831693+00	2026-03-24 17:58:36.831693+00
bf90f59d-17f6-450a-b476-a7be8a7b39ef	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 17:58:36.831693+00	2026-03-24 17:58:36.831693+00
9f856726-5e9b-44d0-822e-323a7448ecd1	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:58:36.839952+00	2026-03-24 17:58:36.839952+00
5bb1722b-d6d1-482a-8f0d-3fca98385293	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:58:36.850939+00	2026-03-24 17:58:36.850939+00
75c9d5cf-960c-41dd-9c4e-0915cb029d54	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 17:58:36.862119+00	2026-03-24 17:58:36.862119+00
c4cdf78e-26cb-4cf5-ad45-9e8087cb0425	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.178567+00	2026-03-24 18:14:41.178567+00
da90b2b9-5b73-4359-be5d-1121e1f6798d	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.187246+00	2026-03-24 18:14:41.187246+00
00fb8167-d409-40fb-9173-13377faaea7e	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.19738+00	2026-03-24 18:14:41.19738+00
f5aae787-c36d-4138-a068-f584645ca751	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.229616+00	2026-03-24 18:14:41.229616+00
45528ef2-28b1-4899-95ba-37f0b8b71ddf	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.229616+00	2026-03-24 18:14:41.229616+00
0adb8542-6104-4c0e-8148-adb1f6fbf2cc	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.240774+00	2026-03-24 18:14:41.240774+00
7c8e80e7-305c-472a-8937-ae0864a28a68	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.266181+00	2026-03-24 18:14:41.266181+00
b65ac80f-5757-4257-a160-d49354b8616b	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:14:41.266181+00	2026-03-24 18:14:41.266181+00
920ca037-de0a-4c34-b053-7c97268de641	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:14:41.273479+00	2026-03-24 18:14:41.273479+00
b74076a7-6bf6-439f-868f-e3fb2a5d43ef	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:14:41.283489+00	2026-03-24 18:14:41.283489+00
199fe4c7-5182-48fd-917c-b22993e1d555	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:14:41.292783+00	2026-03-24 18:14:41.292783+00
bfcf3fbc-6177-4a22-ba5b-cbe379bbfdce	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.33878+00	2026-03-24 18:27:02.33878+00
c07b4c18-6540-4d2f-8e0d-9f3e19d545d2	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.346458+00	2026-03-24 18:27:02.346458+00
6777dc64-0de3-466b-aa28-ffdd07cd73c8	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.354845+00	2026-03-24 18:27:02.354845+00
f9bef580-8ed9-42fb-b58e-0c2d518be3d5	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.372686+00	2026-03-24 18:27:02.372686+00
78ad23c9-9176-45ca-a897-8bee993d4165	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.372686+00	2026-03-24 18:27:02.372686+00
9a2dc35e-959f-43a7-9c9c-b52c9a346a24	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.380007+00	2026-03-24 18:27:02.380007+00
e2162096-a591-43e4-8199-d3344dba97ea	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.405075+00	2026-03-24 18:27:02.405075+00
73e2ccef-3a9d-40df-9941-167965baef84	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:27:02.405075+00	2026-03-24 18:27:02.405075+00
45efcafe-e9f7-41cf-9331-3e95542ac003	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:27:02.412595+00	2026-03-24 18:27:02.412595+00
f91cbfb1-64be-4da0-ba41-c020e7afb031	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:27:02.421967+00	2026-03-24 18:27:02.421967+00
8708524d-c2f0-4ffe-81fa-88f89d5c84f1	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:27:02.430586+00	2026-03-24 18:27:02.430586+00
8f6155d5-2178-483f-af3c-4179ca61f2c9	\N	ftmo	mt5	personal_live	svc-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.786935+00	2026-03-24 18:48:43.786935+00
77a67de2-c3fb-479d-9d0c-67585c637233	\N	ftmo	mt5	personal_live	svc2-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.793261+00	2026-03-24 18:48:43.793261+00
2720f339-7175-4131-924d-7a6a85528739	\N	fundednext	mt5	personal_live	svc3-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.800483+00	2026-03-24 18:48:43.800483+00
0e81ab98-de5c-4cea-8ba6-12293c1626ff	\N	ftmo	mt5	personal_live	simA-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.817181+00	2026-03-24 18:48:43.817181+00
9ecd439b-f538-4c8c-ac50-311cc2f16590	\N	ftmo	mt5	personal_live	simB-ftmo	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.817181+00	2026-03-24 18:48:43.817181+00
09a52cfc-4d61-40d7-93af-ddc2974eb157	\N	fundednext	mt5	personal_live	sim-fundednext	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.824546+00	2026-03-24 18:48:43.824546+00
ccbcb512-0831-4eb3-83b9-977c7dbc05e8	\N	traderscale	mt5	personal_live	simA-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.850269+00	2026-03-24 18:48:43.850269+00
fee6de13-cb0c-4564-96fe-9eaebe6e70bd	\N	traderscale	mt5	personal_live	simB-traderscale	\N	\N	USD	\N	t	{}	2026-03-24 18:48:43.850269+00	2026-03-24 18:48:43.850269+00
9056b568-6c56-4888-8bd4-d253b2533a8e	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:48:43.858297+00	2026-03-24 18:48:43.858297+00
9d5a905c-f4ab-4ed6-a52e-6bedd6c05f5d	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:48:43.866512+00	2026-03-24 18:48:43.866512+00
fef40035-9de0-4692-b8fe-e676a491cdf5	\N	ftmo	mt5	personal_live	test-ftmo	\N	\N	USD	\N	t	{fredtrading}	2026-03-24 18:48:43.874271+00	2026-03-24 18:48:43.874271+00
545a7094-7611-4c6e-a8c2-cedf56f6513d	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:17:26.49059+00	2026-04-03 22:17:26.49059+00
feb955ba-8b12-4c3d-a0fb-af8b73b54696	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:17:42.087418+00	2026-04-03 22:17:42.087418+00
4392de58-270a-4bb2-97a9-a1a81b6ac544	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:17:42.216003+00	2026-04-03 22:17:42.216003+00
946f9428-0379-4888-94b6-9c4f8943509a	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:17:42.324965+00	2026-04-03 22:17:42.324965+00
39094c3e-21fd-4c81-a781-a27a25e7f185	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:17:42.432171+00	2026-04-03 22:17:42.432171+00
1c00bf39-29c9-4c3d-836d-3e2ef4bdb9b2	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:17:42.539643+00	2026-04-03 22:17:42.539643+00
9e16133d-7e8c-4378-9be9-c10eb28f068d	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:18:05.780998+00	2026-04-03 22:18:05.780998+00
e6c465a9-5fe4-48ca-ba9b-d3acdc92ffc1	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:05.907617+00	2026-04-03 22:18:05.907617+00
d477032c-d3d1-4557-ab87-04c201139ceb	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:06.019037+00	2026-04-03 22:18:06.019037+00
d01ab4d2-d515-4ccf-b72f-11a121ab8773	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:06.130525+00	2026-04-03 22:18:06.130525+00
c25e86f9-1862-450c-a255-e7bf2ef7eb11	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:06.240272+00	2026-04-03 22:18:06.240272+00
ef228b4f-1aac-46b3-84d4-ee5ca0a54da6	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:18:21.672404+00	2026-04-03 22:18:21.672404+00
daffc05c-6315-4b19-8819-652140b7cbe1	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:21.712283+00	2026-04-03 22:18:21.712283+00
7ccae282-2a32-4214-b81e-0469462064a8	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:21.723139+00	2026-04-03 22:18:21.723139+00
23bf57be-08ef-48f0-a55b-ee27f8832feb	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:21.731582+00	2026-04-03 22:18:21.731582+00
3124081e-3ba8-4ffb-9ab8-6e2df38aa102	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:21.738179+00	2026-04-03 22:18:21.738179+00
5cd409c1-539b-4090-9463-807acf89608d	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:18:34.123482+00	2026-04-03 22:18:34.123482+00
6666dd6e-a1b6-468b-8254-60d08a0343e8	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:34.138995+00	2026-04-03 22:18:34.138995+00
a232161d-b7eb-4352-b294-9a032e9f3dbd	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:34.146141+00	2026-04-03 22:18:34.146141+00
77931193-66f4-4059-9a45-8fd508202ad7	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:34.154188+00	2026-04-03 22:18:34.154188+00
4968e2f2-56bd-48b8-995f-5afae76c5e17	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:34.160373+00	2026-04-03 22:18:34.160373+00
4844ef78-0ecb-47e4-8804-63f1d0e0bf1f	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:18:52.136249+00	2026-04-03 22:18:52.136249+00
2dea5bda-b6b9-4140-bb17-b96491985e6c	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:52.149992+00	2026-04-03 22:18:52.149992+00
0e2087ea-a5a5-42b1-b25e-fbc5671bce67	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:52.158023+00	2026-04-03 22:18:52.158023+00
b0b638a8-0bc6-44cb-ada3-b828f3641e7d	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:18:52.165817+00	2026-04-03 22:18:52.165817+00
847d1eb6-b556-4aee-bbba-fe940171153c	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:18:52.17185+00	2026-04-03 22:18:52.17185+00
6a8ced54-c85e-4104-9b6d-9515240f5799	\N	ftmo	mt5	personal_live	seed-ftmo-10000	\N	\N	USD	10000.00	t	{}	2026-04-03 22:21:53.327781+00	2026-04-03 22:21:53.327781+00
4b23c3da-90e6-4113-b8f8-953d75f563d6	\N	ftmo	mt5	personal_live	seed-ftmo-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:21:53.343125+00	2026-04-03 22:21:53.343125+00
cad218aa-a82d-4d08-b01b-5c69448b6370	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:21:53.350739+00	2026-04-03 22:21:53.350739+00
d911eab5-c050-4fbc-84b0-2d5a4e6065d3	\N	ftmo	mt5	personal_live	seed-ftmo-100000	\N	\N	USD	100000.00	t	{}	2026-04-03 22:21:53.357547+00	2026-04-03 22:21:53.357547+00
fb88b82f-5e04-4fa3-8eaf-9c15cc1a8f65	\N	traderscale	mt5	personal_live	seed-traderscale-20000	\N	\N	USD	20000.00	t	{}	2026-04-03 22:21:53.363786+00	2026-04-03 22:21:53.363786+00
\.


--
-- Data for Name: broker_credentials; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.broker_credentials (cred_id, account_id, login, server, password_cipher, password_nonce, kek_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: control_actions; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.control_actions (id, created_at, telegram_user_id, control_chat_id, control_message_id, action, payload, status) FROM stdin;
\.


--
-- Data for Name: entry_jitter_policies; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.entry_jitter_policies (jitter_id, broker, platform, canonical, max_jitter, leg_step, apply_to, created_at) FROM stdin;
\.


--
-- Data for Name: execution_batches; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.execution_batches (batch_id, plan_id, account_id, executor_node, request_id, status, error_message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: execution_events; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.execution_events (event_id, batch_id, leg_id, status, terminal_order_id, terminal_position_id, fill_price, filled_lots, message, raw_json, created_at) FROM stdin;
\.


--
-- Data for Name: lot_sizing_profiles; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.lot_sizing_profiles (profile_id, provider, broker, account_size, lot_total, legs_hint, meta, created_at) FROM stdin;
3cc49e31-9b1c-4065-8746-0bbf889b114b	fredtrading	ftmo	10000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
4ae8cc19-3ce1-46e2-99ff-351e1bc41069	fredtrading	ftmo	20000	0.4000	\N	{}	2026-02-21 17:53:51.49747+00
23caf1c9-60da-43a5-9abb-7bf6876058ec	fredtrading	ftmo	35000	0.6000	\N	{}	2026-02-21 17:53:51.49747+00
f10f50b9-3077-4921-94a0-be6cd664a5da	fredtrading	ftmo	100000	1.2000	4	{}	2026-02-21 17:53:51.49747+00
4137d8d3-74aa-4ad8-8e13-215b9e8e1c40	fredtrading	ftmo	200000	1.6000	4	{}	2026-02-21 17:53:51.49747+00
ad894ca3-100d-4e7d-87fc-9fb1d3b32bd0	billionaire_club	traderscale	10000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
2c2b6589-4daa-4bd5-9af0-209fbd0a43c2	billionaire_club	traderscale	20000	0.4000	\N	{}	2026-02-21 17:53:51.49747+00
3b7d10de-507f-4808-a648-046516156445	billionaire_club	traderscale	35000	0.6000	\N	{}	2026-02-21 17:53:51.49747+00
c1367188-ffca-402d-b319-53550cd9269e	billionaire_club	traderscale	100000	1.2000	4	{}	2026-02-21 17:53:51.49747+00
34174e0d-44fc-4179-affd-00b86521789a	billionaire_club	traderscale	200000	1.6000	4	{}	2026-02-21 17:53:51.49747+00
3d957548-9c8b-4a92-bf60-efe85c41c25b	mubeen	fundednext	10000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
279932cd-0c92-4640-a521-1d03239e1989	mubeen	fundednext	20000	0.4000	\N	{}	2026-02-21 17:53:51.49747+00
5b3bf567-14ea-42c5-aae2-3518e3bcf0a1	mubeen	fundednext	35000	0.6000	\N	{}	2026-02-21 17:53:51.49747+00
a0dcd817-59d2-4a46-b182-e15102b58745	mubeen	fundednext	100000	1.2000	4	{}	2026-02-21 17:53:51.49747+00
2b163ec3-c7ce-41e5-91a9-a5cb2ac6e846	mubeen	fundednext	200000	1.6000	4	{}	2026-02-21 17:53:51.49747+00
be960e0e-38f7-4cc2-8b27-d9bc386a8607	fredtrading	vantage	1000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
0a1e4539-20ee-4479-9d84-244290fed2ae	fredtrading	startrader	1000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
7440026a-ba86-4a06-a0fd-234d55f40fcd	fredtrading	vtmarkets	1000	0.2000	\N	{}	2026-02-21 17:53:51.49747+00
\.


--
-- Data for Name: open_positions; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.open_positions (pos_id, account_id, broker_symbol, symbol_canonical, side, entry_price, sl_price, tp_price, lots, terminal_position_id, terminal_order_id, linked_leg_id, linked_plan_id, opened_at, updated_at, is_open, meta) FROM stdin;
\.


--
-- Data for Name: plan_risk_checks; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.plan_risk_checks (check_id, plan_id, ruleset_id, as_of_snapshot_id, est_sl_loss_ccy, est_sl_loss_pct, outcome, reasons, created_at) FROM stdin;
\.


--
-- Data for Name: prop_rulesets; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.prop_rulesets (ruleset_id, broker, phase, currency, max_daily_loss_pct, max_total_loss_pct, profit_target_pct, min_trading_days, meta, created_at) FROM stdin;
\.


--
-- Data for Name: provider_account_routes; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.provider_account_routes (id, provider_code, broker_account_id, is_active, created_at, updated_at) FROM stdin;
288	billionaire_club	7c8e80e7-305c-472a-8937-ae0864a28a68	f	2026-03-24 18:14:41.26763+00	2026-03-24 18:48:43.851676+00
299	billionaire_club	e2162096-a591-43e4-8199-d3344dba97ea	f	2026-03-24 18:27:02.406577+00	2026-03-24 18:48:43.851676+00
2	billionaire_club	d072812f-88e8-4870-8f5c-3dd0d3772164	f	2026-02-21 20:56:42.981599+00	2026-03-24 18:48:43.851676+00
85	billionaire_club	6603ac98-b0b2-4320-8b07-b8135b97b133	f	2026-02-23 22:19:23.934625+00	2026-03-24 18:48:43.851676+00
84	billionaire_club	b4d8dfe9-0a1c-4982-9381-da404895b43c	f	2026-02-23 22:19:23.931844+00	2026-03-24 18:48:43.851676+00
95	billionaire_club	244d6305-f83f-456d-aa5f-7bfdb17e516f	f	2026-02-23 22:19:39.810386+00	2026-03-24 18:48:43.851676+00
94	billionaire_club	7edb2386-8d41-4441-9e7c-f9762868d020	f	2026-02-23 22:19:39.806604+00	2026-03-24 18:48:43.851676+00
103	billionaire_club	aaffea7c-4f7a-4efb-92bf-610061f41aeb	f	2026-03-24 15:23:59.870021+00	2026-03-24 18:48:43.851676+00
102	billionaire_club	75d45fc3-8942-44b1-852c-e4fe3eb216b4	f	2026-03-24 15:23:59.868354+00	2026-03-24 18:48:43.851676+00
119	billionaire_club	ce293930-809d-4924-a42b-e6d41e59bfa6	f	2026-03-24 15:25:04.162694+00	2026-03-24 18:48:43.851676+00
118	billionaire_club	79a50bbb-01be-4b69-aa68-28d167c71d2f	f	2026-03-24 15:25:04.161038+00	2026-03-24 18:48:43.851676+00
167	billionaire_club	277cba10-9e94-4d95-8b11-588fa3cf2083	f	2026-03-24 15:29:15.710555+00	2026-03-24 18:48:43.851676+00
278	billionaire_club	bf90f59d-17f6-450a-b476-a7be8a7b39ef	f	2026-03-24 17:58:36.835405+00	2026-03-24 18:48:43.851676+00
157	mubeen	81626efa-82b0-432d-8404-d6294be757b4	f	2026-03-24 15:28:12.593259+00	2026-03-24 18:48:43.82537+00
133	mubeen	3a52f2e2-9973-4633-af64-5c5e70cc675c	f	2026-03-24 15:26:12.425365+00	2026-03-24 18:48:43.82537+00
83	mubeen	0c165ea1-7bed-4861-a98e-84fad61934cf	f	2026-02-23 22:19:23.900741+00	2026-03-24 18:48:43.82537+00
3	mubeen	7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7	f	2026-02-21 20:56:42.982337+00	2026-03-24 18:48:43.82537+00
52	mubeen	3da1f70b-e2c5-4adf-8538-36a1b08a7c1d	f	2026-02-23 22:00:04.263512+00	2026-03-24 18:48:43.82537+00
55	mubeen	dc676f05-2ea2-46a1-83e6-cd94264de918	f	2026-02-23 22:00:19.658161+00	2026-03-24 18:48:43.82537+00
58	mubeen	563ffbe2-e136-465a-8e63-67ef65eb7dc1	f	2026-02-23 22:00:27.083251+00	2026-03-24 18:48:43.82537+00
61	mubeen	9037fb24-f837-4585-9c80-8f3cb39ea02b	f	2026-02-23 22:02:16.268282+00	2026-03-24 18:48:43.82537+00
310	billionaire_club	ccbcb512-0831-4eb3-83b9-977c7dbc05e8	t	2026-03-24 18:48:43.851676+00	2026-03-24 18:48:43.855668+00
67	mubeen	fa651957-cab2-4265-a5f1-ab6e89047520	f	2026-02-23 22:03:02.834231+00	2026-03-24 18:48:43.82537+00
73	mubeen	3f677a60-eeac-45f4-8682-eb194af483b0	f	2026-02-23 22:03:53.16065+00	2026-03-24 18:48:43.82537+00
93	mubeen	94b23653-e8ac-49a4-94d6-a7a66ece48b3	f	2026-02-23 22:19:39.787324+00	2026-03-24 18:48:43.82537+00
101	mubeen	57b5bc4c-ed2a-43be-a7df-7d2351415ab0	f	2026-03-24 15:23:59.842122+00	2026-03-24 18:48:43.82537+00
248	mubeen	5fef657e-a2a4-49eb-8776-13bc3e6eabea	f	2026-03-24 17:25:54.322234+00	2026-03-24 18:48:43.82537+00
312	fredtrading	9056b568-6c56-4888-8bd4-d253b2533a8e	f	2026-03-24 18:48:43.858297+00	2026-03-24 18:48:43.874271+00
286	fredtrading	45528ef2-28b1-4899-95ba-37f0b8b71ddf	f	2026-03-24 18:14:41.235241+00	2026-03-24 18:48:43.874271+00
191	fredtrading	e26d316f-6f84-4c39-92aa-9e0511d9ef5a	f	2026-03-24 16:29:46.788728+00	2026-03-24 18:48:43.874271+00
173	fredtrading	5eb0956c-6479-4916-aae3-c0fbb47f3387	f	2026-03-24 16:06:06.000481+00	2026-03-24 18:48:43.874271+00
160	fredtrading	52f0787b-fc17-4f77-9f97-b1b8d0798d50	f	2026-03-24 15:28:12.622173+00	2026-03-24 18:48:43.874271+00
136	fredtrading	3af5a463-d0ab-4a53-bac1-2075ab43e75a	f	2026-03-24 15:26:12.453736+00	2026-03-24 18:48:43.874271+00
122	fredtrading	f0f44996-9214-446a-ae82-47f8f77cfd17	f	2026-03-24 15:25:04.183403+00	2026-03-24 18:48:43.874271+00
120	fredtrading	76d09504-5bda-4c82-af1f-14cbf93142fa	f	2026-03-24 15:25:04.166279+00	2026-03-24 18:48:43.874271+00
92	fredtrading	c347530f-9157-44c9-a612-8dd5cd1aedd2	f	2026-02-23 22:19:39.779298+00	2026-03-24 18:48:43.874271+00
308	fredtrading	9ecd439b-f538-4c8c-ac50-311cc2f16590	f	2026-03-24 18:48:43.820463+00	2026-03-24 18:48:43.874271+00
76	fredtrading	2591181b-cf8c-45d6-a54a-239a107cf80c	f	2026-02-23 22:03:53.196917+00	2026-03-24 18:48:43.874271+00
74	fredtrading	ebdefb0c-b209-4fe6-9cc2-59cd76f85ed4	f	2026-02-23 22:03:53.166347+00	2026-03-24 18:48:43.874271+00
70	fredtrading	6444cf0b-293f-4905-a8c6-e14e14485672	f	2026-02-23 22:03:02.869797+00	2026-03-24 18:48:43.874271+00
214	fredtrading	855e07f7-ebfd-4837-889b-02583c33e076	f	2026-03-24 16:34:35.958339+00	2026-03-24 18:48:43.874271+00
293	fredtrading	bfcf3fbc-6177-4a22-ba5b-cbe379bbfdce	f	2026-03-24 18:27:02.33878+00	2026-03-24 18:48:43.874271+00
313	fredtrading	9d5a905c-f4ab-4ed6-a52e-6bedd6c05f5d	f	2026-03-24 18:48:43.866512+00	2026-03-24 18:48:43.874271+00
304	fredtrading	8f6155d5-2178-483f-af3c-4179ca61f2c9	f	2026-03-24 18:48:43.786935+00	2026-03-24 18:48:43.874271+00
152	fredtrading	8ccbf8e6-f8c4-4ffa-aa71-c2b0020b4110	f	2026-03-24 15:27:21.47325+00	2026-03-24 18:48:43.874271+00
153	fredtrading	77dc6c00-81c3-4f88-a6eb-7e089379e90b	f	2026-03-24 15:27:21.483589+00	2026-03-24 18:48:43.874271+00
305	fredtrading	77a67de2-c3fb-479d-9d0c-67585c637233	f	2026-03-24 18:48:43.793261+00	2026-03-24 18:48:43.874271+00
174	fredtrading	dac10980-e70d-4382-ab78-44340188ad29	f	2026-03-24 16:06:16.612151+00	2026-03-24 18:48:43.874271+00
251	mubeen	8a2bded4-04fe-40d2-a652-3a21a7386d83	f	2026-03-24 17:57:29.100715+00	2026-03-24 18:48:43.82537+00
273	mubeen	a8703337-8880-4922-aad6-371e991adff1	f	2026-03-24 17:58:36.774883+00	2026-03-24 18:48:43.82537+00
284	mubeen	00fb8167-d409-40fb-9173-13377faaea7e	f	2026-03-24 18:14:41.19738+00	2026-03-24 18:48:43.82537+00
295	mubeen	6777dc64-0de3-466b-aa28-ffdd07cd73c8	f	2026-03-24 18:27:02.354845+00	2026-03-24 18:48:43.82537+00
306	mubeen	2720f339-7175-4131-924d-7a6a85528739	f	2026-03-24 18:48:43.800483+00	2026-03-24 18:48:43.82537+00
51	fredtrading	fbef469b-8aa1-4c40-a128-4ca242b0d659	f	2026-02-23 22:00:04.254839+00	2026-03-24 18:48:43.874271+00
274	fredtrading	47f870e8-6789-4365-9eb7-5da3db26c6ed	f	2026-03-24 17:58:36.799531+00	2026-03-24 18:48:43.874271+00
162	fredtrading	9f79d8ba-1ee8-4e25-ad38-acf720dd555e	f	2026-03-24 15:28:12.640177+00	2026-03-24 18:48:43.874271+00
146	fredtrading	c9ad4ebd-c9a8-4fe3-9e58-d654d0bb04b8	f	2026-03-24 15:26:57.792026+00	2026-03-24 18:48:43.874271+00
57	fredtrading	3e91f7af-0cef-4618-a641-65b0d690a30c	f	2026-02-23 22:00:27.075591+00	2026-03-24 18:48:43.874271+00
243	fredtrading	c6299cc3-c810-4cae-90ab-1c0b150c62d1	f	2026-03-24 17:23:47.304062+00	2026-03-24 18:48:43.874271+00
96	fredtrading	af59db7a-360d-4501-89e0-2fde151df8a5	f	2026-02-23 22:19:39.816454+00	2026-03-24 18:48:43.874271+00
144	fredtrading	ed1a5018-cef4-409b-abbc-20fe3fa0ab88	f	2026-03-24 15:26:57.773567+00	2026-03-24 18:48:43.874271+00
309	mubeen	09a52cfc-4d61-40d7-93af-ddc2974eb157	t	2026-03-24 18:48:43.82537+00	2026-03-24 18:48:43.82537+00
186	billionaire_club	26be5f31-ae83-437d-89f2-ec86ca4284e2	f	2026-03-24 16:26:08.747103+00	2026-03-24 18:48:43.851676+00
185	billionaire_club	7cf7abde-9e1e-4577-a9db-4d09f090dd4f	f	2026-03-24 16:26:08.745347+00	2026-03-24 18:48:43.851676+00
159	billionaire_club	833a1961-2e95-4b36-8dab-a784026632d6	f	2026-03-24 15:28:12.618278+00	2026-03-24 18:48:43.851676+00
158	billionaire_club	3f9f8c09-cde0-4f8e-af32-c0d862e56325	f	2026-03-24 15:28:12.616462+00	2026-03-24 18:48:43.851676+00
80	billionaire_club	4b48d579-1702-42d8-87cb-24f92959ad4a	f	2026-02-23 22:18:21.125931+00	2026-03-24 18:48:43.851676+00
90	billionaire_club	ec680271-c9b3-4efc-9cb0-a80521892cb7	f	2026-02-23 22:19:31.286254+00	2026-03-24 18:48:43.851676+00
89	billionaire_club	b8717482-981e-432d-b35a-0a19b6d1bd52	f	2026-02-23 22:19:31.28305+00	2026-03-24 18:48:43.851676+00
127	billionaire_club	c12f8cb6-4ff2-48b9-b77a-888acb062a2e	f	2026-03-24 15:25:34.156573+00	2026-03-24 18:48:43.851676+00
126	billionaire_club	67af3231-48cf-4afb-b153-4b7e6bdbb7e3	f	2026-03-24 15:25:34.154887+00	2026-03-24 18:48:43.851676+00
143	billionaire_club	4221ce48-1d94-46a5-91ca-560b62dede65	f	2026-03-24 15:26:57.76964+00	2026-03-24 18:48:43.851676+00
142	billionaire_club	73fee00d-9df9-479f-a774-d5c6d2439a2b	f	2026-03-24 15:26:57.767952+00	2026-03-24 18:48:43.851676+00
311	billionaire_club	fee6de13-cb0c-4564-96fe-9eaebe6e70bd	f	2026-03-24 18:48:43.854606+00	2026-03-24 18:48:43.854606+00
285	fredtrading	f5aae787-c36d-4138-a068-f584645ca751	f	2026-03-24 18:14:41.231498+00	2026-03-24 18:48:43.874271+00
281	fredtrading	75c9d5cf-960c-41dd-9c4e-0915cb029d54	f	2026-03-24 17:58:36.862119+00	2026-03-24 18:48:43.874271+00
218	fredtrading	69be31b6-a299-4a2b-b5e2-ef7cb6a6b27a	f	2026-03-24 16:35:06.388416+00	2026-03-24 18:48:43.874271+00
196	fredtrading	770cdb91-23a8-4a01-aa0f-5731af367fd0	f	2026-03-24 16:29:46.838584+00	2026-03-24 18:48:43.874271+00
189	fredtrading	ce3d5d26-e900-4494-a462-4e5658a73d77	f	2026-03-24 16:26:08.770382+00	2026-03-24 18:48:43.874271+00
187	fredtrading	cec3388d-fa47-493c-9f3b-a204c2e6480b	f	2026-03-24 16:26:08.750996+00	2026-03-24 18:48:43.874271+00
48	fredtrading	ef3bd7d6-22da-45cf-b583-969d1221cf16	f	2026-02-23 21:58:57.248547+00	2026-03-24 18:48:43.874271+00
49	fredtrading	4599014d-6053-4eee-813c-5846e6385938	f	2026-02-23 21:58:57.252365+00	2026-03-24 18:48:43.874271+00
50	fredtrading	694b1256-7b7f-4af5-b123-21f7aee87add	f	2026-02-23 22:00:04.250236+00	2026-03-24 18:48:43.874271+00
161	fredtrading	ecb520d6-79df-4657-b806-b52a0f3361db	f	2026-03-24 15:28:12.631525+00	2026-03-24 18:48:43.874271+00
192	mubeen	089eee55-ef36-4ada-a52e-7034627aecdd	f	2026-03-24 16:29:46.794073+00	2026-03-24 18:48:43.82537+00
165	mubeen	ca5a6cf7-b80e-456d-8811-98278bf5a861	f	2026-03-24 15:29:15.684078+00	2026-03-24 18:48:43.82537+00
79	mubeen	b1e7e300-1f6d-4866-8f3d-4afcf833acf7	f	2026-02-23 22:18:19.24918+00	2026-03-24 18:48:43.82537+00
88	mubeen	71b365c4-36f6-4247-a2b0-6feb0baa934e	f	2026-02-23 22:19:31.262253+00	2026-03-24 18:48:43.82537+00
125	mubeen	5316578a-44e2-40ee-9a3e-b7c7a2cf7de6	f	2026-03-24 15:25:34.130239+00	2026-03-24 18:48:43.82537+00
141	mubeen	1404a98d-0a0f-4b5f-b179-2c47e30f00f3	f	2026-03-24 15:26:57.742023+00	2026-03-24 18:48:43.82537+00
287	mubeen	0adb8542-6104-4c0e-8148-adb1f6fbf2cc	f	2026-03-24 18:14:41.241905+00	2026-03-24 18:48:43.82537+00
176	mubeen	c3851abb-50c0-40b2-a870-28cbc5ad1ba6	f	2026-03-24 16:06:16.619164+00	2026-03-24 18:48:43.82537+00
222	mubeen	16ce43af-59a4-4e26-9190-9daf02fa8016	f	2026-03-24 16:35:16.041907+00	2026-03-24 18:48:43.82537+00
117	mubeen	42c23288-8713-473a-b1e7-ff46905a9806	f	2026-03-24 15:25:04.136622+00	2026-03-24 18:48:43.82537+00
184	mubeen	e00fee57-b3f1-445b-9632-954e9eebe105	f	2026-03-24 16:26:08.718435+00	2026-03-24 18:48:43.82537+00
298	mubeen	9a2dc35e-959f-43a7-9c9c-b52c9a346a24	f	2026-03-24 18:27:02.380926+00	2026-03-24 18:48:43.82537+00
216	mubeen	9b79ab6e-8edc-46a4-9718-ad5108dade57	f	2026-03-24 16:34:36.205366+00	2026-03-24 18:48:43.82537+00
219	mubeen	c0dd92bd-a797-4ff7-bd0d-33b80564e25e	f	2026-03-24 16:35:06.397616+00	2026-03-24 18:48:43.82537+00
276	mubeen	4eef5584-91ec-4afb-884f-1097041dcfd4	f	2026-03-24 17:58:36.807381+00	2026-03-24 18:48:43.82537+00
233	mubeen	40bfb475-7d76-43c0-9c2c-4cc4d38364ad	f	2026-03-24 16:35:31.901453+00	2026-03-24 18:48:43.82537+00
236	mubeen	ed77ca9d-bdf6-47af-b849-f6590fdd3d72	f	2026-03-24 17:20:39.628334+00	2026-03-24 18:48:43.82537+00
109	mubeen	65cb65a3-61d9-4d45-a3bb-568d616cd648	f	2026-03-24 15:24:18.203606+00	2026-03-24 18:48:43.82537+00
239	mubeen	85aa3cda-87e8-4b38-a6f4-ccb535d3dd8d	f	2026-03-24 17:22:51.070083+00	2026-03-24 18:48:43.82537+00
254	mubeen	d9b749f2-7201-4b8b-81a6-9cd7cc7485fb	f	2026-03-24 17:57:29.128906+00	2026-03-24 18:48:43.82537+00
111	billionaire_club	469fe66e-9101-4354-abc2-b6f067d2107c	f	2026-03-24 15:24:18.217978+00	2026-03-24 18:48:43.851676+00
110	billionaire_club	cc2477fc-447f-4e9d-9ccd-2be059ae13c4	f	2026-03-24 15:24:18.216528+00	2026-03-24 18:48:43.851676+00
256	billionaire_club	747fa3b9-05d5-4a82-a568-09fe3cfa1b2e	f	2026-03-24 17:57:29.164634+00	2026-03-24 18:48:43.851676+00
277	billionaire_club	5844ced6-6be5-48cd-9fd6-ff390a89ff24	f	2026-03-24 17:58:36.833382+00	2026-03-24 18:48:43.851676+00
289	billionaire_club	b65ac80f-5757-4257-a160-d49354b8616b	f	2026-03-24 18:14:41.269366+00	2026-03-24 18:48:43.851676+00
300	billionaire_club	73e2ccef-3a9d-40df-9941-167965baef84	f	2026-03-24 18:27:02.408338+00	2026-03-24 18:48:43.851676+00
145	fredtrading	39def072-f835-407d-8cb9-47ce205b1498	f	2026-03-24 15:26:57.783251+00	2026-03-24 18:48:43.874271+00
105	fredtrading	61661b02-e4cd-4cd2-bb28-d359687960a2	f	2026-03-24 15:23:59.884749+00	2026-03-24 18:48:43.874271+00
275	fredtrading	a9c8259b-f6e1-4886-95b1-1b9ad177f4b9	f	2026-03-24 17:58:36.8019+00	2026-03-24 18:48:43.874271+00
269	fredtrading	23e51a78-2b52-4425-85aa-28665d43ee2c	f	2026-03-24 17:57:43.355512+00	2026-03-24 18:48:43.874271+00
279	fredtrading	9f856726-5e9b-44d0-822e-323a7448ecd1	f	2026-03-24 17:58:36.839952+00	2026-03-24 18:48:43.874271+00
171	fredtrading	ac9529ea-ef01-4169-ad17-0cc88a2867c3	f	2026-03-24 16:06:05.976565+00	2026-03-24 18:48:43.874271+00
172	fredtrading	c1609da7-a45c-4137-84c7-72a1a3b74784	f	2026-03-24 16:06:05.989222+00	2026-03-24 18:48:43.874271+00
238	fredtrading	fb486da7-4d96-4650-b684-e7c9d9ddd7b9	f	2026-03-24 17:22:51.060511+00	2026-03-24 18:48:43.874271+00
59	fredtrading	d914974e-753e-4418-b5d9-8ec71ac7354d	f	2026-02-23 22:02:16.222349+00	2026-03-24 18:48:43.874271+00
244	fredtrading	29474a21-092d-476a-a3cf-630ba7ade510	f	2026-03-24 17:23:47.315582+00	2026-03-24 18:48:43.874271+00
252	fredtrading	037c3556-8796-48d0-92d2-5b262a279370	f	2026-03-24 17:57:29.122265+00	2026-03-24 18:48:43.874271+00
180	fredtrading	b00b2348-0c3f-46e6-a837-000954f4adc7	f	2026-03-24 16:06:16.659784+00	2026-03-24 18:48:43.874271+00
307	fredtrading	0e81ab98-de5c-4cea-8ba6-12293c1626ff	f	2026-03-24 18:48:43.818532+00	2026-03-24 18:48:43.874271+00
303	fredtrading	8708524d-c2f0-4ffe-81fa-88f89d5c84f1	f	2026-03-24 18:27:02.430586+00	2026-03-24 18:48:43.874271+00
280	fredtrading	5bb1722b-d6d1-482a-8f0d-3fca98385293	f	2026-03-24 17:58:36.850939+00	2026-03-24 18:48:43.874271+00
100	fredtrading	6d002a8a-4c1b-4b21-8e1f-4d37775d20ea	f	2026-03-24 15:23:59.837219+00	2026-03-24 18:48:43.874271+00
98	fredtrading	5b1f0c8f-2538-4ad7-9189-d9f9813ea968	f	2026-02-23 22:19:39.847377+00	2026-03-24 18:48:43.874271+00
138	fredtrading	4b535fb2-9d80-4970-9bbb-3f005d77b4d2	f	2026-03-24 15:26:12.470589+00	2026-03-24 18:48:43.874271+00
137	fredtrading	868bfe6d-a6ab-4486-a00d-584239473c23	f	2026-03-24 15:26:12.462268+00	2026-03-24 18:48:43.874271+00
149	mubeen	1e7093ac-641c-4236-8c17-5d2f9b97d131	f	2026-03-24 15:27:21.456204+00	2026-03-24 18:48:43.82537+00
225	mubeen	fd1b33f8-5da7-4cff-b5c7-50431e1d174e	f	2026-03-24 16:35:16.074614+00	2026-03-24 18:48:43.82537+00
135	billionaire_club	35dcf60a-53bf-4a93-bd87-909af59306e4	f	2026-03-24 15:26:12.45005+00	2026-03-24 18:48:43.851676+00
134	billionaire_club	7d4416ff-efe6-4793-9c71-98dfd80209e5	f	2026-03-24 15:26:12.448589+00	2026-03-24 18:48:43.851676+00
166	billionaire_club	adb17f21-4384-497b-b3db-877f5fa1cae0	f	2026-03-24 15:29:15.708706+00	2026-03-24 18:48:43.851676+00
178	billionaire_club	410cb016-e098-4243-b641-3fb6e8d4198a	f	2026-03-24 16:06:16.645464+00	2026-03-24 18:48:43.851676+00
177	billionaire_club	f9ee7234-2eca-4e21-9ca9-7987cb0a5974	f	2026-03-24 16:06:16.644008+00	2026-03-24 18:48:43.851676+00
194	billionaire_club	90964f23-c7b2-48c9-bc8a-6a9e071bd55d	f	2026-03-24 16:29:46.823928+00	2026-03-24 18:48:43.851676+00
193	billionaire_club	96d2e6cd-fdfb-4e1f-862f-20ae298658c3	f	2026-03-24 16:29:46.821744+00	2026-03-24 18:48:43.851676+00
151	billionaire_club	bf0f28cc-194e-42b0-b5ab-c5dcf5becd4e	f	2026-03-24 15:27:21.469452+00	2026-03-24 18:48:43.851676+00
150	billionaire_club	bc99a4a9-e254-4f7d-9345-d07f12eb27ff	f	2026-03-24 15:27:21.468144+00	2026-03-24 18:48:43.851676+00
227	billionaire_club	0ff641ed-c835-4fe0-a2f9-23b2ccb382d8	f	2026-03-24 16:35:16.104416+00	2026-03-24 18:48:43.851676+00
226	billionaire_club	54672ede-056b-452f-8fbd-571603bcb8d3	f	2026-03-24 16:35:16.102565+00	2026-03-24 18:48:43.851676+00
255	billionaire_club	3024de89-bf85-4a5d-a675-b98eb7356cb9	f	2026-03-24 17:57:29.162901+00	2026-03-24 18:48:43.851676+00
314	fredtrading	fef40035-9de0-4692-b8fe-e676a491cdf5	t	2026-03-24 18:48:43.874271+00	2026-03-24 18:48:43.874271+00
60	fredtrading	90b89d6f-39f8-45a5-96bd-c095c935da44	f	2026-02-23 22:02:16.245335+00	2026-03-24 18:48:43.874271+00
206	fredtrading	a8efc261-0895-4495-a332-db5061ecfc61	f	2026-03-24 16:30:44.582667+00	2026-03-24 18:48:43.874271+00
260	fredtrading	4d90ea74-d813-4b0f-9ad2-7ac10e4c59b2	f	2026-03-24 17:57:43.26768+00	2026-03-24 18:48:43.874271+00
261	fredtrading	e76dd04a-b82b-40a7-adfb-962cea6cba15	f	2026-03-24 17:57:43.275366+00	2026-03-24 18:48:43.874271+00
272	fredtrading	cbf82e7b-eaaa-4113-b3e8-032f701c6bf6	f	2026-03-24 17:58:36.764988+00	2026-03-24 18:48:43.874271+00
82	fredtrading	3bf57164-1b10-468d-a996-9a200c45fdb2	f	2026-02-23 22:19:23.892052+00	2026-03-24 18:48:43.874271+00
198	fredtrading	2ada7612-e2f7-4dcd-8c12-b4ac69c1fa35	f	2026-03-24 16:30:09.474971+00	2026-03-24 18:48:43.874271+00
199	fredtrading	8db973bd-85e5-4d17-8cc4-19321e53fad5	f	2026-03-24 16:30:09.480841+00	2026-03-24 18:48:43.874271+00
257	fredtrading	7b9797d7-d844-4da6-9e93-645fc1ca134f	f	2026-03-24 17:57:29.168571+00	2026-03-24 18:48:43.874271+00
234	fredtrading	e1dcb7f7-d346-4858-8b4b-1a336a5e6289	f	2026-03-24 17:20:39.609162+00	2026-03-24 18:48:43.874271+00
294	fredtrading	c07b4c18-6540-4d2f-8e0d-9f3e19d545d2	f	2026-03-24 18:27:02.346458+00	2026-03-24 18:48:43.874271+00
181	fredtrading	fa32dae1-1864-4268-a568-f30df8a8cc59	f	2026-03-24 16:06:16.668825+00	2026-03-24 18:48:43.874271+00
69	fredtrading	97b22529-ff06-4788-943c-789be1a53fd0	f	2026-02-23 22:03:02.855348+00	2026-03-24 18:48:43.874271+00
164	fredtrading	31ef946a-eb3f-4cfc-8fc9-2494923cd7a8	f	2026-03-24 15:29:15.678994+00	2026-03-24 18:48:43.874271+00
212	fredtrading	08ee3072-13ca-4d3c-b510-466dd73faedf	f	2026-03-24 16:30:44.635972+00	2026-03-24 18:48:43.874271+00
268	fredtrading	430a512a-2be2-4f32-8c49-254a2de04a9c	f	2026-03-24 17:57:43.346702+00	2026-03-24 18:48:43.874271+00
259	fredtrading	80f9b07d-34cf-44a2-bb6f-239e8a2e502b	f	2026-03-24 17:57:29.18682+00	2026-03-24 18:48:43.874271+00
302	fredtrading	f91cbfb1-64be-4da0-ba41-c020e7afb031	f	2026-03-24 18:27:02.421967+00	2026-03-24 18:48:43.874271+00
301	fredtrading	45efcafe-e9f7-41cf-9331-3e95542ac003	f	2026-03-24 18:27:02.412595+00	2026-03-24 18:48:43.874271+00
247	fredtrading	1a21878c-7216-449d-b930-d89738854d28	f	2026-03-24 17:25:54.309719+00	2026-03-24 18:48:43.874271+00
97	fredtrading	031f7c17-799d-4359-996d-7a76108c8240	f	2026-02-23 22:19:39.832159+00	2026-03-24 18:48:43.874271+00
155	fredtrading	d3ad0b4f-7ecb-4a84-91f4-e80fdbc8a597	f	2026-03-24 15:28:12.586888+00	2026-03-24 18:48:43.874271+00
296	fredtrading	f9bef580-8ed9-42fb-b58e-0c2d518be3d5	f	2026-03-24 18:27:02.374074+00	2026-03-24 18:48:43.874271+00
156	fredtrading	518f4c87-8462-4155-92de-ee0c78aa33d5	f	2026-03-24 15:28:12.588854+00	2026-03-24 18:48:43.874271+00
220	fredtrading	f97878ce-5e11-4d1f-b075-84d1b320c98e	f	2026-03-24 16:35:16.02069+00	2026-03-24 18:48:43.874271+00
71	fredtrading	9c346e8c-8cec-4204-8a50-4a8cfb465e1b	f	2026-02-23 22:03:53.148133+00	2026-03-24 18:48:43.874271+00
154	fredtrading	a38b8b83-1cd1-4740-a666-14b69baf7095	f	2026-03-24 15:27:21.492122+00	2026-03-24 18:48:43.874271+00
204	fredtrading	8ba7fd9d-8982-42ba-83d2-d516a4894d29	f	2026-03-24 16:30:09.536394+00	2026-03-24 18:48:43.874271+00
297	fredtrading	78ad23c9-9176-45ca-a897-8bee993d4165	f	2026-03-24 18:27:02.376212+00	2026-03-24 18:48:43.874271+00
291	fredtrading	b74076a7-6bf6-439f-868f-e3fb2a5d43ef	f	2026-03-24 18:14:41.283489+00	2026-03-24 18:48:43.874271+00
215	fredtrading	6a17193f-2cb2-4201-b293-604889d66481	f	2026-03-24 16:34:36.088486+00	2026-03-24 18:48:43.874271+00
217	fredtrading	3f5d1202-5456-4070-8820-3ff1bd078f52	f	2026-03-24 16:35:06.375007+00	2026-03-24 18:48:43.874271+00
271	fredtrading	f4fce66a-71a0-4be4-a2e5-2d117022130f	f	2026-03-24 17:58:36.755157+00	2026-03-24 18:48:43.874271+00
224	fredtrading	9deba179-76a1-4093-b814-341e220d2a35	f	2026-03-24 16:35:16.069101+00	2026-03-24 18:48:43.874271+00
211	fredtrading	65d34501-53b5-4782-8fd8-691d7857a0e9	f	2026-03-24 16:30:44.624327+00	2026-03-24 18:48:43.874271+00
99	fredtrading	6014c133-ff44-4041-9f65-976e774ae933	f	2026-03-24 15:23:59.831308+00	2026-03-24 18:48:43.874271+00
282	fredtrading	c4cdf78e-26cb-4cf5-ad45-9e8087cb0425	f	2026-03-24 18:14:41.178567+00	2026-03-24 18:48:43.874271+00
283	fredtrading	da90b2b9-5b73-4359-be5d-1121e1f6798d	f	2026-03-24 18:14:41.187246+00	2026-03-24 18:48:43.874271+00
129	fredtrading	c0bb1266-fd27-4b8c-b57f-edd6bd745372	f	2026-03-24 15:25:34.169514+00	2026-03-24 18:48:43.874271+00
62	fredtrading	a7de8947-1b38-40bc-bc9a-1ac068b29342	f	2026-02-23 22:02:16.274448+00	2026-03-24 18:48:43.874271+00
179	fredtrading	ccd6d937-223d-4181-bdba-8a927c0213f0	f	2026-03-24 16:06:16.649428+00	2026-03-24 18:48:43.874271+00
228	fredtrading	3792b8ca-fe7b-4619-901b-ff0d0f2f07e1	f	2026-03-24 16:35:16.108785+00	2026-03-24 18:48:43.874271+00
213	fredtrading	1749ab8a-1dc9-4d48-b381-c52f462cc2c7	f	2026-03-24 16:30:44.6457+00	2026-03-24 18:48:43.874271+00
235	fredtrading	5ec9126d-9d61-4746-9025-74ac3a0cd568	f	2026-03-24 17:20:39.619451+00	2026-03-24 18:48:43.874271+00
237	fredtrading	20064908-c6ff-4b51-b796-33b3eebee142	f	2026-03-24 17:22:51.050231+00	2026-03-24 18:48:43.874271+00
200	mubeen	cabbd7c4-9801-4c5c-8297-0231ad71737f	f	2026-03-24 16:30:09.487557+00	2026-03-24 18:48:43.82537+00
208	mubeen	3ec1755f-cc9e-47a8-b7dc-7619369eb4d7	f	2026-03-24 16:30:44.59176+00	2026-03-24 18:48:43.82537+00
242	mubeen	5ac183f3-9f1b-4bff-80e3-4d1b35250fbe	f	2026-03-24 17:23:07.785739+00	2026-03-24 18:48:43.82537+00
245	mubeen	b47865c6-8610-4f1d-a9d1-b28d44709dc0	f	2026-03-24 17:23:47.326646+00	2026-03-24 18:48:43.82537+00
202	billionaire_club	f6b15e29-2d37-40bf-83a5-731567cc0f97	f	2026-03-24 16:30:09.518784+00	2026-03-24 18:48:43.851676+00
201	billionaire_club	6f378963-0413-4f3e-afbc-c69b90753a38	f	2026-03-24 16:30:09.516584+00	2026-03-24 18:48:43.851676+00
210	billionaire_club	de6bfc4f-4f61-4583-843e-831cb06c510c	f	2026-03-24 16:30:44.620361+00	2026-03-24 18:48:43.851676+00
209	billionaire_club	4ab6356e-f696-455f-bec3-44e344aad9a3	f	2026-03-24 16:30:44.618433+00	2026-03-24 18:48:43.851676+00
290	fredtrading	920ca037-de0a-4c34-b053-7c97268de641	f	2026-03-24 18:14:41.273479+00	2026-03-24 18:48:43.874271+00
131	fredtrading	b6a5c828-cf6e-4833-ab99-93efbcf40dd1	f	2026-03-24 15:26:12.417615+00	2026-03-24 18:48:43.874271+00
132	fredtrading	ceed9318-6324-45cb-b507-2c85eaaa6e65	f	2026-03-24 15:26:12.420873+00	2026-03-24 18:48:43.874271+00
221	fredtrading	646c3434-7f9e-497a-bad6-06f7d24e2593	f	2026-03-24 16:35:16.032146+00	2026-03-24 18:48:43.874271+00
147	fredtrading	fa23e53a-a50c-42ee-aca9-50faa37b53db	f	2026-03-24 15:27:21.4485+00	2026-03-24 18:48:43.874271+00
148	fredtrading	dc6eabac-d2c1-4be5-8cf3-607ca8569d25	f	2026-03-24 15:27:21.451728+00	2026-03-24 18:48:43.874271+00
163	fredtrading	2c620b0b-9821-48fb-9b27-f952c84ab46a	f	2026-03-24 15:29:15.676915+00	2026-03-24 18:48:43.874271+00
72	fredtrading	c149afb9-bcf8-4d4d-8709-62d1e288e9d2	f	2026-02-23 22:03:53.153022+00	2026-03-24 18:48:43.874271+00
81	fredtrading	3cdae7ee-098f-4184-83a0-24e2e9e1a3b0	f	2026-02-23 22:19:23.888647+00	2026-03-24 18:48:43.874271+00
263	fredtrading	ab42cd3c-9195-485b-8171-fc3fde5b4d59	f	2026-03-24 17:57:43.30631+00	2026-03-24 18:48:43.874271+00
175	fredtrading	b7693b7a-2dda-4ff4-881c-a6de8f72f67f	f	2026-03-24 16:06:16.614372+00	2026-03-24 18:48:43.874271+00
262	mubeen	ef314185-421b-467e-bd47-330c5f9df910	f	2026-03-24 17:57:43.284019+00	2026-03-24 18:48:43.82537+00
292	fredtrading	199fe4c7-5182-48fd-917c-b22993e1d555	f	2026-03-24 18:14:41.292783+00	2026-03-24 18:48:43.874271+00
264	fredtrading	d48144aa-b6c7-4663-aeb2-cd4f493a2ff9	f	2026-03-24 17:57:43.309092+00	2026-03-24 18:48:43.874271+00
207	fredtrading	9828f38d-0515-45e5-8cc5-5519a3f4f2e3	f	2026-03-24 16:30:44.585426+00	2026-03-24 18:48:43.874271+00
197	fredtrading	53a484d9-0bd1-47be-9193-fdfdf1048286	f	2026-03-24 16:29:46.848506+00	2026-03-24 18:48:43.874271+00
65	fredtrading	13b8515c-51ce-4830-a242-dbb69e4c4829	f	2026-02-23 22:03:02.823557+00	2026-03-24 18:48:43.874271+00
68	fredtrading	3b2e62c9-44a1-4480-9e93-c0241b0f0910	f	2026-02-23 22:03:02.840767+00	2026-03-24 18:48:43.874271+00
123	fredtrading	208333e7-2f78-47db-a285-250deb1b66f9	f	2026-03-24 15:25:34.12204+00	2026-03-24 18:48:43.874271+00
91	fredtrading	1c8a4264-3998-477e-afc6-8f3110db39d6	f	2026-02-23 22:19:39.776395+00	2026-03-24 18:48:43.874271+00
124	fredtrading	8c3b5f6f-2bbf-46ae-b5f5-445b5a8c77e6	f	2026-03-24 15:25:34.125368+00	2026-03-24 18:48:43.874271+00
128	fredtrading	d2aef4cf-ad7e-4d98-a66d-f27eee851716	f	2026-03-24 15:25:34.160311+00	2026-03-24 18:48:43.874271+00
170	fredtrading	088a6d01-3d06-479f-b27f-ca395f4393c8	f	2026-03-24 15:29:15.732283+00	2026-03-24 18:48:43.874271+00
114	fredtrading	46fccc78-bcc5-49b4-8314-9bbf952b40f4	f	2026-03-24 15:24:18.239472+00	2026-03-24 18:48:43.874271+00
195	fredtrading	c8e7506a-4e80-49e4-87e6-4d5e90c5ed93	f	2026-03-24 16:29:46.827702+00	2026-03-24 18:48:43.874271+00
107	fredtrading	4a5bd11d-6ff7-4713-9b37-abf1ee22ad02	f	2026-03-24 15:24:18.196+00	2026-03-24 18:48:43.874271+00
108	fredtrading	e55bb795-6c69-43b4-a35e-33aafdc7d787	f	2026-03-24 15:24:18.199127+00	2026-03-24 18:48:43.874271+00
112	fredtrading	c3b38133-059a-4f7f-a6fa-568b11e3e61e	f	2026-03-24 15:24:18.221475+00	2026-03-24 18:48:43.874271+00
168	fredtrading	6f3d6c8f-b795-4a61-aa32-0ddc3682d8d7	f	2026-03-24 15:29:15.714355+00	2026-03-24 18:48:43.874271+00
121	fredtrading	722c2128-fd74-4f9d-886a-14bd27e5820a	f	2026-03-24 15:25:04.175058+00	2026-03-24 18:48:43.874271+00
106	fredtrading	ab0cfdea-463a-41c7-bb48-954b3979cc85	f	2026-03-24 15:23:59.896349+00	2026-03-24 18:48:43.874271+00
104	fredtrading	62ac7883-ff68-4241-9753-cb0cbbb1657b	f	2026-03-24 15:23:59.87361+00	2026-03-24 18:48:43.874271+00
183	fredtrading	f9f84603-5a70-4e46-bbde-3ef204f0f5ea	f	2026-03-24 16:26:08.713527+00	2026-03-24 18:48:43.874271+00
190	fredtrading	effaaddd-2d0c-4ff2-b774-87f0bfe9a48c	f	2026-03-24 16:29:46.784174+00	2026-03-24 18:48:43.874271+00
53	fredtrading	f9267f49-f39a-4246-9edb-2641f9e0a3f6	f	2026-02-23 22:00:19.645563+00	2026-03-24 18:48:43.874271+00
113	fredtrading	767fdf5a-fcec-4ee0-a8da-eaf8a748d297	f	2026-03-24 15:24:18.230844+00	2026-03-24 18:48:43.874271+00
241	fredtrading	1146a8bc-f66e-42cc-87f6-0b1fd9a6980f	f	2026-03-24 17:23:07.774866+00	2026-03-24 18:48:43.874271+00
230	fredtrading	482c4614-2fb8-4861-b664-6bb4019ce4fc	f	2026-03-24 16:35:16.128951+00	2026-03-24 18:48:43.874271+00
54	fredtrading	1d122ac1-97fc-4b79-a1a8-bbe8ac80d7de	f	2026-02-23 22:00:19.649154+00	2026-03-24 18:48:43.874271+00
75	fredtrading	1e11640f-3c6c-45f2-9654-0722b8d5c7f3	f	2026-02-23 22:03:53.18185+00	2026-03-24 18:48:43.874271+00
77	fredtrading	6ee3b404-e54c-4ad2-bc12-8b9ece9e7d8f	f	2026-02-23 22:18:19.23855+00	2026-03-24 18:48:43.874271+00
265	mubeen	f5f80e2f-ad14-4d49-9e06-6bf877049924	f	2026-03-24 17:57:43.314112+00	2026-03-24 18:48:43.82537+00
267	billionaire_club	64e73ec5-6263-44eb-999b-ec8e9f93ad64	f	2026-03-24 17:57:43.342938+00	2026-03-24 18:48:43.851676+00
270	fredtrading	5798007c-3060-4575-90b8-65ec6390412b	f	2026-03-24 17:57:43.364951+00	2026-03-24 18:48:43.874271+00
115	fredtrading	1827c87e-9755-4cb1-a6ee-12fe0586d604	f	2026-03-24 15:25:04.12876+00	2026-03-24 18:48:43.874271+00
188	fredtrading	ed5306b1-d659-492f-960b-cd903b16b341	f	2026-03-24 16:26:08.761077+00	2026-03-24 18:48:43.874271+00
169	fredtrading	90575ff5-ba36-4765-b17c-22cd57ca1d1c	f	2026-03-24 15:29:15.723684+00	2026-03-24 18:48:43.874271+00
139	fredtrading	3ddf36ca-94ba-4f06-9bf4-e9118c4f6f7a	f	2026-03-24 15:26:57.733682+00	2026-03-24 18:48:43.874271+00
130	fredtrading	057df014-c743-4e1e-9483-213602c2b1a3	f	2026-03-24 15:25:34.180223+00	2026-03-24 18:48:43.874271+00
253	fredtrading	b7f68e49-aa4c-4ec2-a9c1-5a3c7a47e449	f	2026-03-24 17:57:29.124075+00	2026-03-24 18:48:43.874271+00
249	fredtrading	c528dc81-55a8-45ca-ac72-6115219be07d	f	2026-03-24 17:57:29.08202+00	2026-03-24 18:48:43.874271+00
250	fredtrading	f8573107-8e01-4b71-911e-3acf37d1fc0f	f	2026-03-24 17:57:29.091582+00	2026-03-24 18:48:43.874271+00
78	fredtrading	8e9d1ef2-8ad3-49e2-a5a8-03af7b8ecd8c	f	2026-02-23 22:18:19.241888+00	2026-03-24 18:48:43.874271+00
86	fredtrading	ace5b008-2b73-478b-9ec0-dbecc7743912	f	2026-02-23 22:19:31.245254+00	2026-03-24 18:48:43.874271+00
87	fredtrading	4c2fc7ae-3ce4-4482-b648-08bcf8e691df	f	2026-02-23 22:19:31.251255+00	2026-03-24 18:48:43.874271+00
182	fredtrading	8dfa4bef-4c5d-453c-9e12-4a14d9ab2eb0	f	2026-03-24 16:26:08.711363+00	2026-03-24 18:48:43.874271+00
203	fredtrading	1f58b1ba-66af-4054-9605-c4cc7d1149d4	f	2026-03-24 16:30:09.523696+00	2026-03-24 18:48:43.874271+00
258	fredtrading	71c4d0ce-7e85-4a55-a4f4-20d0cf7f00dc	f	2026-03-24 17:57:29.177762+00	2026-03-24 18:48:43.874271+00
66	fredtrading	7f8d54ff-4cd5-420f-a7e8-bb91013af615	f	2026-02-23 22:03:02.826812+00	2026-03-24 18:48:43.874271+00
1	fredtrading	0bf2975d-3c7f-4573-b6f2-97d4d6ae3f4a	f	2026-02-21 20:56:42.978919+00	2026-03-24 18:48:43.874271+00
266	billionaire_club	830679d2-835e-446d-a666-481102d33168	f	2026-03-24 17:57:43.341467+00	2026-03-24 18:48:43.851676+00
231	fredtrading	5d892f7c-6890-40f9-8aef-2a96ca1b3f91	f	2026-03-24 16:35:31.883996+00	2026-03-24 18:48:43.874271+00
140	fredtrading	9b370c0c-8066-4062-8239-3e30b53e82d7	f	2026-03-24 15:26:57.737331+00	2026-03-24 18:48:43.874271+00
232	fredtrading	774e6e4e-2384-4260-927e-206ecec4dc69	f	2026-03-24 16:35:31.892183+00	2026-03-24 18:48:43.874271+00
246	fredtrading	9f47d584-40da-4a4b-a289-a7926013327d	f	2026-03-24 17:25:54.29162+00	2026-03-24 18:48:43.874271+00
205	fredtrading	56606f9f-a668-4b9b-ab5d-f5035d248946	f	2026-03-24 16:30:09.547732+00	2026-03-24 18:48:43.874271+00
56	fredtrading	d4d9c22a-3d13-424f-971d-7173402c6cfe	f	2026-02-23 22:00:27.072189+00	2026-03-24 18:48:43.874271+00
240	fredtrading	7243e524-9646-44d1-b989-20e60a6704bd	f	2026-03-24 17:23:07.765403+00	2026-03-24 18:48:43.874271+00
229	fredtrading	496d5648-16da-4e15-adc6-cf9a606f360a	f	2026-03-24 16:35:16.118814+00	2026-03-24 18:48:43.874271+00
116	fredtrading	d03acc11-0e6f-42db-bfc0-666910db1241	f	2026-03-24 15:25:04.131979+00	2026-03-24 18:48:43.874271+00
223	fredtrading	7c4002aa-1887-45f2-83f2-95108699a5c1	f	2026-03-24 16:35:16.06618+00	2026-03-24 18:48:43.874271+00
\.


--
-- Data for Name: providers; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.providers (provider_id, code, name, created_at) FROM stdin;
37ec4081-d682-4161-ac3c-a74a8ca08043	fredtrading	Fredtrading	2026-02-21 17:53:51.49747+00
f3450050-6bbf-44e8-a4ac-3b5da4ab4981	billionaire_club	BILLIONAIRE CLUB	2026-02-21 17:53:51.49747+00
ef3da65d-dba5-4d0a-a66a-3b0c5f1afaf1	mubeen	Mubeen Trading	2026-02-21 17:53:51.49747+00
\.


--
-- Data for Name: risk_multipliers; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.risk_multipliers (provider, tag, multiplier, requires_approval) FROM stdin;
fredtrading	unknown	1.000	f
fredtrading	normal	1.000	f
fredtrading	half	0.500	f
fredtrading	tiny	0.250	t
fredtrading	high	1.000	t
billionaire_club	unknown	1.000	f
billionaire_club	normal	1.000	f
billionaire_club	half	0.500	f
billionaire_club	tiny	0.250	t
billionaire_club	high	1.000	t
mubeen	unknown	1.000	f
mubeen	normal	1.000	f
mubeen	half	0.500	f
mubeen	tiny	0.250	f
mubeen	high	1.000	t
\.


--
-- Data for Name: routing_decisions; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.routing_decisions (id, telegram_message_id, chat_id, provider_code, broker_account_id, decision, reason, message_ts, raw_meta, created_at, message_id, telegram_msg_pk) FROM stdin;
285	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:10:25.126023+00	{"message_id": 1771877425}	2026-02-23 20:10:25.126092+00	1771877425	d30b041f-6bf6-47c5-8d0c-560dd9d835d9
307	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:59:50.315869+00	{"message_id": 1771880390}	2026-02-23 20:59:50.315948+00	1771880390	2f7c53e9-a899-4673-a3f0-4b41d76711da
333	\N	222	fredtrading	61661b02-e4cd-4cd2-bb28-d359687960a2	ROUTED	\N	2026-03-24 15:23:59.887615+00	{"message_id": 1774365839}	2026-03-24 15:23:59.887297+00	1774365839	3811a070-5800-4e52-b7ff-8c8ea39f6edc
334	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:23:59.894367+00	{"message_id": 1774365839}	2026-03-24 15:23:59.894029+00	1774365839	48ef2a1f-b8b5-4449-b3d6-a846ced4f9c8
335	\N	444	fredtrading	ab0cfdea-463a-41c7-bb48-954b3979cc85	ROUTED	\N	2026-03-24 15:23:59.899117+00	{"message_id": 1774365839}	2026-03-24 15:23:59.898774+00	1774365839	3bc142f1-fe6e-4e54-be4d-a422798eb777
363	\N	222	fredtrading	77dc6c00-81c3-4f88-a6eb-7e089379e90b	ROUTED	\N	2026-03-24 15:27:21.487741+00	{"message_id": 1774366041}	2026-03-24 15:27:21.486299+00	1774366041	3516ce67-da82-4eed-a622-2c5dd17cd5a1
364	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:27:21.490903+00	{"message_id": 1774366041}	2026-03-24 15:27:21.489429+00	1774366041	be89e85e-c779-4cd4-9b55-cc1f89db0a40
365	\N	444	fredtrading	a38b8b83-1cd1-4740-a666-14b69baf7095	ROUTED	\N	2026-03-24 15:27:21.496029+00	{"message_id": 1774366041}	2026-03-24 15:27:21.494508+00	1774366041	34eb459d-fd39-4306-874c-87c83c88ab9a
393	\N	222	fredtrading	770cdb91-23a8-4a01-aa0f-5731af367fd0	ROUTED	\N	2026-03-24 16:29:46.842004+00	{"message_id": 1774369786}	2026-03-24 16:29:46.841728+00	1774369786	45d9c437-4217-43d0-b228-a3fe95483d65
394	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:29:46.845773+00	{"message_id": 1774369786}	2026-03-24 16:29:46.845669+00	1774369786	c52ca687-7794-4a2f-bb77-cee9a5e324c9
395	\N	444	fredtrading	53a484d9-0bd1-47be-9193-fdfdf1048286	ROUTED	\N	2026-03-24 16:29:46.851601+00	{"message_id": 1774369786}	2026-03-24 16:29:46.851238+00	1774369786	62ed87e3-301d-4a32-b2bd-235ab04b6e66
418	\N	222	fredtrading	23e51a78-2b52-4425-85aa-28665d43ee2c	ROUTED	\N	2026-03-24 17:57:43.358557+00	{"message_id": 1774375063}	2026-03-24 17:57:43.357961+00	1774375063	3ae69b34-6e5f-4d2c-bc4d-218803b64acd
433	\N	222	fredtrading	f91cbfb1-64be-4da0-ba41-c020e7afb031	ROUTED	\N	2026-03-24 18:27:02.425238+00	{"message_id": 1774376822}	2026-03-24 18:27:02.424683+00	1774376822	2f65f3e4-d0d2-47ed-8ab2-188408e3a995
288	1	999	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	\N	{}	2026-02-23 20:19:46.605669+00	1	\N
290	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:19:46.621436+00	{"message_id": 1771877986}	2026-02-23 20:19:46.621168+00	1771877986	5044c0c2-c88d-404c-8373-d891483ac883
311	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 22:00:27.332668+00	{"message_id": 1771884027}	2026-02-23 22:00:27.333381+00	1771884027	48adc8ec-e3bd-469a-894c-b8b327023add
338	\N	222	fredtrading	767fdf5a-fcec-4ee0-a8da-eaf8a748d297	ROUTED	\N	2026-03-24 15:24:18.233772+00	{"message_id": 1774365858}	2026-03-24 15:24:18.233358+00	1774365858	deed5561-76a5-4fb9-a7df-32aaa5087b15
339	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:24:18.237457+00	{"message_id": 1774365858}	2026-03-24 15:24:18.237053+00	1774365858	be393da5-f855-4dd4-90a7-2b80b163e6ef
340	\N	444	fredtrading	46fccc78-bcc5-49b4-8314-9bbf952b40f4	ROUTED	\N	2026-03-24 15:24:18.241976+00	{"message_id": 1774365858}	2026-03-24 15:24:18.241548+00	1774365858	351a7bc0-f6cf-4d48-9fc3-ed8170020aa4
368	\N	222	fredtrading	ecb520d6-79df-4657-b806-b52a0f3361db	ROUTED	\N	2026-03-24 15:28:12.634939+00	{"message_id": 1774366092}	2026-03-24 15:28:12.634089+00	1774366092	71c2e8b9-fc9d-4952-a612-391306fddabd
369	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:28:12.638361+00	{"message_id": 1774366092}	2026-03-24 15:28:12.637505+00	1774366092	b07e9927-0e9a-4a0a-a223-9df7f8e9bfe8
370	\N	444	fredtrading	9f79d8ba-1ee8-4e25-ad38-acf720dd555e	ROUTED	\N	2026-03-24 15:28:12.645002+00	{"message_id": 1774366092}	2026-03-24 15:28:12.644099+00	1774366092	90bc8208-6087-4919-a498-6d2a89260582
398	\N	222	fredtrading	8ba7fd9d-8982-42ba-83d2-d516a4894d29	ROUTED	\N	2026-03-24 16:30:09.540576+00	{"message_id": 1774369809}	2026-03-24 16:30:09.540017+00	1774369809	34318afb-9b3a-4931-a3ec-f2e7ae650a4d
399	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:30:09.545305+00	{"message_id": 1774369809}	2026-03-24 16:30:09.544692+00	1774369809	43482450-bf7c-4845-bf76-a9e6845ced3d
400	\N	444	fredtrading	56606f9f-a668-4b9b-ab5d-f5035d248946	ROUTED	\N	2026-03-24 16:30:09.550699+00	{"message_id": 1774369809}	2026-03-24 16:30:09.549986+00	1774369809	8211dfe9-6cdc-41b5-bc4d-7dfbf8ef43d1
419	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 17:57:43.361859+00	{"message_id": 1774375063}	2026-03-24 17:57:43.361328+00	1774375063	4dcf24a2-e735-4ac1-ba10-bd8d6e8a87cc
420	\N	444	fredtrading	5798007c-3060-4575-90b8-65ec6390412b	ROUTED	\N	2026-03-24 17:57:43.368675+00	{"message_id": 1774375063}	2026-03-24 17:57:43.36807+00	1774375063	e63b1e61-ca65-4fe2-88dc-01740cee4fc4
434	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 18:27:02.42842+00	{"message_id": 1774376822}	2026-03-24 18:27:02.42785+00	1774376822	adb4c9ad-2b6a-4bd2-b6b1-e3b284d971b2
435	\N	444	fredtrading	8708524d-c2f0-4ffe-81fa-88f89d5c84f1	ROUTED	\N	2026-03-24 18:27:02.433619+00	{"message_id": 1774376822}	2026-03-24 18:27:02.433012+00	1774376822	557c25a7-5c28-46ec-b020-414afe2b2f19
292	\N	-1002298510219	mubeen	7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7	ROUTED	\N	2026-02-23 20:22:54+00	{"message_id": 1946}	2026-02-23 20:22:54.622113+00	1946	bcc71cf1-e071-40eb-ab5e-a8b3d52ccf55
312	555	111	fredtrading	a7de8947-1b38-40bc-bc9a-1ac068b29342	ROUTED	\N	\N	{"x": 1}	2026-02-23 22:02:16.279627+00	555	\N
314	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 22:02:16.421884+00	{"message_id": 1771884136}	2026-02-23 22:02:16.422268+00	1771884136	90ffabae-5614-4aa1-befd-692924f6adf5
343	\N	222	fredtrading	722c2128-fd74-4f9d-886a-14bd27e5820a	ROUTED	\N	2026-03-24 15:25:04.177795+00	{"message_id": 1774365904}	2026-03-24 15:25:04.177519+00	1774365904	8fa3c929-3a7b-440a-b51a-79d9f68d9d9b
344	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:25:04.180858+00	{"message_id": 1774365904}	2026-03-24 15:25:04.18055+00	1774365904	1d15c3f5-d725-424f-b7f1-0f2ca601cd17
345	\N	444	fredtrading	f0f44996-9214-446a-ae82-47f8f77cfd17	ROUTED	\N	2026-03-24 15:25:04.185905+00	{"message_id": 1774365904}	2026-03-24 15:25:04.185558+00	1774365904	e023d667-46b2-45e1-b165-6559c8e7118b
373	\N	222	fredtrading	90575ff5-ba36-4765-b17c-22cd57ca1d1c	ROUTED	\N	2026-03-24 15:29:15.726703+00	{"message_id": 1774366155}	2026-03-24 15:29:15.7265+00	1774366155	0eb11e47-617d-40cd-a4da-89919ea06734
374	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:29:15.729878+00	{"message_id": 1774366155}	2026-03-24 15:29:15.729777+00	1774366155	b39e9ac1-7742-43d3-b95c-2cb389bfa77f
375	\N	444	fredtrading	088a6d01-3d06-479f-b27f-ca395f4393c8	ROUTED	\N	2026-03-24 15:29:15.735097+00	{"message_id": 1774366155}	2026-03-24 15:29:15.734839+00	1774366155	cce57b31-4dbb-49d7-b110-e401e40f198e
403	\N	222	fredtrading	08ee3072-13ca-4d3c-b510-466dd73faedf	ROUTED	\N	2026-03-24 16:30:44.639533+00	{"message_id": 1774369844}	2026-03-24 16:30:44.638832+00	1774369844	5f7d7126-8ff9-4a74-be82-ae8460fbfc9e
404	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:30:44.643431+00	{"message_id": 1774369844}	2026-03-24 16:30:44.642797+00	1774369844	1ab73268-08d4-48c0-b7e0-affde432da6d
405	\N	444	fredtrading	1749ab8a-1dc9-4d48-b381-c52f462cc2c7	ROUTED	\N	2026-03-24 16:30:44.648856+00	{"message_id": 1774369844}	2026-03-24 16:30:44.648243+00	1774369844	dbdcef20-553c-459b-a0c2-9f7e1e88ea8b
423	\N	222	fredtrading	5bb1722b-d6d1-482a-8f0d-3fca98385293	ROUTED	\N	2026-03-24 17:58:36.855096+00	{"message_id": 1774375116}	2026-03-24 17:58:36.854523+00	1774375116	a0a0c24c-d0f7-4b98-9a7c-0ca33068715f
438	\N	222	fredtrading	9d5a905c-f4ab-4ed6-a52e-6bedd6c05f5d	ROUTED	\N	2026-03-24 18:48:43.869383+00	{"message_id": 1774378123}	2026-03-24 18:48:43.868916+00	1774378123	6ae0fef2-6f92-4ac9-9a2a-3931d4944601
293	\N	-1001239815745	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:41:13+00	{"message_id": 24856}	2026-02-23 20:41:26.146119+00	24856	052edaa1-317b-4d95-82e7-f045f530e077
309	\N	-1001239815745	fredtrading	0bf2975d-3c7f-4573-b6f2-97d4d6ae3f4a	ROUTED	\N	2026-02-23 21:10:09+00	{"message_id": 24857}	2026-02-23 21:10:29.055184+00	24857	af964d6b-08b9-472b-92bb-f283eb0e7d6e
317	\N	222	fredtrading	97b22529-ff06-4788-943c-789be1a53fd0	ROUTED	\N	2026-02-23 22:03:02.859853+00	{"message_id": 1771884182}	2026-02-23 22:03:02.859514+00	1771884182	0bcdaa7b-06b2-42c5-8762-bbcab03e4f6e
318	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 22:03:02.865904+00	{"message_id": 1771884182}	2026-02-23 22:03:02.865639+00	1771884182	043c4ec3-0ade-424a-a137-e940a0b37e22
319	\N	444	fredtrading	6444cf0b-293f-4905-a8c6-e14e14485672	ROUTED	\N	2026-02-23 22:03:02.873749+00	{"message_id": 1771884182}	2026-02-23 22:03:02.873316+00	1771884182	2c5bb2a3-fbfe-433e-b12e-328dcf16d632
330	\N	-1001239815745	fredtrading	5b1f0c8f-2538-4ad7-9189-d9f9813ea968	ROUTED	\N	2026-02-23 22:56:04+00	{"message_id": 24858}	2026-02-23 22:58:50.274632+00	24858	f2fd2d13-1089-40cc-a7d3-b43d116fdd56
348	\N	222	fredtrading	c0bb1266-fd27-4b8c-b57f-edd6bd745372	ROUTED	\N	2026-03-24 15:25:34.174462+00	{"message_id": 1774365934}	2026-03-24 15:25:34.173743+00	1774365934	7b0648c0-1200-4d1b-86b0-ebcb1d952a80
349	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:25:34.178492+00	{"message_id": 1774365934}	2026-03-24 15:25:34.177615+00	1774365934	b206ff12-e395-4dc6-9de5-610e8b284b4e
350	\N	444	fredtrading	057df014-c743-4e1e-9483-213602c2b1a3	ROUTED	\N	2026-03-24 15:25:34.18361+00	{"message_id": 1774365934}	2026-03-24 15:25:34.182767+00	1774365934	909e35e1-14d3-4070-a4f0-8bb4f6fbe2aa
378	\N	222	fredtrading	c1609da7-a45c-4137-84c7-72a1a3b74784	ROUTED	\N	2026-03-24 16:06:05.993059+00	{"message_id": 1774368365}	2026-03-24 16:06:05.992562+00	1774368365	7517b929-4831-4b19-b734-cbffdd970ada
379	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:06:05.997387+00	{"message_id": 1774368365}	2026-03-24 16:06:05.996867+00	1774368365	abce0e79-0c51-44dd-9fcf-9df99700e191
380	\N	444	fredtrading	5eb0956c-6479-4916-aae3-c0fbb47f3387	ROUTED	\N	2026-03-24 16:06:06.004041+00	{"message_id": 1774368366}	2026-03-24 16:06:06.00351+00	1774368366	9756fcef-795f-45c8-974a-0b5e1ed25acc
408	\N	222	fredtrading	496d5648-16da-4e15-adc6-cf9a606f360a	ROUTED	\N	2026-03-24 16:35:16.122536+00	{"message_id": 1774370116}	2026-03-24 16:35:16.121934+00	1774370116	f9d65699-8e23-4d17-88ff-0367beea7931
409	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:35:16.126716+00	{"message_id": 1774370116}	2026-03-24 16:35:16.125976+00	1774370116	87203eab-3546-42d1-a786-5f41990d9f24
410	\N	444	fredtrading	482c4614-2fb8-4861-b664-6bb4019ce4fc	ROUTED	\N	2026-03-24 16:35:16.132789+00	{"message_id": 1774370116}	2026-03-24 16:35:16.131963+00	1774370116	860f9956-915f-43da-8e31-b0e333ab87f0
424	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 17:58:36.858889+00	{"message_id": 1774375116}	2026-03-24 17:58:36.858281+00	1774375116	815ca4d1-aa55-4779-a054-7532751ac145
425	\N	444	fredtrading	75c9d5cf-960c-41dd-9c4e-0915cb029d54	ROUTED	\N	2026-03-24 17:58:36.865693+00	{"message_id": 1774375116}	2026-03-24 17:58:36.865045+00	1774375116	08672811-ed1c-4c26-b060-c2b40bc3da47
439	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 18:48:43.872514+00	{"message_id": 1774378123}	2026-03-24 18:48:43.872049+00	1774378123	6333620e-2f97-439f-b903-6c2e06f09a7d
440	\N	444	fredtrading	fef40035-9de0-4692-b8fe-e676a491cdf5	ROUTED	\N	2026-03-24 18:48:43.877057+00	{"message_id": 1774378123}	2026-03-24 18:48:43.876576+00	1774378123	cb6ab049-b06e-4c10-9d96-c8e7c2619ed3
297	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:45:46.771109+00	{"message_id": 1771879546}	2026-02-23 20:45:46.770777+00	1771879546	c6dd236b-f945-418b-8210-91f135e5ec0f
322	\N	222	fredtrading	1e11640f-3c6c-45f2-9654-0722b8d5c7f3	ROUTED	\N	2026-02-23 22:03:53.186062+00	{"message_id": 1771884233}	2026-02-23 22:03:53.186442+00	1771884233	f00b90d6-7483-4b69-9fd4-500c80b57fce
323	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 22:03:53.191645+00	{"message_id": 1771884233}	2026-02-23 22:03:53.191958+00	1771884233	0faa00a8-49b9-473c-99ae-4679bb43cbbe
324	\N	444	fredtrading	2591181b-cf8c-45d6-a54a-239a107cf80c	ROUTED	\N	2026-02-23 22:03:53.200504+00	{"message_id": 1771884233}	2026-02-23 22:03:53.20083+00	1771884233	20a9b9f7-69eb-41ea-9190-73e9c39e55e0
353	\N	222	fredtrading	868bfe6d-a6ab-4486-a00d-584239473c23	ROUTED	\N	2026-03-24 15:26:12.465464+00	{"message_id": 1774365972}	2026-03-24 15:26:12.464998+00	1774365972	2dd5bc62-2cb9-46ac-8e8a-c54b46ee2fe8
354	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:26:12.468701+00	{"message_id": 1774365972}	2026-03-24 15:26:12.468193+00	1774365972	dcbdd2e3-da30-4440-bd8b-c1db25b7bf68
355	\N	444	fredtrading	4b535fb2-9d80-4970-9bbb-3f005d77b4d2	ROUTED	\N	2026-03-24 15:26:12.473384+00	{"message_id": 1774365972}	2026-03-24 15:26:12.472834+00	1774365972	ebca87b0-d8ca-4daa-9c97-20c65008ba0f
383	\N	222	fredtrading	b00b2348-0c3f-46e6-a837-000954f4adc7	ROUTED	\N	2026-03-24 16:06:16.663165+00	{"message_id": 1774368376}	2026-03-24 16:06:16.662655+00	1774368376	3358ba55-6597-479d-9e15-b38ca7ee4b36
384	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:06:16.666399+00	{"message_id": 1774368376}	2026-03-24 16:06:16.665846+00	1774368376	44707700-af50-403e-be61-6fdcd089b0be
385	\N	444	fredtrading	fa32dae1-1864-4268-a568-f30df8a8cc59	ROUTED	\N	2026-03-24 16:06:16.671586+00	{"message_id": 1774368376}	2026-03-24 16:06:16.67106+00	1774368376	15b8157f-6b70-46b5-8695-0f0159fbc2b3
413	\N	222	fredtrading	71c4d0ce-7e85-4a55-a4f4-20d0cf7f00dc	ROUTED	\N	2026-03-24 17:57:29.18101+00	{"message_id": 1774375049}	2026-03-24 17:57:29.180466+00	1774375049	02b4d776-b231-4ce5-a1be-81fcbfb50452
428	\N	222	fredtrading	b74076a7-6bf6-439f-868f-e3fb2a5d43ef	ROUTED	\N	2026-03-24 18:14:41.2877+00	{"message_id": 1774376081}	2026-03-24 18:14:41.286416+00	1774376081	9714ccbe-cb87-4dd4-97b4-8995f0fc65db
38	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 18:43:32+00	{"message_id": 1854}	2026-02-23 18:43:32.185588+00	1854	78d32cbb-8882-4565-8bf3-169cec74285c
39	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:05:47+00	{"message_id": 1855}	2026-02-23 19:05:47.992461+00	1855	22845405-2dc0-48c8-8a54-79038ceab719
40	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:06:56+00	{"message_id": 1856}	2026-02-23 19:06:56.174177+00	1856	edaa5b0a-94b7-40ce-bf1c-44dd4d1bb73c
41	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:35+00	{"message_id": 1857}	2026-02-23 19:09:35.276979+00	1857	6cd43030-0c7b-4c78-a437-a26c3da5192b
42	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:35+00	{"message_id": 1858}	2026-02-23 19:09:36.072003+00	1858	23a61115-5375-4dda-b9a9-9b37e37ccb78
43	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:36+00	{"message_id": 1859}	2026-02-23 19:09:36.838617+00	1859	c2f4017f-a14a-44d7-b376-fedd26f615a1
44	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:37+00	{"message_id": 1860}	2026-02-23 19:09:37.509554+00	1860	2c384bf0-23a4-4268-97fd-81384bc38b2f
45	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:37+00	{"message_id": 1861}	2026-02-23 19:09:38.036819+00	1861	7daa3298-da1f-44bf-bae6-11eb3369f41f
46	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:38+00	{"message_id": 1862}	2026-02-23 19:09:38.635811+00	1862	12b2be2c-2068-4599-b2da-b185875fa1f0
47	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:38+00	{"message_id": 1863}	2026-02-23 19:09:39.186419+00	1863	2b692587-c0a6-46aa-b305-7e62ea69975c
48	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:42+00	{"message_id": 1864}	2026-02-23 19:09:43.026325+00	1864	49d2c0a2-7620-4d14-b91a-3dfb31ce2751
49	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:43+00	{"message_id": 1865}	2026-02-23 19:09:43.6113+00	1865	2ad2bc4f-5042-47fc-a0db-4d1cc22ac837
50	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:43+00	{"message_id": 1866}	2026-02-23 19:09:44.340955+00	1866	021f42a0-22d5-4c97-a527-4e02bc94d59d
51	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:09:44+00	{"message_id": 1867}	2026-02-23 19:10:05.198567+00	1867	e1f0e969-0f0e-4715-8717-dea48c33ebe2
52	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:05+00	{"message_id": 1868}	2026-02-23 19:10:05.905114+00	1868	5587c998-eaac-4ad2-a9a0-2353606118da
53	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:06+00	{"message_id": 1869}	2026-02-23 19:10:06.826891+00	1869	e68b88c3-9b6d-4f93-8765-352d4561950a
54	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:07+00	{"message_id": 1870}	2026-02-23 19:10:07.731056+00	1870	12855316-5585-47aa-afc3-5e170d060e00
55	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:08+00	{"message_id": 1871}	2026-02-23 19:10:08.461401+00	1871	5f9627df-f94e-4a3c-bee1-88cd07749933
56	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:08+00	{"message_id": 1872}	2026-02-23 19:10:09.63871+00	1872	483a65c3-7adb-418d-80d4-6d5fb8785b5e
57	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:12+00	{"message_id": 1873}	2026-02-23 19:10:13.370313+00	1873	b1ea3504-776f-44ef-8774-8e372d0ed403
58	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:13+00	{"message_id": 1874}	2026-02-23 19:10:14.393887+00	1874	7b3b52b5-9215-4c85-8bf5-3e0e7a97ed38
59	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:14+00	{"message_id": 1875}	2026-02-23 19:10:15.229863+00	1875	b3388b20-5b8d-4255-9e87-378fa5d82e4a
60	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:15+00	{"message_id": 1876}	2026-02-23 19:10:15.878636+00	1876	6be737ff-fdba-4474-8446-f88ee1db34e5
61	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:22+00	{"message_id": 1878}	2026-02-23 19:10:22.589413+00	1878	caf2c8c8-6b6f-47da-9e2a-8ca9b3ba670a
62	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:34+00	{"message_id": 1880}	2026-02-23 19:10:34.337884+00	1880	ff7a61e6-9d72-4604-8c80-d6273ca97b9c
63	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:22+00	{"message_id": 1879}	2026-02-23 19:10:35.650487+00	1879	f03ec4c8-7c8b-4bbe-994e-c9dda9cf5f17
64	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:16+00	{"message_id": 1877}	2026-02-23 19:10:35.937136+00	1877	34ef6467-f345-4904-bcd2-bbd09420d030
65	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:35+00	{"message_id": 1882}	2026-02-23 19:10:36.281032+00	1882	8ebc009f-f915-4be5-8e22-660db1ca8ade
66	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:34+00	{"message_id": 1881}	2026-02-23 19:10:38.304966+00	1881	c9402ed5-0cae-441b-93ea-874c8d1f90c8
67	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:39+00	{"message_id": 1884}	2026-02-23 19:10:39.636314+00	1884	25ad8279-9d94-4b0e-b531-3a5b3da45dde
68	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:39+00	{"message_id": 1883}	2026-02-23 19:10:39.813013+00	1883	5472ab13-9c0b-4b53-92c7-20507d91c894
69	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:39+00	{"message_id": 1885}	2026-02-23 19:10:39.900303+00	1885	c3f740c3-339e-47f0-9da8-c729f9f08312
70	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:43+00	{"message_id": 1888}	2026-02-23 19:10:43.555759+00	1888	ce67b3d5-4eab-4df2-91e4-258810aa4d9c
71	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:43+00	{"message_id": 1887}	2026-02-23 19:10:43.582921+00	1887	0f29eca9-dd50-4d69-bc8c-c4b376aaada7
72	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:42+00	{"message_id": 1886}	2026-02-23 19:10:43.611805+00	1886	c0ebee61-5983-440d-b240-362a923f07b6
73	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:43+00	{"message_id": 1890}	2026-02-23 19:11:06.37086+00	1890	f8d97188-2ee7-4f10-89bd-2befe51cb701
74	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:43+00	{"message_id": 1889}	2026-02-23 19:11:06.712143+00	1889	d539cf43-6652-42bb-a3c0-53e60c1e13dc
75	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:10:50+00	{"message_id": 1891}	2026-02-23 19:11:06.741011+00	1891	555832ac-2624-4ce1-8fcf-5efcfd08e5fe
76	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:06+00	{"message_id": 1892}	2026-02-23 19:11:07.133395+00	1892	c5cd2871-0e4d-4331-9441-7e125a7533f4
77	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:07+00	{"message_id": 1894}	2026-02-23 19:11:07.500718+00	1894	7a850fec-939a-46f5-9e4e-958b05e74cd2
78	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:06+00	{"message_id": 1893}	2026-02-23 19:11:07.715397+00	1893	54502088-d75b-4ddf-8172-c9ef98fc3fe7
79	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:07+00	{"message_id": 1895}	2026-02-23 19:11:07.908388+00	1895	8c2c6173-f3be-4c7e-bb96-211cab55acee
80	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:07+00	{"message_id": 1896}	2026-02-23 19:11:08.321574+00	1896	d11b7758-0476-472f-b682-8ac6b0d9c02b
81	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:12+00	{"message_id": 1898}	2026-02-23 19:11:12.675031+00	1898	f08ac49d-d398-4383-8a2f-2af35eb86bc9
82	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:12+00	{"message_id": 1897}	2026-02-23 19:11:12.897855+00	1897	ebc63378-caad-4917-a505-b8952a04ca1f
83	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:12+00	{"message_id": 1900}	2026-02-23 19:11:36.636116+00	1900	7c6b169b-32d9-4e5a-961f-3096a389220f
84	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:13+00	{"message_id": 1901}	2026-02-23 19:11:36.822243+00	1901	dbd1e312-6b99-415c-b8f7-241f376fc1b9
85	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:12+00	{"message_id": 1899}	2026-02-23 19:11:37.031438+00	1899	2b212dde-e0fd-4fd1-b395-ee5b5b01e1cb
86	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:36+00	{"message_id": 1902}	2026-02-23 19:11:37.30714+00	1902	8434892c-2161-4f70-b085-0e0c86708ab4
87	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:40+00	{"message_id": 1903}	2026-02-23 19:11:40.621238+00	1903	0e8eff68-9e88-451b-88f9-8a4365d1b97b
88	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:40+00	{"message_id": 1904}	2026-02-23 19:11:40.699066+00	1904	c0bb5ebb-dfe3-45b6-8877-f4f9898d5c4b
89	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:40+00	{"message_id": 1905}	2026-02-23 19:11:40.70535+00	1905	f2131b36-0718-49af-be8f-768c199081d2
90	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:43+00	{"message_id": 1908}	2026-02-23 19:11:44.407032+00	1908	3dc47912-181c-44c3-b43e-9baf2a3f466b
91	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:43+00	{"message_id": 1907}	2026-02-23 19:11:44.502523+00	1907	93551d51-37b6-4206-b51b-eef0e81e1a24
92	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:11:43+00	{"message_id": 1906}	2026-02-23 19:11:44.614608+00	1906	dd906016-30c7-4dad-8043-49e45b3648d9
93	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:12+00	{"message_id": 1912}	2026-02-23 19:12:12.373951+00	1912	85008fb9-66c9-4283-9b74-483c539fd9ee
94	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:12+00	{"message_id": 1913}	2026-02-23 19:12:13.125366+00	1913	90112d17-95be-4636-80b8-891a98c8dd29
95	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:13+00	{"message_id": 1914}	2026-02-23 19:12:13.734381+00	1914	e904f0cb-0d96-424f-a3ea-abf4efa1c430
96	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:13+00	{"message_id": 1915}	2026-02-23 19:12:14.79449+00	1915	aa5cd063-a2b3-4944-bae2-2869ea1be4aa
97	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:15+00	{"message_id": 1916}	2026-02-23 19:12:15.407512+00	1916	0cdf6b38-9a8f-4780-a1bd-f70690977bc5
98	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:15+00	{"message_id": 1917}	2026-02-23 19:12:16.447285+00	1917	7bb59c60-9452-4edf-8b65-1ec3c3feb514
99	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:16+00	{"message_id": 1918}	2026-02-23 19:12:17.068838+00	1918	54e81701-830b-4e85-b85c-13266ee10274
100	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:20+00	{"message_id": 1919}	2026-02-23 19:12:20.869835+00	1919	86ae6644-c0e3-4214-8c4f-5ca593a07182
101	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:21+00	{"message_id": 1920}	2026-02-23 19:12:21.574127+00	1920	5ac05f65-26cb-409b-a72c-e411b16744af
102	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:21+00	{"message_id": 1921}	2026-02-23 19:12:22.190578+00	1921	cd660daf-2402-4650-a187-928fd7b8c8c1
103	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:22+00	{"message_id": 1922}	2026-02-23 19:12:22.779778+00	1922	1aaf7eca-9406-445f-af9d-60e36b28f5cb
104	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:23+00	{"message_id": 1923}	2026-02-23 19:12:43.668223+00	1923	02c9fc7a-1e2b-4695-845f-990f89c79e85
105	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:43+00	{"message_id": 1924}	2026-02-23 19:12:44.253162+00	1924	dca7d7a9-f529-4955-a249-acd1167060dd
106	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:44+00	{"message_id": 1925}	2026-02-23 19:12:44.83727+00	1925	e4161099-1206-4614-9de9-24bfe1fa057e
107	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:45+00	{"message_id": 1926}	2026-02-23 19:12:45.630766+00	1926	39a1fc8e-e998-45d4-bf5b-976fa3783bd4
108	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:46+00	{"message_id": 1927}	2026-02-23 19:12:46.676388+00	1927	f28a9c79-c3b3-4a0c-8b45-71c2390bd2be
109	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:46+00	{"message_id": 1928}	2026-02-23 19:12:47.370271+00	1928	244220e9-84d5-4085-84f3-415c9f12be01
110	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:50+00	{"message_id": 1929}	2026-02-23 19:12:50.977785+00	1929	22f35980-1a09-4273-96c1-727e7c1addfb
111	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:51+00	{"message_id": 1930}	2026-02-23 19:12:51.518661+00	1930	02d34ad9-6dfb-4902-9d3f-79172cc965c5
112	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:51+00	{"message_id": 1931}	2026-02-23 19:12:52.151361+00	1931	37a600e4-37a5-4934-b42c-b07210c467ee
113	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:52+00	{"message_id": 1932}	2026-02-23 19:12:52.820294+00	1932	2edd0b57-8d62-4ca6-a352-e50a11835e6e
114	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:12:53+00	{"message_id": 1933}	2026-02-23 19:13:14.622587+00	1933	e0dadce9-898f-4d69-8034-3b833dd96404
115	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:14+00	{"message_id": 1934}	2026-02-23 19:13:15.243648+00	1934	f6d1e272-c05b-4808-b788-29a9ab3a8aa6
116	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:15+00	{"message_id": 1935}	2026-02-23 19:13:15.945536+00	1935	2e1bbf82-28a3-4191-bd35-934832bbfb93
117	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:16+00	{"message_id": 1936}	2026-02-23 19:13:16.734905+00	1936	6eeab5d7-e71e-4382-8333-f9c075fa6205
118	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:16+00	{"message_id": 1937}	2026-02-23 19:13:17.282182+00	1937	df077c0a-a142-42ce-b896-6ec4edf3465f
119	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:17+00	{"message_id": 1938}	2026-02-23 19:13:17.885057+00	1938	35c1f8d8-151c-4fcf-98d2-019f4b330739
120	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:21+00	{"message_id": 1939}	2026-02-23 19:13:21.648005+00	1939	14fbec49-9304-4ee9-9eaa-470d1059be9e
121	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:21+00	{"message_id": 1940}	2026-02-23 19:13:22.330403+00	1940	2845fadd-717e-4f90-8d41-be3954acc4b7
122	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:22+00	{"message_id": 1941}	2026-02-23 19:13:22.85291+00	1941	ef148598-a8d2-4765-9a62-1dd572c11937
123	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:23+00	{"message_id": 1942}	2026-02-23 19:13:23.501416+00	1942	0b0d8520-cf4f-45f0-b1cf-ab9feb667ff1
124	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:23+00	{"message_id": 1943}	2026-02-23 19:13:46.306863+00	1943	fcf4be42-8725-441d-9538-0456e74d2d13
125	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:46+00	{"message_id": 1944}	2026-02-23 19:13:47.064857+00	1944	809a4b1f-c623-4454-8c66-f7967b202f5b
126	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:47+00	{"message_id": 1945}	2026-02-23 19:13:47.92572+00	1945	511b836b-736a-4986-936b-a6824ee21a4c
127	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:48+00	{"message_id": 1946}	2026-02-23 19:13:48.679658+00	1946	2f028929-11a0-4926-bf69-3eb3cba05306
128	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:49+00	{"message_id": 1947}	2026-02-23 19:13:49.727725+00	1947	75671e3e-caaf-4705-a7ea-77fa77b19198
129	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:50+00	{"message_id": 1948}	2026-02-23 19:13:50.641205+00	1948	6dbe1210-085a-460a-891c-e6976d166aba
130	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:53+00	{"message_id": 1949}	2026-02-23 19:13:54.379557+00	1949	cf37b2e4-1e58-4c7b-877a-66cbb08781ab
131	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:54+00	{"message_id": 1950}	2026-02-23 19:13:55.029635+00	1950	98d2badd-5f08-4b3c-8231-b9fc8b1e6c43
132	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:55+00	{"message_id": 1951}	2026-02-23 19:13:55.613626+00	1951	c2547701-b202-4c68-9e66-4301d6bbaf1b
133	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:55+00	{"message_id": 1952}	2026-02-23 19:13:56.258795+00	1952	ad2c6d8b-94ad-4acf-863d-72be0d913894
134	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:13:56+00	{"message_id": 1953}	2026-02-23 19:14:17.191376+00	1953	28ed7ea9-453f-45ec-b9be-6274053d7cae
135	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:17+00	{"message_id": 1954}	2026-02-23 19:14:17.97088+00	1954	628a0ea9-7dfc-4731-b1d3-bb2665e76ce2
136	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:18+00	{"message_id": 1955}	2026-02-23 19:14:18.67464+00	1955	9ccbb154-e1be-46dd-adda-6e9d11f6b8ea
137	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:18+00	{"message_id": 1956}	2026-02-23 19:14:19.476299+00	1956	cf58876e-914e-4592-aa79-ac36724178bf
138	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:19+00	{"message_id": 1957}	2026-02-23 19:14:20.144731+00	1957	aecebb2a-b621-4f1f-83db-fb52d7c2157f
139	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:20+00	{"message_id": 1958}	2026-02-23 19:14:20.777712+00	1958	c94fb92d-8dfd-47cd-a894-01c22925b0e1
140	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:23+00	{"message_id": 1959}	2026-02-23 19:14:24.442935+00	1959	5498b0ad-44be-4440-a0f6-9ee00f8d1c90
141	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:24+00	{"message_id": 1960}	2026-02-23 19:14:25.307143+00	1960	50dcea71-4c22-4701-a102-9078b34e16b5
142	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:25+00	{"message_id": 1961}	2026-02-23 19:14:26.002394+00	1961	4ced1fc5-3521-48a7-b503-9073773a8e1f
143	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:26+00	{"message_id": 1962}	2026-02-23 19:14:26.673688+00	1962	815b5fe1-3152-4ef0-a20d-4122a07ac25e
144	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:26+00	{"message_id": 1963}	2026-02-23 19:14:47.622959+00	1963	27e2011d-ab38-4f76-b83e-c1940b93b60e
145	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:47+00	{"message_id": 1964}	2026-02-23 19:14:48.380904+00	1964	f124790c-4c00-4cf8-a358-737c0ba95298
146	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:48+00	{"message_id": 1965}	2026-02-23 19:14:49.033544+00	1965	ee014ba4-bc26-4c91-81ad-0e68c3a2d8ef
147	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:49+00	{"message_id": 1966}	2026-02-23 19:14:49.698819+00	1966	4d29ec2a-ccfb-4c43-be70-a05d821daa0d
148	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:49+00	{"message_id": 1967}	2026-02-23 19:14:50.47298+00	1967	6e2e7555-b338-46e4-8028-c9a6f05e97ba
149	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:50+00	{"message_id": 1968}	2026-02-23 19:14:51.188407+00	1968	23308dfb-2bef-4c07-93e5-4fd3f468d548
150	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:54+00	{"message_id": 1969}	2026-02-23 19:14:54.834879+00	1969	db47762a-b03a-4bea-bce7-876eb591e6dd
151	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:55+00	{"message_id": 1970}	2026-02-23 19:14:55.45764+00	1970	95905bda-855a-454a-9084-6503cba560b0
152	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:55+00	{"message_id": 1971}	2026-02-23 19:14:56.396401+00	1971	bba3ce32-2684-4cda-aeb2-752da1a0dc52
153	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:56+00	{"message_id": 1972}	2026-02-23 19:14:57.06241+00	1972	0ca1e8cd-acf5-4a31-896b-8daec2e0409a
154	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:14:57+00	{"message_id": 1973}	2026-02-23 19:15:18.950315+00	1973	b159ce12-f54b-4ef5-8765-824625abb4a7
155	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:19+00	{"message_id": 1974}	2026-02-23 19:15:19.66257+00	1974	100ae7d2-633f-4b67-9385-ab4c5dc42628
156	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:19+00	{"message_id": 1975}	2026-02-23 19:15:20.392347+00	1975	279d0651-7c28-4955-b6d1-5041e610abd7
157	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:20+00	{"message_id": 1976}	2026-02-23 19:15:20.936996+00	1976	82d5c938-ebf3-45e6-8249-cb3ed1cdb992
158	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:21+00	{"message_id": 1977}	2026-02-23 19:15:21.982283+00	1977	0371facb-41a6-49b2-b020-466427f03958
159	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:22+00	{"message_id": 1978}	2026-02-23 19:15:22.635085+00	1978	10340f1c-865a-442b-b777-b890417a54df
160	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:25+00	{"message_id": 1979}	2026-02-23 19:15:26.459193+00	1979	1b4ab366-9991-483b-b044-6dfa64b01076
161	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:26+00	{"message_id": 1980}	2026-02-23 19:15:27.365392+00	1980	17a18181-963f-4beb-bced-1df9bda0e59c
162	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:27+00	{"message_id": 1981}	2026-02-23 19:15:28.182479+00	1981	c746e7b5-2717-4d29-9e7d-35245266baab
163	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:28+00	{"message_id": 1982}	2026-02-23 19:15:28.849848+00	1982	0df8a006-dae8-425b-b891-b30deca35480
164	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:29+00	{"message_id": 1983}	2026-02-23 19:15:49.720218+00	1983	af969f5d-b5a6-45f2-9199-8d4c1863030c
165	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:49+00	{"message_id": 1984}	2026-02-23 19:15:50.382249+00	1984	a389124c-a90f-4954-be0b-8f2d3bec50fb
166	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:50+00	{"message_id": 1985}	2026-02-23 19:15:50.988218+00	1985	9bc97546-23fe-4eb3-9bcc-95ac7f05a564
167	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:51+00	{"message_id": 1986}	2026-02-23 19:15:51.750416+00	1986	e62c28b8-4443-475a-8eb0-2544941d39a6
168	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:51+00	{"message_id": 1987}	2026-02-23 19:15:52.420257+00	1987	efefde12-707e-421f-835e-c90901eeaecc
169	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:52+00	{"message_id": 1988}	2026-02-23 19:15:53.034597+00	1988	5cf1a51d-cc7c-4ff2-a1f7-02f3de44cc5b
170	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:56+00	{"message_id": 1989}	2026-02-23 19:15:56.719883+00	1989	fbc82904-df2e-42a0-b611-5ca79053d158
171	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:56+00	{"message_id": 1990}	2026-02-23 19:15:57.379024+00	1990	f54fdff5-3d04-4d0e-861d-411286a73769
172	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:57+00	{"message_id": 1991}	2026-02-23 19:15:58.172556+00	1991	9d0bdc17-dfc8-45a6-ac86-22db2ef985ee
173	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:58+00	{"message_id": 1992}	2026-02-23 19:15:58.910085+00	1992	b3cde7f7-7f1c-490e-8764-d446cfa76651
174	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:15:59+00	{"message_id": 1993}	2026-02-23 19:16:20.717047+00	1993	83731929-474b-427c-8a5e-7ff7cf2a4a85
175	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:20+00	{"message_id": 1994}	2026-02-23 19:16:21.389018+00	1994	95b6f110-e484-4948-8ce4-89482c81904c
176	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:21+00	{"message_id": 1995}	2026-02-23 19:16:22.227171+00	1995	ece1ec3d-e465-4bce-b6ad-452e5d1d4540
177	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:22+00	{"message_id": 1996}	2026-02-23 19:16:22.986934+00	1996	9b3c98e3-1280-40c9-83e3-5117ad4a1784
178	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:23+00	{"message_id": 1997}	2026-02-23 19:16:24.066171+00	1997	af0ed2ef-dc54-4672-86cd-617f0af641a3
179	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:24+00	{"message_id": 1998}	2026-02-23 19:16:24.847973+00	1998	707b400a-3af6-412a-8709-2801805ca2ff
180	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:28+00	{"message_id": 1999}	2026-02-23 19:16:28.557855+00	1999	6c151b24-937f-4e23-a19a-165ed5d846ca
181	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:28+00	{"message_id": 2000}	2026-02-23 19:16:29.302206+00	2000	7cd9f02b-173a-416a-9b49-a3ff9bcfb001
182	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:29+00	{"message_id": 2001}	2026-02-23 19:16:30.098029+00	2001	ee559fd4-d72b-4127-aa67-cab32ca1f2a3
183	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:30+00	{"message_id": 2002}	2026-02-23 19:16:30.682931+00	2002	5d44e7c7-f385-4afc-a1d5-7d5cf2d56b27
184	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:30+00	{"message_id": 2003}	2026-02-23 19:16:52.567829+00	2003	bcffce4f-fe3b-4e97-847d-63c6fbf20ae9
185	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:52+00	{"message_id": 2004}	2026-02-23 19:16:53.527308+00	2004	a42a7490-e652-4ab5-b287-8d469061c42b
186	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:53+00	{"message_id": 2005}	2026-02-23 19:16:54.303739+00	2005	cafbad6d-adb6-43de-93bf-c13792ba31df
187	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:54+00	{"message_id": 2006}	2026-02-23 19:16:54.837583+00	2006	2fbd35f0-84ff-4a21-a401-cf4a6680ba98
188	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:55+00	{"message_id": 2007}	2026-02-23 19:16:55.711864+00	2007	b665c338-2dfc-4321-b431-b04f9603c3f4
189	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:55+00	{"message_id": 2008}	2026-02-23 19:16:56.320074+00	2008	c088aa21-ba18-4b2b-b503-bd5eb188f3f8
190	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:16:59+00	{"message_id": 2009}	2026-02-23 19:16:59.964004+00	2009	277d6ac9-c1d5-4dea-b2c5-8ff54b3fab8f
191	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:00+00	{"message_id": 2010}	2026-02-23 19:17:00.51057+00	2010	d4c4eb91-ca74-4922-ad49-a267505768a8
192	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:00+00	{"message_id": 2011}	2026-02-23 19:17:01.121901+00	2011	bb337d13-66e0-438f-b79a-49c57a4d4897
193	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:01+00	{"message_id": 2012}	2026-02-23 19:17:01.798291+00	2012	fdc1fde1-d28d-4443-a0bd-f277801c91c2
194	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:02+00	{"message_id": 2013}	2026-02-23 19:17:23.721543+00	2013	826c7586-3359-4a77-a007-c0653081a1ec
195	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:23+00	{"message_id": 2014}	2026-02-23 19:17:24.35231+00	2014	de6bddbf-e819-4ae2-ac62-ab7b43f1cf0f
196	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:24+00	{"message_id": 2015}	2026-02-23 19:17:25.0736+00	2015	5ab143aa-207f-41f3-9e6f-afaaef03b636
197	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:25+00	{"message_id": 2016}	2026-02-23 19:17:25.693311+00	2016	5a11c1fd-ebf9-4937-a55e-3fcb2e978acc
198	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:25+00	{"message_id": 2017}	2026-02-23 19:17:26.235393+00	2017	65048d95-6fb8-450a-ba68-03457a38dda8
199	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:26+00	{"message_id": 2018}	2026-02-23 19:17:26.794561+00	2018	c16df9af-f3a5-42be-9870-47c56be70883
200	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:30+00	{"message_id": 2019}	2026-02-23 19:17:30.502385+00	2019	fa95fe51-0d5d-4883-b7c8-657b59301673
201	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:30+00	{"message_id": 2020}	2026-02-23 19:17:31.364808+00	2020	ba60e2c1-6e21-4965-ba21-5c90a880674c
202	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:31+00	{"message_id": 2021}	2026-02-23 19:17:32.067176+00	2021	968ae8a3-1b69-4f88-9f80-05d76b46ca61
203	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:32+00	{"message_id": 2022}	2026-02-23 19:17:32.638707+00	2022	91f00071-d538-4124-9dee-e586a6fbfefa
204	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:32+00	{"message_id": 2023}	2026-02-23 19:17:55.487457+00	2023	adf9fbcb-5bf9-4eff-9b0b-ddaef66314b3
205	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:55+00	{"message_id": 2024}	2026-02-23 19:17:56.105292+00	2024	61975c75-f50b-437b-bbff-a73287d02fe1
206	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:56+00	{"message_id": 2025}	2026-02-23 19:17:56.595466+00	2025	467be1e9-bc00-4388-b1c1-6635534f515c
207	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:56+00	{"message_id": 2026}	2026-02-23 19:17:57.207091+00	2026	dd11bb53-878c-41ab-bc9f-632bfeb3536c
208	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:57+00	{"message_id": 2027}	2026-02-23 19:17:57.817551+00	2027	faa7556b-e8f6-477c-b92d-8165e9f86fd6
209	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:17:58+00	{"message_id": 2028}	2026-02-23 19:17:58.501656+00	2028	95193feb-584b-42e1-b039-5ffc96ced5f0
210	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:01+00	{"message_id": 2029}	2026-02-23 19:18:02.372674+00	2029	4ec6e5ad-8900-4f13-a941-170904b2f677
211	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:02+00	{"message_id": 2030}	2026-02-23 19:18:03.20407+00	2030	fdc6895f-e3f6-480f-ac21-66fd109126dc
212	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:03+00	{"message_id": 2031}	2026-02-23 19:18:03.967252+00	2031	4692ffc0-a90a-495d-ad8d-4b6c3be89637
213	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:04+00	{"message_id": 2032}	2026-02-23 19:18:04.532386+00	2032	2b75dd81-0d37-43d4-891d-8c2908869714
214	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:04+00	{"message_id": 2033}	2026-02-23 19:18:27.226919+00	2033	261921ae-157c-4ade-9bd1-263c56063111
215	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:27+00	{"message_id": 2034}	2026-02-23 19:18:27.855656+00	2034	90c74a30-8a87-4b81-b0bf-81872fa20347
216	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:28+00	{"message_id": 2035}	2026-02-23 19:18:28.578886+00	2035	70f89e61-3a09-4999-a17b-538cef2c03b9
217	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:28+00	{"message_id": 2036}	2026-02-23 19:18:29.212514+00	2036	4ee94be8-a1e1-4114-a620-64aacb4c5ee2
218	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:29+00	{"message_id": 2037}	2026-02-23 19:18:29.876609+00	2037	2938c324-c59d-4b5a-afb4-ffa0d6f92e3f
219	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:30+00	{"message_id": 2038}	2026-02-23 19:18:30.691113+00	2038	080bf636-dc7a-4297-9e62-e6c76a625b2b
220	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:33+00	{"message_id": 2039}	2026-02-23 19:18:34.44306+00	2039	e38f40ba-452f-4955-9daf-c91f255e7373
221	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:34+00	{"message_id": 2040}	2026-02-23 19:18:35.219811+00	2040	c556692a-9979-4ebb-8006-5713053df18d
222	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:35+00	{"message_id": 2041}	2026-02-23 19:18:35.969113+00	2041	7965b242-7954-44f8-b82c-879cd3bf060c
223	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:36+00	{"message_id": 2042}	2026-02-23 19:18:36.622661+00	2042	0ea4deb0-12da-423d-aef9-4898766fefa7
224	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:36+00	{"message_id": 2043}	2026-02-23 19:18:58.472926+00	2043	aa9d07fb-f700-4e47-a49f-2aadf62a0d49
225	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:58+00	{"message_id": 2044}	2026-02-23 19:18:59.13107+00	2044	8e6d6325-ccc9-4876-a170-862866c378f0
226	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:18:59+00	{"message_id": 2045}	2026-02-23 19:18:59.774923+00	2045	81895277-5a1e-41b0-b397-a1199cf08a4b
227	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:00+00	{"message_id": 2046}	2026-02-23 19:19:00.802649+00	2046	1e005bcd-0be9-40d4-a732-4d9b1219cbd8
228	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:00+00	{"message_id": 2047}	2026-02-23 19:19:01.638967+00	2047	25afa4e7-67b9-42a8-ba20-885de29ba4a6
229	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:01+00	{"message_id": 2048}	2026-02-23 19:19:02.492896+00	2048	3d22d1ec-9e18-49ea-b2ac-94ac141a3848
230	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:05+00	{"message_id": 2049}	2026-02-23 19:19:06.26409+00	2049	a0cd2232-2fe1-4f19-905a-6c8bbdf298d0
231	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:06+00	{"message_id": 2050}	2026-02-23 19:19:07.101825+00	2050	c8882e34-1f3f-480e-9628-a5005fe44406
232	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:07+00	{"message_id": 2051}	2026-02-23 19:19:07.969137+00	2051	78960426-c895-4bfd-9a8f-97c74f0d8150
233	\N	-5211338635	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:19:08+00	{"message_id": 2052}	2026-02-23 19:19:08.578728+00	2052	52979eef-8220-49fd-8223-b51fa9eabe6e
234	\N	-1001239815745	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	ROUTED	\N	2026-02-23 19:45:23.028882+00	{"message_id": 1771875923}	2026-02-23 19:45:23.072698+00	1771875923	4a538009-4124-45c3-bd1f-17c01b914684
235	\N	-1001239815745	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:45:23.085398+00	{"message_id": 1771875924}	2026-02-23 19:45:23.085455+00	1771875924	6fcb3c42-6125-431c-b619-c6680b9687b6
236	\N	-1001239815745	fredtrading	\N	IGNORED_NO_ACCOUNT	Provider has no active mapped account	2026-02-23 19:45:23.092553+00	{"message_id": 1771875925}	2026-02-23 19:45:23.09335+00	1771875925	89eef95c-8747-4829-8d44-16c9dd137c26
237	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:53:52.875396+00	{"message_id": 1771876432}	2026-02-23 19:53:52.874342+00	1771876432	94570764-0520-4597-9eb2-3367a1abaf92
238	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:55:51.667188+00	{"message_id": 1771876551}	2026-02-23 19:55:51.667262+00	1771876551	4cbf6e16-406e-4974-991c-e84eef2dff21
240	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:57:06.938349+00	{"message_id": 1771876626}	2026-02-23 19:57:06.939236+00	1771876626	7596dab4-73a8-4759-84d2-61163f469593
245	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:58:13.687545+00	{"message_id": 1771876693}	2026-02-23 19:58:13.688087+00	1771876693	7802988a-451e-4751-9b5d-1e2884409f01
250	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:58:51.851478+00	{"message_id": 1771876731}	2026-02-23 19:58:51.85102+00	1771876731	463407b7-d66b-4533-830f-f77138490caa
255	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 19:59:21.862721+00	{"message_id": 1771876761}	2026-02-23 19:59:21.862519+00	1771876761	1e7fd268-2db6-4b6c-95e4-6b22cb185444
260	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:02:47.599524+00	{"message_id": 1771876967}	2026-02-23 20:02:47.599185+00	1771876967	9a7eae58-2237-4d7d-8824-139940ac9e9f
265	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:03:36.402179+00	{"message_id": 1771877016}	2026-02-23 20:03:36.39634+00	1771877016	8b02b29d-4348-4818-9426-92cd712e60a9
270	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:04:06.037024+00	{"message_id": 1771877046}	2026-02-23 20:04:06.036427+00	1771877046	f889549d-0e10-446a-8371-2086337d0223
275	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:05:49.776599+00	{"message_id": 1771877149}	2026-02-23 20:05:49.775618+00	1771877149	e7c17776-be2f-47f2-a6e5-31dae43e2dba
280	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:05:50.912874+00	{"message_id": 1771877150}	2026-02-23 20:05:50.911802+00	1771877150	8a1fe611-7bcb-4b39-bd75-99f5e56e7221
302	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 20:56:48.916204+00	{"message_id": 1771880208}	2026-02-23 20:56:48.916382+00	1771880208	bd3791e9-3019-44a6-a884-c891399db54f
327	\N	222	fredtrading	031f7c17-799d-4359-996d-7a76108c8240	ROUTED	\N	2026-02-23 22:19:39.836555+00	{"message_id": 1771885179}	2026-02-23 22:19:39.83655+00	1771885179	274d6844-c434-43a2-92fa-b0f5fcc98967
328	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-02-23 22:19:39.841725+00	{"message_id": 1771885179}	2026-02-23 22:19:39.841761+00	1771885179	1a0e0579-d1e7-45fe-a4f6-d9cc73bd0b75
329	\N	444	fredtrading	5b1f0c8f-2538-4ad7-9189-d9f9813ea968	ROUTED	\N	2026-02-23 22:19:39.851382+00	{"message_id": 1771885179}	2026-02-23 22:19:39.851322+00	1771885179	a29460a4-cd56-4a7f-9d29-5f7ad0d6d502
358	\N	222	fredtrading	39def072-f835-407d-8cb9-47ce205b1498	ROUTED	\N	2026-03-24 15:26:57.786596+00	{"message_id": 1774366017}	2026-03-24 15:26:57.786016+00	1774366017	cb0f94da-b627-447c-852d-bb72b7832fde
359	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 15:26:57.789827+00	{"message_id": 1774366017}	2026-03-24 15:26:57.789227+00	1774366017	5c636ce1-1848-42d1-a36f-7002495885fa
360	\N	444	fredtrading	c9ad4ebd-c9a8-4fe3-9e58-d654d0bb04b8	ROUTED	\N	2026-03-24 15:26:57.794803+00	{"message_id": 1774366017}	2026-03-24 15:26:57.794169+00	1774366017	4bbaccb4-8219-4d1e-9151-ddd5959f3bc2
388	\N	222	fredtrading	ed5306b1-d659-492f-960b-cd903b16b341	ROUTED	\N	2026-03-24 16:26:08.764685+00	{"message_id": 1774369568}	2026-03-24 16:26:08.763928+00	1774369568	4ba75d02-5c5b-4e54-9c6e-406334badc21
389	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 16:26:08.768201+00	{"message_id": 1774369568}	2026-03-24 16:26:08.7675+00	1774369568	a49655b3-9405-44a1-ae48-ca0e5ad067e6
390	\N	444	fredtrading	ce3d5d26-e900-4494-a462-4e5658a73d77	ROUTED	\N	2026-03-24 16:26:08.77365+00	{"message_id": 1774369568}	2026-03-24 16:26:08.772828+00	1774369568	63481efe-283e-40e8-b9a9-7456492ca0fc
414	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 17:57:29.184739+00	{"message_id": 1774375049}	2026-03-24 17:57:29.184278+00	1774375049	9d96e375-e24d-4828-b380-0003df3ee6fb
415	\N	444	fredtrading	80f9b07d-34cf-44a2-bb6f-239e8a2e502b	ROUTED	\N	2026-03-24 17:57:29.189829+00	{"message_id": 1774375049}	2026-03-24 17:57:29.189222+00	1774375049	e596f295-856e-42fa-949e-71b47ae68127
429	\N	333	\N	\N	IGNORED_UNKNOWN_CHAT	No chat_id → provider mapping	2026-03-24 18:14:41.291129+00	{"message_id": 1774376081}	2026-03-24 18:14:41.289839+00	1774376081	75270099-19f8-42ee-b930-638561ef6869
430	\N	444	fredtrading	199fe4c7-5182-48fd-917c-b22993e1d555	ROUTED	\N	2026-03-24 18:14:41.296776+00	{"message_id": 1774376081}	2026-03-24 18:14:41.295449+00	1774376081	f4d08306-d4c8-48be-880e-fbd58d296710
\.


--
-- Data for Name: symbol_mappings; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.symbol_mappings (mapping_id, broker, platform, canonical, broker_symbol, is_enabled, created_at) FROM stdin;
937af41c-dc71-4f39-8c06-632ed4c7a3fc	vantage	mt4	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
e94e5b76-34a8-4a09-85e0-c3cf81e08e16	vantage	mt4	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
cef09b42-6ca6-4b48-96ce-466cbb5692aa	vantage	mt4	DJ30	DJ30	t	2026-02-21 17:53:51.49747+00
e04628c4-5159-4caa-8efa-eea927230bf0	vantage	mt4	SP500	SP500	t	2026-02-21 17:53:51.49747+00
b7926654-63ae-4092-95bc-f010f1e38125	vantage	mt4	NAS100	NAS100	t	2026-02-21 17:53:51.49747+00
899a0ef5-e7dc-481c-b65c-827fe48e260c	vantage	mt4	USOIL	USOUSD	t	2026-02-21 17:53:51.49747+00
dd12aa7e-8eae-4280-9e14-f526c1fca378	vantage	mt4	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
a4951a9f-8634-4b0c-b3ee-ee0d3aa2e377	vantage	mt4	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
af2482a8-26de-482d-a4db-16ccaa66afb1	vantage	mt4	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
c922154d-6ecc-4046-9f64-d77850beb775	vantage	mt4	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
ca3c1fe3-f74d-46e4-a662-4bebe9f2a285	vantage	mt4	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
214644ba-3329-449f-b19e-fdedb71b41b7	vantage	mt4	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
aa8850d8-0c66-45dd-8542-5d855fd063ac	vantage	mt4	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
1688b8d6-1379-4fec-9513-b537873bc380	vantage	mt4	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
bb4c8afd-b0ec-43ce-8b3d-93c8d20df698	vantage	mt4	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
6533f18e-da65-458f-a970-30c8e3b6f1ee	vantage	mt4	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
f6dc3492-6623-4b5e-b44a-bd18d4ffbb50	vantage	mt4	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
54c25390-6f7f-4a0a-b5e8-35a0b327e9a9	vantage	mt4	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
39dce192-ef77-4a05-8188-c3fd80bc9430	vantage	mt4	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
6575727d-7f1f-4c52-b0c0-63c72d519a3e	vantage	mt4	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
86593f04-460b-4f31-b30a-988cd8114666	vantage	mt4	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
1fb384ef-5bcf-4b34-9e33-1eac87b18465	vantage	mt4	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
5b932103-ea8b-4229-95bc-e62f9a0f401b	vantage	mt4	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
2e20377b-7ca0-41ea-a3b0-6bf95d966e89	vantage	mt4	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
0d6a7c2d-5bff-45c4-a34a-aa5ef640c4a2	vantage	mt4	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
f42a400f-8616-420f-bf1f-44c9463cdee0	vantage	mt4	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
91b9dc7a-d758-428f-bd99-53141602f120	vantage	mt4	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
8f86e9ab-b28e-42e8-8583-13523b979444	vantage	mt4	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
d2813ffb-13b3-4007-8538-e3df77aa28f1	vantage	mt4	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
77029fec-cf55-436e-a51f-bba7d5b428e7	vantage	mt4	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
5b358963-07d3-4eb9-a451-fa2610c85a94	vantage	mt4	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
ec352ac0-2492-4509-a619-088c5c704523	vantage	mt4	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
8008ea18-8dd4-4df4-b0b5-1f24cef44355	vantage	mt4	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
ee5b8856-1478-4aed-b6a3-52366fa31e57	vantage	mt4	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
c0734c84-35ae-4b36-bc4b-f3361c0a4798	vantage	mt4	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
afffa646-838d-42d4-8ec3-d25b3e930410	vantage	mt4	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
92d1549e-2d34-4ee0-8923-e0bca21b53cc	vantage	mt4	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
062767ac-8657-49d4-ad91-83c3d29c0751	vantage	mt4	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
7f83dfe0-ade9-41e0-b2fc-f0595eb8d390	vantage	mt5	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
2db1c429-116f-411c-9fe1-dfac1d0db399	vantage	mt5	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
6ce1abc3-61b6-4aec-a34f-397ae9ee3cf2	vantage	mt5	DJ30	DJ30	t	2026-02-21 17:53:51.49747+00
a570df53-576a-4f16-a3e8-99b41fa529c5	vantage	mt5	SP500	SP500	t	2026-02-21 17:53:51.49747+00
50be6ea6-54e9-4daf-bf6e-830edc45603c	vantage	mt5	NAS100	NAS100	t	2026-02-21 17:53:51.49747+00
580cb783-0fdb-449b-a736-73ac31cc479a	vantage	mt5	USOIL	USOUSD	t	2026-02-21 17:53:51.49747+00
5027b5fc-42bd-4d0a-b271-81cd6a8318b0	vantage	mt5	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
399637d4-8630-40d9-8169-bffcc2ea5af3	vantage	mt5	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
ebd949fc-7ad2-4bda-a488-4c1189dbf5c8	vantage	mt5	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
28c22bcc-4753-468c-9c25-6de5ab536564	vantage	mt5	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
e90554a1-2ea3-4f76-b6eb-af0da181fbb0	vantage	mt5	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
a6bf88cb-22e5-4fba-bd25-35b27fbb40b0	vantage	mt5	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
032d6ac8-423d-4fc9-8472-3cf9d9a08c23	vantage	mt5	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
6a561ce8-e75d-4d59-9cc4-5f41965ea349	vantage	mt5	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
d42862fd-862a-49ee-a814-1b0097f7d4cb	vantage	mt5	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
54d69819-a0be-4b98-a232-4839217168ef	vantage	mt5	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
03182c67-4fb4-4145-9141-aef307f7cc6b	vantage	mt5	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
119a1ab2-989e-47c8-a538-86861ce11ab1	vantage	mt5	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
6f42bd1f-cd1f-4ae3-9bd2-f8def97e415a	vantage	mt5	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
b1a5767c-ec47-420c-8914-037d8055d9f7	vantage	mt5	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
197738d2-4f9b-446f-818d-d11d463289d5	vantage	mt5	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
67918ace-8d62-4509-9e5d-ee72b4fa57cc	vantage	mt5	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
d7a661ab-7e97-445b-b93b-ab099e6f1859	vantage	mt5	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
23a36c0c-fd3d-4b9e-8d18-3adc48bbaa7e	vantage	mt5	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
6d384a73-2175-4839-87dd-44a627cbc5bd	vantage	mt5	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
6d8b7b27-5aa6-42d9-b90f-552bdff30556	vantage	mt5	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
b0343c71-ef04-430e-88bb-c62acec95867	vantage	mt5	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
029f306b-950a-45dd-8497-224959baf84e	vantage	mt5	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
d8d0b8cf-344c-48a6-b903-fe8ea777e5bd	vantage	mt5	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
9f05df06-50fb-40c3-9422-7ee97147b5cc	vantage	mt5	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
aaa6233b-6af0-4f73-bf4f-ba3e843a5875	vantage	mt5	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
def9f84e-1d33-4c36-a8cc-19c1e16579c3	vantage	mt5	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
aff73bac-e625-460f-a74a-362de49bc75b	vantage	mt5	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
f22361ce-fe48-4b95-b81f-a8f57d9ffd38	vantage	mt5	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
f5d8078c-a1b1-4230-8a98-030764224df3	vantage	mt5	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
af8112f4-7319-49e8-8902-5b7f8053556e	vantage	mt5	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
06b34383-49c6-435e-98c0-fb25312f7e51	vantage	mt5	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
b947ccf1-165f-4cd7-827b-c1d2ae8abbc4	vantage	mt5	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
c580e3ed-2ae3-443d-850c-d0d5b3d2ea4a	ftmo	mt4	DJ30	US30.cash	t	2026-02-21 17:53:51.49747+00
af669e40-d0f3-4128-93ea-0e80554429e7	ftmo	mt4	SP500	US500.cash	t	2026-02-21 17:53:51.49747+00
7fa4b80e-557a-4fa4-9696-59e4814a88fb	ftmo	mt4	NAS100	US100.cash	t	2026-02-21 17:53:51.49747+00
88839c75-87dd-4e48-a603-9ae41529241c	ftmo	mt4	USOIL	USOIL.cash	t	2026-02-21 17:53:51.49747+00
d0193cfc-5210-4a8f-9bee-3b26002c0f13	ftmo	mt4	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
a1268cfc-a199-4356-b1bd-282c6857aad1	ftmo	mt4	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
d95069b4-1425-4d45-9a49-62f8ca184518	ftmo	mt4	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
89600418-e209-4a1d-9969-23428f707930	ftmo	mt4	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
f0f95e3e-54a0-40c6-9bfe-0b3d1ea0667a	ftmo	mt4	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
668c9f2c-6430-4fc9-a259-def58fa3d992	ftmo	mt4	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
510f1929-89a5-4b5a-88d9-10f8902a9e1f	ftmo	mt4	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
1deb81f9-93ae-46a2-9715-f2e0d99edce1	ftmo	mt4	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
f6734c96-fe89-47cb-84c7-f75e1f618d63	ftmo	mt4	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
80a6c9fb-aa70-47b7-85a0-c9b0f663ac5f	ftmo	mt4	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
28ebee49-9629-48e4-aa52-d7141d60328b	ftmo	mt4	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
2ab1430d-cc4b-4b7b-b2cd-cf96716b3983	ftmo	mt4	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
13f22d16-dcac-4d7d-ad9e-2a37d0541c59	ftmo	mt4	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
c18fee06-3b31-4dc0-8f7d-e9cc74473172	ftmo	mt4	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
a6055976-fbc5-4238-bf84-04e3a320e0dc	ftmo	mt4	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
8b2732ea-8539-4cbb-959a-0fcdc4c0c1b5	ftmo	mt4	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
9f6fbf7b-8f99-4457-9871-9cfd583a532d	ftmo	mt4	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
8eb6def4-cfa7-4a7e-a84a-78c767fa1f38	ftmo	mt4	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
2fe21826-e0cd-4ff6-aff9-1a1f955ee037	ftmo	mt4	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
e044c064-77c6-4c01-9cac-d131f4cfaaa9	ftmo	mt4	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
55bf7d07-4e4b-4f57-bb19-b81a5aac052b	ftmo	mt4	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
490e87f9-c272-47b3-9581-1da174ab82c2	ftmo	mt4	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
9cd47043-6017-43db-9b79-55ac7dca8bd0	ftmo	mt4	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
126982c1-26db-41cc-934c-56c89749aada	ftmo	mt4	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
16ff0db4-ae08-422b-8f59-89c87835cb73	ftmo	mt4	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
5914f337-5465-4bbd-a895-9d1d56b9b26d	ftmo	mt4	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
25be9d33-adc1-48ba-912e-34ad9c6c2323	ftmo	mt4	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
8d376c4c-387a-4a4a-8ce9-9224695b4c4d	ftmo	mt4	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
57d6ac4c-9c87-4874-9b9b-9df3d4e9897d	ftmo	mt4	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
0d7cdee1-11a8-45e7-bf61-45937e97dad2	ftmo	mt4	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
dc0d7beb-73db-403e-8cde-52166ecc18d7	ftmo	mt4	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
4930b9d7-c791-4106-9f75-5aa6a87f5526	ftmo	mt4	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
28a894b7-2857-440d-90d4-910596878ea3	ftmo	mt4	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
cbe06404-960b-4ef3-8ee6-675308710a47	ftmo	mt4	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
5884d58f-e097-4dce-a220-f0364e01a73b	ftmo	mt5	DJ30	US30.cash	t	2026-02-21 17:53:51.49747+00
6be5202f-4f8e-4a18-a737-45c42c338590	ftmo	mt5	SP500	US500.cash	t	2026-02-21 17:53:51.49747+00
a69cd82a-25b4-4236-b27b-e278b142b27b	ftmo	mt5	NAS100	US100.cash	t	2026-02-21 17:53:51.49747+00
b13d06ee-1218-4577-9789-eae71c1ee71e	ftmo	mt5	USOIL	USOIL.cash	t	2026-02-21 17:53:51.49747+00
b32eecd4-2162-4e45-906e-f91ad289ce7b	ftmo	mt5	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
813d173a-3ec1-43e7-9247-ee15196233cf	ftmo	mt5	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
075b4ebc-8f15-48dd-b15f-07e3c815116f	ftmo	mt5	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
10ae4b56-312b-4909-974f-d74203d3e60d	ftmo	mt5	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
6127d88b-e0c4-4940-b08d-1ed8a866ffd3	ftmo	mt5	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
1d6f0881-a198-4c2c-ab56-9ff4740e9f60	ftmo	mt5	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
0354d93a-14da-4204-9114-eabd4d2cddfb	ftmo	mt5	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
36d0cb99-4077-4411-80c6-a07e4cb9842d	ftmo	mt5	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
c31b916f-dc0f-4635-a3a3-735af11037e0	ftmo	mt5	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
213b3870-123a-4eee-a483-961995f5834e	ftmo	mt5	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
38065d70-0a2e-43ea-94e4-55898a3eeef1	ftmo	mt5	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
61be2b20-ce57-43d4-874e-223d32c7ed82	ftmo	mt5	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
442ae547-7a4a-49af-bedf-ef53d9739715	ftmo	mt5	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
8c6c87bd-9a9a-4bb5-8c39-615ee0168ca8	ftmo	mt5	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
38097cb4-3480-451d-a557-7fdc7e296eaf	ftmo	mt5	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
bc3f1315-7d20-459f-975a-82dd0cc3f9aa	ftmo	mt5	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
fc09d902-f5dd-4803-be2f-7704855c5856	ftmo	mt5	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
8e6945fe-c7fd-446c-b6e1-bba1d3b42175	ftmo	mt5	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
3217616a-533c-4afd-9d9c-a0efa6ea3013	ftmo	mt5	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
5adf2187-1854-422a-b66f-891bd8d16156	ftmo	mt5	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
d540c023-aaeb-4a11-9bdd-4dcdf361c954	ftmo	mt5	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
89b3f55c-edf4-4fef-aa28-1b7588325cac	ftmo	mt5	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
7da01334-ded4-43b6-b8eb-35bd4e6810d3	ftmo	mt5	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
4ce5d0f5-3ed8-4d95-8870-ecd52de88b55	ftmo	mt5	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
77151b5b-5364-45fe-98b7-383ec1a27cc9	ftmo	mt5	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
cc697aec-34c6-484b-8e99-5b36316053b0	ftmo	mt5	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
dc8fcdef-a189-4e18-9c62-ebaa9dcd2a1a	ftmo	mt5	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
e4291d0a-2cbf-4750-aeb6-3f0f37c33310	ftmo	mt5	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
7b1135fc-32c5-4a8e-b9e1-af22b77b200b	ftmo	mt5	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
def7f512-b48c-4979-b630-fb214ecb9c2c	ftmo	mt5	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
8aa4f516-eb23-4c17-b8cd-c655b23ffb69	ftmo	mt5	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
1a00aaf9-d6f9-4931-8930-0e2a49463b23	ftmo	mt5	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
7a3cc782-b60e-45bc-b309-81061b5fe338	ftmo	mt5	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
3a24cee3-afc7-4f9c-9ddb-0ec3e49390f1	ftmo	mt5	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
3d65071b-6a85-46ee-a3df-8d2df49048d6	traderscale	mt4	XAUUSD	XAUUSDc	t	2026-02-21 17:53:51.49747+00
04880011-92bc-4132-bd02-a1150830c4a3	traderscale	mt4	XAGUSD	XAGUSDc	t	2026-02-21 17:53:51.49747+00
4362b816-4b7c-459d-9949-e4241638762d	traderscale	mt4	DJ30	DJ30.c	t	2026-02-21 17:53:51.49747+00
ffcf1a28-6c02-4f11-aa6e-d14e0dcf56e0	traderscale	mt4	SP500	US500.c	t	2026-02-21 17:53:51.49747+00
62e5e890-7657-47c7-8b29-4f2fb43b6b16	traderscale	mt4	NAS100	USTEC.c	t	2026-02-21 17:53:51.49747+00
43e52ebb-4bf3-4d2b-9bba-da2c8c46d797	traderscale	mt4	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
3d8bfa95-11c3-4b95-a37d-91e680ae5d07	traderscale	mt4	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
06ad59d9-00bf-4edb-8419-939577853ba3	traderscale	mt4	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
040b55bc-da18-4984-a94c-184bfd1bcc1e	traderscale	mt4	EURUSD	EURUSDc	t	2026-02-21 17:53:51.49747+00
c63d05b4-835a-4e0b-beee-f1a9fd6c6005	traderscale	mt4	GBPUSD	GBPUSDc	t	2026-02-21 17:53:51.49747+00
50f30949-d80f-4b26-a072-faa7341dce68	traderscale	mt4	USDJPY	USDJPYc	t	2026-02-21 17:53:51.49747+00
b10dc8c1-debc-4c1d-8b59-d3f88f1a338b	traderscale	mt4	USDCHF	USDCHFc	t	2026-02-21 17:53:51.49747+00
87b97bf9-ade9-45ad-92a9-4a408d4a4b27	traderscale	mt4	USDCAD	USDCADc	t	2026-02-21 17:53:51.49747+00
890bdee7-90a9-4e48-95bb-708184c9add6	traderscale	mt4	AUDUSD	AUDUSDc	t	2026-02-21 17:53:51.49747+00
730bec7d-8228-44b4-8408-658d058edfdb	traderscale	mt4	NZDUSD	NZDUSDc	t	2026-02-21 17:53:51.49747+00
021e9c1f-6772-45d1-99f2-730a4491db0a	traderscale	mt4	AUDCAD	AUDCADc	t	2026-02-21 17:53:51.49747+00
62ce61f8-5817-4055-b49b-b7afd3fae3da	traderscale	mt4	AUDCHF	AUDCHFc	t	2026-02-21 17:53:51.49747+00
8fe8bae7-2b51-49e5-9ef2-4ad9d439ea64	traderscale	mt4	AUDJPY	AUDJPYc	t	2026-02-21 17:53:51.49747+00
441584bd-88d8-40a9-be71-720c76bc487d	traderscale	mt4	AUDNZD	AUDNZDc	t	2026-02-21 17:53:51.49747+00
455b66ff-f24f-4bfe-930e-ff115eadd3aa	traderscale	mt4	CADCHF	CADCHFc	t	2026-02-21 17:53:51.49747+00
9ef0dcad-3b5c-427f-abc0-b3601852156f	traderscale	mt4	CADJPY	CADJPYc	t	2026-02-21 17:53:51.49747+00
5859c744-a04f-4534-9578-ec912b4ea2e5	traderscale	mt4	CHFJPY	CHFJPYc	t	2026-02-21 17:53:51.49747+00
74ddc852-232a-4581-b3f0-2edadc27d4de	traderscale	mt4	EURAUD	EURAUDc	t	2026-02-21 17:53:51.49747+00
c191b094-47d1-485c-ba45-8161515fd998	traderscale	mt4	EURCAD	EURCADc	t	2026-02-21 17:53:51.49747+00
2e1af944-4091-4e34-903f-675e52016159	traderscale	mt4	EURCHF	EURCHFc	t	2026-02-21 17:53:51.49747+00
065682b6-e299-489d-b7e0-9964c305d0b3	traderscale	mt4	EURGBP	EURGBPc	t	2026-02-21 17:53:51.49747+00
106826fe-4ab9-4706-8abd-8e04a43f0549	traderscale	mt4	EURJPY	EURJPYc	t	2026-02-21 17:53:51.49747+00
c4e50b0e-57b3-4594-8e4d-7499a6d7da1e	traderscale	mt4	EURNZD	EURNZDc	t	2026-02-21 17:53:51.49747+00
d870371d-4595-4f4e-bdcf-ebcd19ad5c00	traderscale	mt4	GBPAUD	GBPAUDc	t	2026-02-21 17:53:51.49747+00
66641cd6-bea3-4d46-97b9-968a8406b651	traderscale	mt4	GBPCAD	GBPCADc	t	2026-02-21 17:53:51.49747+00
17e18737-1429-4623-ad2c-7cfceb36a45f	traderscale	mt4	GBPCHF	GBPCHFc	t	2026-02-21 17:53:51.49747+00
0cee10ae-0bcd-46e7-bc64-455f3501209a	traderscale	mt4	GBPJPY	GBPJPYc	t	2026-02-21 17:53:51.49747+00
e98ef2be-30bf-4893-a1e2-8f2744c121fc	traderscale	mt4	GBPNZD	GBPNZDc	t	2026-02-21 17:53:51.49747+00
a81cf33d-e8e0-4d7f-ac5d-ae8047aae0db	traderscale	mt4	NZDCAD	NZDCADc	t	2026-02-21 17:53:51.49747+00
bc47ab86-ee9f-440e-9e0b-4f7e2d919838	traderscale	mt4	NZDCHF	NZDCHFc	t	2026-02-21 17:53:51.49747+00
58e77e9a-3fd1-46dc-bc17-a41363d0e426	traderscale	mt4	NZDJPY	NZDJPYc	t	2026-02-21 17:53:51.49747+00
11d6c414-57f8-4326-8af8-e1012f9c9da4	traderscale	mt5	XAUUSD	XAUUSDc	t	2026-02-21 17:53:51.49747+00
9583225f-efa4-4bfb-9c25-30690af3be0c	traderscale	mt5	XAGUSD	XAGUSDc	t	2026-02-21 17:53:51.49747+00
df52f34f-7d77-4132-ad59-43179eb92633	traderscale	mt5	DJ30	DJ30.c	t	2026-02-21 17:53:51.49747+00
964dbad1-1639-4697-9f8b-a4391c178e68	traderscale	mt5	SP500	US500.c	t	2026-02-21 17:53:51.49747+00
57137867-6322-4916-90e9-c7536d8a12ce	traderscale	mt5	NAS100	USTEC.c	t	2026-02-21 17:53:51.49747+00
e110d5b1-341e-467f-9484-c5fee64c8052	traderscale	mt5	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
6c06a17e-04d0-45f8-844e-05246547a404	traderscale	mt5	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
381a5eb5-de90-4704-a906-e21986b52ad4	traderscale	mt5	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
c591e54d-0eb5-42da-9ef3-9a28c6f45db5	traderscale	mt5	EURUSD	EURUSDc	t	2026-02-21 17:53:51.49747+00
11c3a2e5-6de3-40b8-ba09-396f88101d9b	traderscale	mt5	GBPUSD	GBPUSDc	t	2026-02-21 17:53:51.49747+00
c26c50f8-fa3c-4648-b090-b8b317638863	traderscale	mt5	USDJPY	USDJPYc	t	2026-02-21 17:53:51.49747+00
df8e9924-980a-4f9b-8ba9-3ec36a433e12	traderscale	mt5	USDCHF	USDCHFc	t	2026-02-21 17:53:51.49747+00
e1a87cb9-7434-40aa-8fba-86f0e035f4b4	traderscale	mt5	USDCAD	USDCADc	t	2026-02-21 17:53:51.49747+00
cb0ca56c-c378-43b2-97c6-d8179e0e837e	traderscale	mt5	AUDUSD	AUDUSDc	t	2026-02-21 17:53:51.49747+00
1a4a60cd-80ab-4e90-90a4-146a6da89d13	traderscale	mt5	NZDUSD	NZDUSDc	t	2026-02-21 17:53:51.49747+00
61c156d2-c3a5-4487-89d5-bb8e4b2861c5	traderscale	mt5	AUDCAD	AUDCADc	t	2026-02-21 17:53:51.49747+00
e82e9c9f-2efb-40ee-a0d3-d838adfa25b7	traderscale	mt5	AUDCHF	AUDCHFc	t	2026-02-21 17:53:51.49747+00
37a4f858-975d-4011-af0f-796e5f8f16b0	traderscale	mt5	AUDJPY	AUDJPYc	t	2026-02-21 17:53:51.49747+00
53db9f4b-1bae-4e53-9bf1-ca27e84486f0	traderscale	mt5	AUDNZD	AUDNZDc	t	2026-02-21 17:53:51.49747+00
bda0c6ba-2409-4ec9-858d-cee26bfa7901	traderscale	mt5	CADCHF	CADCHFc	t	2026-02-21 17:53:51.49747+00
df41a973-3d70-4ded-bad7-3800a09db0b4	traderscale	mt5	CADJPY	CADJPYc	t	2026-02-21 17:53:51.49747+00
6193781c-9ce5-4d38-9603-8d9b29e3752b	traderscale	mt5	CHFJPY	CHFJPYc	t	2026-02-21 17:53:51.49747+00
8c28249f-d156-4412-afee-2619f4961af6	traderscale	mt5	EURAUD	EURAUDc	t	2026-02-21 17:53:51.49747+00
0421133f-9241-4ec4-959d-2f5f810c1fb2	traderscale	mt5	EURCAD	EURCADc	t	2026-02-21 17:53:51.49747+00
a793020c-a359-4782-99de-97d5a77540b1	traderscale	mt5	EURCHF	EURCHFc	t	2026-02-21 17:53:51.49747+00
9df033c0-115d-4cf7-ac85-738d1b8767da	traderscale	mt5	EURGBP	EURGBPc	t	2026-02-21 17:53:51.49747+00
d0d1c8dd-01b3-40c4-8909-5a82af6231c4	traderscale	mt5	EURJPY	EURJPYc	t	2026-02-21 17:53:51.49747+00
5e496956-090d-4f84-a28a-b22199971370	traderscale	mt5	EURNZD	EURNZDc	t	2026-02-21 17:53:51.49747+00
3d608c8b-99b7-4157-b2e8-be89a2b0b3ad	traderscale	mt5	GBPAUD	GBPAUDc	t	2026-02-21 17:53:51.49747+00
8dafdc3b-ebca-4e3d-9774-f0397e4de094	traderscale	mt5	GBPCAD	GBPCADc	t	2026-02-21 17:53:51.49747+00
cc626f31-b3ef-468c-84eb-dea8cfd3bf1a	traderscale	mt5	GBPCHF	GBPCHFc	t	2026-02-21 17:53:51.49747+00
eb8b3668-9a0a-4058-97a8-e433b56dbb39	traderscale	mt5	GBPJPY	GBPJPYc	t	2026-02-21 17:53:51.49747+00
22daa40c-026a-4359-a2a8-0130b59cd9f5	traderscale	mt5	GBPNZD	GBPNZDc	t	2026-02-21 17:53:51.49747+00
5b5b3f2a-d2da-4f46-8e96-8ea32603d5c0	traderscale	mt5	NZDCAD	NZDCADc	t	2026-02-21 17:53:51.49747+00
3d478328-93f1-444b-a82a-c2eecd3736ef	traderscale	mt5	NZDCHF	NZDCHFc	t	2026-02-21 17:53:51.49747+00
c2ba390e-44d2-4cbf-9007-1b407abcaef1	traderscale	mt5	NZDJPY	NZDJPYc	t	2026-02-21 17:53:51.49747+00
37feec36-4d52-4a86-b198-c4b3a831b5ca	fundednext	mt4	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
6a30f976-799a-4a23-a92c-84e932a06b72	fundednext	mt4	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
262b4545-1a4f-417f-8a04-3eeb3d358d41	fundednext	mt4	DJ30	US30	t	2026-02-21 17:53:51.49747+00
f51b89a3-ad98-47ca-961a-2b04f725bf46	fundednext	mt4	SP500	SPX500	t	2026-02-21 17:53:51.49747+00
b69a7ad4-721e-4c27-ab5a-02158d612331	fundednext	mt4	NAS100	NDX100	t	2026-02-21 17:53:51.49747+00
91dc851b-cb8a-4d41-b388-695719e096af	fundednext	mt4	USOIL	USOUSD	t	2026-02-21 17:53:51.49747+00
f48d6b19-4a1f-403b-8569-2c97bd89f99d	fundednext	mt4	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
864b6e85-6025-4c6a-89db-d00eff854adb	fundednext	mt4	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
115d1e44-29d5-4c5d-a8aa-b380877a025f	fundednext	mt4	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
9d48d1a8-3bc9-4b87-b484-351da4301bbb	fundednext	mt4	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
6794dafb-d41d-49a9-9840-129e83c0f5ba	fundednext	mt4	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
d634705b-b27e-4410-8bba-180b91375b55	fundednext	mt4	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
526f5f7e-e425-43f0-9224-243646a6bb7f	fundednext	mt4	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
8eead742-1ee3-4e08-bdb7-983f0367cdf7	fundednext	mt4	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
3b7c9ddc-74d0-4622-8d4d-f9c17811d930	fundednext	mt4	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
633e7d54-aa00-4b3d-9df5-732b699f6f98	fundednext	mt4	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
ad70b2e6-5ec2-4b24-8e12-3a0a577f2636	fundednext	mt4	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
ad46b08f-64bf-4a6f-815d-4cf49d2d8255	fundednext	mt4	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
cc94362d-675f-4ea6-87dc-9dd0324a6fce	fundednext	mt4	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
ba81cd9d-80c6-45c9-ad62-890c5c835c65	fundednext	mt4	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
9a4d4113-afbd-4415-89d3-5ce88d649491	fundednext	mt4	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
3153dab0-ff9f-41da-9a57-41708c89dd3b	fundednext	mt4	AUDSGD	AUDSGD	t	2026-02-21 17:53:51.49747+00
87c11653-c399-4a49-94cf-442191bf6a3d	fundednext	mt4	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
12fc654e-614b-46c4-80d7-ad9926259e31	fundednext	mt4	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
fd09adab-4add-4210-9349-536d4a61316e	fundednext	mt4	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
7a3f024a-13a7-49c8-814f-73ca707ca1cb	fundednext	mt4	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
61aa79b0-e8a8-4a4a-be45-aadc42a83c8d	fundednext	mt4	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
ea5d0339-cd50-486f-baf4-7392f3cf1d90	fundednext	mt4	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
5b92b12e-8626-499c-8ad5-1e213f29f9eb	fundednext	mt4	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
838f5331-98e0-477a-b6f6-3a9d8dd3b8af	fundednext	mt4	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
0886326b-8670-403c-ac00-c4c404d57597	fundednext	mt4	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
78d18499-fdfd-490b-926e-1d13a5f73fca	fundednext	mt4	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
e605668f-8210-45d0-8bae-39a797e9ddc5	fundednext	mt4	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
531d5f72-6a92-4d3f-aca0-eb5c80ace6b7	fundednext	mt4	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
007d27e7-1624-4699-bc93-e3812dd46675	fundednext	mt4	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
8315c991-6353-4492-acee-adf0ac659261	fundednext	mt4	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
8c282788-7b88-461b-a86e-eb52c5d97e31	fundednext	mt4	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
01ef5016-4d3d-4deb-9074-2184d6fb2802	fundednext	mt4	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
2f785755-570e-469c-adbf-d7d7f5c4f91a	fundednext	mt4	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
cb3672d2-1016-4290-a877-2ee38d6055be	fundednext	mt5	XAUUSD	XAUUSD	t	2026-02-21 17:53:51.49747+00
100ab41a-f5c4-4a98-899f-278a4c6ea5eb	fundednext	mt5	XAGUSD	XAGUSD	t	2026-02-21 17:53:51.49747+00
941ae1da-21ba-44dd-9eac-fa9136fdf62d	fundednext	mt5	DJ30	US30	t	2026-02-21 17:53:51.49747+00
a912d982-dce2-4507-b197-68641e5440be	fundednext	mt5	SP500	SPX500	t	2026-02-21 17:53:51.49747+00
c32b5d46-3904-4aa2-be0e-fd4b1406f9c4	fundednext	mt5	NAS100	NDX100	t	2026-02-21 17:53:51.49747+00
b3e2e1e2-dfc8-4cbd-9173-37eeddad3dc8	fundednext	mt5	USOIL	USOUSD	t	2026-02-21 17:53:51.49747+00
2b5b1e9e-9d98-477a-88b0-7d9964cd55a5	fundednext	mt5	BTCUSD	BTCUSD	t	2026-02-21 17:53:51.49747+00
9459cb2b-0cd5-45a7-9e61-d6ef0c6e723b	fundednext	mt5	ETHUSD	ETHUSD	t	2026-02-21 17:53:51.49747+00
7998a5e8-073d-4b81-92f5-228aa570234d	fundednext	mt5	XRPUSD	XRPUSD	t	2026-02-21 17:53:51.49747+00
01bfe584-97da-4b80-818a-f5a0897323b3	fundednext	mt5	SOLUSD	SOLUSD	t	2026-02-21 17:53:51.49747+00
36539fa8-db4f-4c06-91cb-095ecac703f1	fundednext	mt5	EURUSD	EURUSD	t	2026-02-21 17:53:51.49747+00
a2953c40-6097-4baa-b1fe-4150f6a3be5a	fundednext	mt5	GBPUSD	GBPUSD	t	2026-02-21 17:53:51.49747+00
136f170c-4c6a-432d-ae00-0be31e7c8b93	fundednext	mt5	USDJPY	USDJPY	t	2026-02-21 17:53:51.49747+00
fdb0ba03-0534-4f52-8e13-1e8b1541e88c	fundednext	mt5	USDCHF	USDCHF	t	2026-02-21 17:53:51.49747+00
f0353fc5-443c-4088-9200-0ee6f984fb77	fundednext	mt5	USDCAD	USDCAD	t	2026-02-21 17:53:51.49747+00
75e4a8fb-d2c4-4486-84e4-a6fe359f7f7c	fundednext	mt5	AUDUSD	AUDUSD	t	2026-02-21 17:53:51.49747+00
603d0471-6eca-46a1-9814-ab6267c2ac27	fundednext	mt5	NZDUSD	NZDUSD	t	2026-02-21 17:53:51.49747+00
becdecf2-14ab-49bd-854a-d5ce8803c652	fundednext	mt5	AUDCAD	AUDCAD	t	2026-02-21 17:53:51.49747+00
71494930-d6d3-46b6-b495-3370a3f8171a	fundednext	mt5	AUDCHF	AUDCHF	t	2026-02-21 17:53:51.49747+00
434dfb24-4357-46b1-baa7-e462df9f12ad	fundednext	mt5	AUDJPY	AUDJPY	t	2026-02-21 17:53:51.49747+00
f880f22c-691f-47ed-864b-5c373c517c2f	fundednext	mt5	AUDNZD	AUDNZD	t	2026-02-21 17:53:51.49747+00
ed6c27ef-a4d1-47da-8a46-72f4bd9bf58a	fundednext	mt5	AUDSGD	AUDSGD	t	2026-02-21 17:53:51.49747+00
fe399964-9ad0-4e3b-98f0-e7fca7dcce97	fundednext	mt5	CADCHF	CADCHF	t	2026-02-21 17:53:51.49747+00
234e8363-aead-4fde-8fba-bc577a346f76	fundednext	mt5	CADJPY	CADJPY	t	2026-02-21 17:53:51.49747+00
4365ced3-a2a1-45f9-9e5d-8e5883792576	fundednext	mt5	CHFJPY	CHFJPY	t	2026-02-21 17:53:51.49747+00
bbcb4ef8-c544-4809-b31e-3202ff918115	fundednext	mt5	EURAUD	EURAUD	t	2026-02-21 17:53:51.49747+00
8a7ccdcd-50e1-4b5c-85d1-56446fd653d0	fundednext	mt5	EURCAD	EURCAD	t	2026-02-21 17:53:51.49747+00
97c1cc54-1551-4acc-9bf7-3bf05fe840db	fundednext	mt5	EURCHF	EURCHF	t	2026-02-21 17:53:51.49747+00
f9d55a8f-681d-40e9-8017-95bc478e0b87	fundednext	mt5	EURGBP	EURGBP	t	2026-02-21 17:53:51.49747+00
034a0692-519d-4fc5-8353-9becb6627f17	fundednext	mt5	EURJPY	EURJPY	t	2026-02-21 17:53:51.49747+00
8c8dd3ca-11e4-4781-9b40-ffebb9de79ad	fundednext	mt5	EURNZD	EURNZD	t	2026-02-21 17:53:51.49747+00
3676e7ef-1f3a-47cc-9915-10d08384c130	fundednext	mt5	GBPAUD	GBPAUD	t	2026-02-21 17:53:51.49747+00
c1428949-df40-4657-bf4c-a7887382825a	fundednext	mt5	GBPCAD	GBPCAD	t	2026-02-21 17:53:51.49747+00
cda3d944-766d-41a4-a42c-a5c8692559e5	fundednext	mt5	GBPCHF	GBPCHF	t	2026-02-21 17:53:51.49747+00
1948194b-3d0a-4567-97bc-27aa1f22bbe0	fundednext	mt5	GBPJPY	GBPJPY	t	2026-02-21 17:53:51.49747+00
3274f371-4e19-4784-add9-15759de5bfdb	fundednext	mt5	GBPNZD	GBPNZD	t	2026-02-21 17:53:51.49747+00
2d9b8dbe-51c7-4cff-a388-bbc570e60533	fundednext	mt5	NZDCAD	NZDCAD	t	2026-02-21 17:53:51.49747+00
a26b7213-07eb-4ea5-acba-4d483b4e1fb6	fundednext	mt5	NZDCHF	NZDCHF	t	2026-02-21 17:53:51.49747+00
a67edf8d-fa9d-4d26-9f4b-fce3b237782a	fundednext	mt5	NZDJPY	NZDJPY	t	2026-02-21 17:53:51.49747+00
\.


--
-- Data for Name: symbols; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.symbols (symbol_id, canonical, asset_class, pip_size, meta, created_at) FROM stdin;
f9baa40a-2ca8-4e46-8c9e-467fbf897463	XAUUSD	metal	\N	{}	2026-02-21 17:53:51.49747+00
19758c5d-7fcf-410d-914e-b39706666144	XAGUSD	metal	\N	{}	2026-02-21 17:53:51.49747+00
193ff85f-e890-46c1-be97-605d3668ca37	DJ30	index	\N	{}	2026-02-21 17:53:51.49747+00
bcfac913-dfcb-4b3c-a522-06f45d4c4f98	SP500	index	\N	{}	2026-02-21 17:53:51.49747+00
b665d79a-c361-47b2-9fcc-7cae13783249	NAS100	index	\N	{}	2026-02-21 17:53:51.49747+00
0b5ad5d2-65e6-428b-ab8b-57a294300ba6	USOIL	oil	\N	{}	2026-02-21 17:53:51.49747+00
6d0337c2-d509-41a6-b5cc-a3bc963572b4	BTCUSD	crypto	\N	{}	2026-02-21 17:53:51.49747+00
45da57fc-747b-4467-9214-4941a13f97e0	ETHUSD	crypto	\N	{}	2026-02-21 17:53:51.49747+00
f7524a57-9929-40fc-98df-9136126630e2	XRPUSD	crypto	\N	{}	2026-02-21 17:53:51.49747+00
6a0a2fc0-f784-47fc-ae45-7048a339cc5d	SOLUSD	crypto	\N	{}	2026-02-21 17:53:51.49747+00
56c014f3-b254-4de6-bb70-5c5155d0541c	EURUSD	fx	\N	{}	2026-02-21 17:53:51.49747+00
d1840386-8cdb-4fdc-826b-6eeb57787fe5	GBPUSD	fx	\N	{}	2026-02-21 17:53:51.49747+00
f86d8969-dc6f-445f-8451-6076d1cc5de6	USDJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
0bb672bd-11da-487d-8970-ddb933355209	USDCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
c5885e32-39dd-4c5d-802e-8d8c3d791ff1	USDCAD	fx	\N	{}	2026-02-21 17:53:51.49747+00
5b7f6bb9-f069-4951-99ed-ec48ac189cc7	AUDUSD	fx	\N	{}	2026-02-21 17:53:51.49747+00
71e77c19-f31e-41c1-a156-2572b9d30e77	NZDUSD	fx	\N	{}	2026-02-21 17:53:51.49747+00
6c406eb4-7e3e-48f6-aed0-0a9c7ac175f7	AUDCAD	fx	\N	{}	2026-02-21 17:53:51.49747+00
f6e788b3-d75b-4dbd-9273-c9165e19007b	AUDCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
8663d941-fccb-43f8-b5f2-6cab0402c93a	AUDJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
6a31217f-34c4-4a28-94d7-ff45fe64cdc0	AUDNZD	fx	\N	{}	2026-02-21 17:53:51.49747+00
92315148-c74f-4c99-8fdc-2fbc4462370f	AUDSGD	fx	\N	{}	2026-02-21 17:53:51.49747+00
54378d10-293b-428e-968f-9ae40e8c461d	CADCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
57a04ea1-12db-4a63-8318-b398215383d8	CADJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
fd9a4b65-833d-45fa-a149-e999e8bcc374	CHFJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
e668c999-5f08-4099-a167-ae0f83fd8891	EURAUD	fx	\N	{}	2026-02-21 17:53:51.49747+00
63063069-b83c-4fa9-a66e-b814f7e68e3a	EURCAD	fx	\N	{}	2026-02-21 17:53:51.49747+00
a9e0b1f3-b7fc-4861-8d78-07d62259e98f	EURCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
778c860b-0a6d-4748-9470-d7893739b8b0	EURGBP	fx	\N	{}	2026-02-21 17:53:51.49747+00
b8bd4ed3-5e1e-45a0-982f-c2f4fc1bebc9	EURJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
9f4cb514-5962-4b0e-ad6e-d524cbf004e4	EURNZD	fx	\N	{}	2026-02-21 17:53:51.49747+00
3e20b83d-6fef-4510-a2c2-9705dfcec167	GBPAUD	fx	\N	{}	2026-02-21 17:53:51.49747+00
d8a590c6-3bc6-4951-ac8f-73696211ba14	GBPCAD	fx	\N	{}	2026-02-21 17:53:51.49747+00
31da6c3f-d1fe-4eab-aa49-5b9734d7fcfd	GBPCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
0f0a0617-cca4-47de-94f9-0dfca469c9c8	GBPJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
1c0a6d0c-68cd-41a0-bb8b-892b46f66ca6	GBPNZD	fx	\N	{}	2026-02-21 17:53:51.49747+00
1f433638-bc5a-4f85-a990-cc8914a386d0	NZDCAD	fx	\N	{}	2026-02-21 17:53:51.49747+00
d56e4d49-9abe-4928-94c4-3f8fcb9e4ce7	NZDCHF	fx	\N	{}	2026-02-21 17:53:51.49747+00
0956de5d-b4f9-4f45-b5cd-0ecb2449548b	NZDJPY	fx	\N	{}	2026-02-21 17:53:51.49747+00
\.


--
-- Data for Name: telegram_chats; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.telegram_chats (chat_id, title, username, provider_code, channel_kind, is_control_chat, created_at, updated_at) FROM stdin;
8000024556310	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 17:58:53.613575+00	2026-03-24 17:58:53.613575+00
8000061825860	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:05:11.190799+00	2026-03-24 18:05:11.190799+00
8000002282325	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:05:11.2052+00	2026-03-24 18:05:11.2052+00
8000064108185	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:12:08.095555+00	2026-03-24 18:12:08.095555+00
8000002456263	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:14:41.142985+00	2026-03-24 18:14:41.142985+00
-1001239815745	Fredtrading - VIP - Main channel	\N	billionaire_club	mixed	f	2026-02-21 21:00:39.999869+00	2026-02-23 22:58:50.274632+00
8000080912930	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 17:56:09.899268+00	2026-03-24 17:56:09.899268+00
-1001234567890	Test	test	\N	mixed	f	2026-02-23 19:53:52.73606+00	2026-02-23 20:10:25.088521+00
8000004564650	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:21:46.745636+00	2026-03-24 18:21:46.745636+00
8000025827745	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:26:55.45374+00	2026-03-24 18:26:55.45374+00
8000013194395	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:27:02.311575+00	2026-03-24 18:27:02.311575+00
-1002467468850	\N	\N	billionaire_club	mixed	f	2026-02-21 21:00:39.998947+00	2026-02-21 21:00:39.998947+00
-1002997989063	\N	\N	billionaire_club	mixed	f	2026-02-21 21:00:39.998947+00	2026-02-21 21:00:39.998947+00
-1002208969496	\N	\N	fredtrading	mixed	f	2026-02-21 21:00:39.999869+00	2026-02-21 21:00:39.999869+00
-1001979286278	\N	\N	fredtrading	mixed	f	2026-02-21 21:00:39.999869+00	2026-02-21 21:00:39.999869+00
-1002808934766	\N	\N	mubeen	mixed	f	2026-02-21 21:00:40.000163+00	2026-02-21 21:00:40.000163+00
-1003254187278	\N	\N	billionaire_club	mixed	f	2026-02-21 21:00:39.998947+00	2026-02-21 21:00:39.998947+00
8000049738107	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 17:57:43.252651+00	2026-03-24 17:57:43.252651+00
-1005211338635	Control Chat	\N	\N	mixed	t	2026-03-24 18:48:27.941878+00	2026-03-24 18:48:27.941878+00
8000096625570	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:48:39.237329+00	2026-03-24 18:48:39.237329+00
777001	\N	\N	fredtrading	mixed	f	2026-02-23 22:00:27.051252+00	2026-03-24 18:48:43.69237+00
777002	\N	\N	\N	mixed	f	2026-02-23 20:19:46.590316+00	2026-03-24 18:48:43.696549+00
8000082882460	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 18:48:43.764923+00	2026-03-24 18:48:43.764923+00
-5211338635	Trade Bot Control	\N	\N	mixed	t	2026-02-21 19:16:43.978196+00	2026-02-23 21:02:37.996894+00
8000029777593	approval-seed-mubeen	\N	mubeen	mixed	f	2026-03-24 17:58:36.723571+00	2026-03-24 17:58:36.723571+00
111	\N	\N	fredtrading	mixed	f	2026-02-23 22:02:16.274448+00	2026-03-24 18:48:43.858297+00
222	test	\N	fredtrading	mixed	f	2026-02-23 22:03:02.855348+00	2026-03-24 18:48:43.868916+00
333	test	\N	\N	mixed	f	2026-02-23 19:53:52.874342+00	2026-03-24 18:48:43.872049+00
444	test	\N	fredtrading	mixed	f	2026-02-23 22:03:02.869797+00	2026-03-24 18:48:43.87867+00
-1002298510219	Mubeen Trading	mubeentrading	mubeen	mixed	f	2026-02-21 21:00:40.000163+00	2026-02-23 20:23:06.831192+00
8000045733158	approval-seed-mubeen	\N	mubeen	mixed	f	2026-04-03 20:18:21.879648+00	2026-04-03 20:18:21.879648+00
8000037150545	approval-seed-mubeen	\N	mubeen	mixed	f	2026-04-03 20:20:09.424914+00	2026-04-03 20:20:09.424914+00
\.


--
-- Data for Name: telegram_messages; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.telegram_messages (msg_pk, chat_id, message_id, sender_id, sent_at, text, raw_json, is_edited, edited_at, created_at) FROM stdin;
89bb1428-75f3-4f75-8a5a-794a7de83265	-5211338635	108	7622982526	2026-02-21 19:16:43+00	Hey	{"_": "Message", "id": 108, "out": false, "date": "2026-02-21 19:16:43+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "Hey", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 19:16:43.982833+00
da0c51b2-952a-4255-9254-de69549cbb72	-5211338635	109	8432659358	2026-02-21 19:40:03+00	🧪 Test Approval Card\n\nThis is a Milestone 1 wiring test.\nPress a button to verify callback handling + DB enqueue.	{"_": "Message", "id": 109, "out": true, "date": "2026-02-21 19:40:03+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🧪 Test Approval Card\\n\\nThis is a Milestone 1 wiring test.\\nPress a button to verify callback handling + DB enqueue.", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 18, "offset": 3}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": {"_": "ReplyInlineMarkup", "rows": [{"_": "KeyboardButtonRow", "buttons": [{"_": "KeyboardButtonCallback", "data": "b'approve'", "text": "✅ Approve", "requires_password": false}, {"_": "KeyboardButtonCallback", "data": "b'reject'", "text": "❌ Reject", "requires_password": false}, {"_": "KeyboardButtonCallback", "data": "b'snooze'", "text": "😴 Snooze", "requires_password": false}]}]}, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 19:40:03.984736+00
37cf73bc-80d3-461c-8767-101cf27f6280	-5211338635	110	8432659358	2026-02-21 19:40:19+00	✅ Callback received: approve (enqueued)	{"_": "Message", "id": 110, "out": true, "date": "2026-02-21 19:40:19+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ Callback received: approve (enqueued)", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 7, "offset": 21}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 19:40:19.067252+00
8b02b29d-4348-4818-9426-92cd712e60a9	333	1771877016	1	2026-02-23 20:03:36.402179+00	hello	{"x": 1}	f	\N	2026-02-23 20:03:36.39634+00
bd3791e9-3019-44a6-a884-c891399db54f	333	1771880208	1	2026-02-23 20:56:48.916204+00	hello	{"x": 1}	f	\N	2026-02-23 20:56:48.916382+00
9d96e375-e24d-4828-b380-0003df3ee6fb	333	1774375049	1	2026-03-24 17:57:29.184739+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:29.184278+00
e596f295-856e-42fa-949e-71b47ae68127	444	1774375049	1	2026-03-24 17:57:29.189829+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:29.189222+00
2f65f3e4-d0d2-47ed-8ab2-188408e3a995	222	1774376822	1	2026-03-24 18:27:02.425238+00	hello	{"x": 1}	f	\N	2026-03-24 18:27:02.424683+00
a91f8b36-2776-451c-8476-8b08600b1f31	8000037150545	1150545	\N	2026-04-03 20:20:09.430831+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-04-03 20:20:09.424914+00
fba35e5e-a288-42ea-9468-8386f5bbfe42	-1001239815745	1061714	\N	\N	seed	{}	f	\N	2026-04-03 20:44:43.581371+00
d443a189-5136-4b65-a438-eaddbb821bff	-1001239815745	1087087	\N	\N	seed	{}	f	\N	2026-04-03 20:44:43.589173+00
d6be1687-a315-4638-a7a1-d1fb04c75af0	-1001239815745	1077472	\N	\N	seed	{}	f	\N	2026-04-03 20:44:43.593681+00
7dd803c0-7fe2-460b-9ea4-5352ec647976	-1001239815745	1034502	\N	\N	seed	{}	f	\N	2026-04-03 20:44:43.596306+00
21cdacc8-4a19-478c-8734-3becb3f23602	-1001239815745	944722	\N	\N	seed	{}	f	\N	2026-04-03 20:57:53.426095+00
854a4391-1134-44be-b8e4-7370313eccfb	-1001239815745	997303	\N	\N	seed	{}	f	\N	2026-04-03 20:57:53.442426+00
eddcfad4-64e9-48d0-8a6a-82c3b08f880c	-1003254187278	975345	\N	\N	seed trade	{}	f	\N	2026-04-03 21:03:29.155382+00
5c8a73e9-e5ba-4473-8936-5a077bbb4af7	-1003254187278	975346	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:03:29.169575+00
6a298cba-67f2-4d3e-a012-491af948c11f	-1003254187278	1055599	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.666223+00
8dcbb517-45dd-4363-8a89-02a034141a1b	-1003254187278	1017291	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.681386+00
cbff70c3-750b-4590-8e59-93f9fd35a45c	-1003254187278	1028140	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.691476+00
c8105c91-9b5c-4a94-b4c6-805f84ad1471	-1001239815745	930698	\N	\N	seed	{}	f	\N	2026-04-03 22:17:42.087418+00
c5df57ad-24c5-480d-bca8-7040fb6c5f6f	-1001239815745	978877	\N	\N	seed	{}	f	\N	2026-04-03 22:17:42.216003+00
75bf6072-b429-4e91-be79-83bf74de8df2	-1001239815745	994305	\N	\N	seed	{}	f	\N	2026-04-03 22:17:42.324965+00
5508cbd1-c749-4b05-b169-778eba50e40e	-1001239815745	955155	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:17:42.432171+00
68c610c9-62ee-4197-b885-52c1193aa1a4	-1001239815745	953500	\N	\N	seed	{}	f	\N	2026-04-03 22:17:42.539643+00
f6b53e0c-8b5b-4ccc-83bf-01ce74214545	-1001239815745	933555	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:18:52.165817+00
b6085613-24ba-4e96-83ab-0b84e6911dbb	-1001239815745	984233	\N	\N	seed	{}	f	\N	2026-04-03 22:18:52.17185+00
7a86915e-6168-4cf6-ab7e-83c6ee506284	-5211338635	1845	7622982526	2026-02-21 19:57:43+00	🚨 SELL XAUUSD\n\n📈ENTRY: 5036\n\n🔴SL: 5042\n\n🟢TP1: 5033\n🟢TP2: 5030\n🟢TP3: 5024	{"_": "Message", "id": 1845, "out": true, "date": "2026-02-21 19:57:43+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "🚨 SELL XAUUSD\\n\\n📈ENTRY: 5036\\n\\n🔴SL: 5042\\n\\n🟢TP1: 5033\\n🟢TP2: 5030\\n🟢TP3: 5024", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 19:57:44.042602+00
f889549d-0e10-446a-8371-2086337d0223	333	1771877046	1	2026-02-23 20:04:06.037024+00	hello	{"x": 1}	f	\N	2026-02-23 20:04:06.036427+00
75fcdb96-1fec-47b0-9019-a585d2368b37	8000049738107	1738107	\N	2026-03-24 17:57:43.259594+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 17:57:43.252651+00
4dcf24a2-e735-4ac1-ba10-bd8d6e8a87cc	333	1774375063	1	2026-03-24 17:57:43.361859+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:43.361328+00
e63b1e61-ca65-4fe2-88dc-01740cee4fc4	444	1774375063	1	2026-03-24 17:57:43.368675+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:43.36807+00
e70b70b4-79db-4a2a-be28-9cd6b4bc340c	8000096625570	1625570	\N	2026-03-24 18:48:39.239685+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:48:39.237329+00
afb32ec3-fcc0-42a8-8eac-6aa5c78c919a	-1003254187278	1053706	\N	\N	seed	{}	f	\N	2026-04-03 20:49:46.367059+00
73c274f1-7be4-41d1-b2b3-eb2bba2e46a7	-1003254187278	1055735	\N	\N	seed	{}	f	\N	2026-04-03 20:49:46.386882+00
3e25a084-0373-4e67-884e-3398956545bf	-1003254187278	1040527	\N	\N	seed	{}	f	\N	2026-04-03 20:49:46.413466+00
99d5fa1b-56ab-422b-8578-f8348ef5c5a7	-1001239815745	939630	\N	\N	seed	{}	f	\N	2026-04-03 20:58:14.220531+00
67a64823-749b-4242-bd24-ca5397e93dac	-1001239815745	921199	\N	\N	seed	{}	f	\N	2026-04-03 20:58:14.237699+00
246e8e21-89ad-46bf-9240-19d95f3817d9	-1003254187278	923989	\N	\N	seed trade	{}	f	\N	2026-04-03 21:05:08.79502+00
f9701999-8ac4-4601-b2d0-f4295b6004c6	-1003254187278	923990	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:05:08.806806+00
6d9e3aec-b826-41df-842a-da6c8231f184	-1003254187278	980819	\N	\N	seed trade	{}	f	\N	2026-04-03 21:26:13.222477+00
51a4aa60-df2b-4b85-99d0-cc15ee46104b	-1003254187278	980820	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:26:13.233151+00
fe364df0-35dc-4eb5-8823-9097a83ca3c7	-1001239815745	924362	\N	\N	seed	{}	f	\N	2026-04-03 21:27:58.10856+00
db5b3bcb-7abb-46df-a0eb-fb774ea19055	-1001239815745	994813	\N	\N	seed	{}	f	\N	2026-04-03 21:27:58.127538+00
69e0d9fe-bd8e-42b8-86a7-c72efc4596ee	-1001239815745	906059	\N	\N	seed	{}	f	\N	2026-04-03 22:18:05.780998+00
be40ac15-6dc6-4741-a31a-714ea5c4d9f8	-1001239815745	996188	\N	\N	seed	{}	f	\N	2026-04-03 22:18:05.907617+00
d5b6eecc-ec15-4e41-b31d-f991385e9227	-1001239815745	934193	\N	\N	seed	{}	f	\N	2026-04-03 22:18:06.019037+00
215490eb-68eb-4133-a7e1-726fa5432168	-1001239815745	944615	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:18:06.130525+00
e51ce1a6-36a6-4c46-9fb5-594362fc0455	-1001239815745	985205	\N	\N	seed	{}	f	\N	2026-04-03 22:18:06.240272+00
fa105fb5-a28d-4f52-bcd1-de736d865904	-1001239815745	907593	\N	\N	seed	{}	f	\N	2026-04-03 22:21:53.327781+00
157f181b-feb4-487e-b1e5-6816e796c15b	-1001239815745	939117	\N	\N	seed	{}	f	\N	2026-04-03 22:21:53.343125+00
1e01948b-b735-400c-8f2a-439921c9f5c6	-1001239815745	984428	\N	\N	seed	{}	f	\N	2026-04-03 22:21:53.350739+00
a10da90c-58fe-44c3-af32-1a23a83110a1	-1001239815745	938546	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:21:53.357547+00
c9fe9608-65a1-4f6d-9b3a-6f6a3ea36b5b	-1001239815745	981434	\N	\N	seed	{}	f	\N	2026-04-03 22:21:53.363786+00
e7c17776-be2f-47f2-a6e5-31dae43e2dba	333	1771877149	1	2026-02-23 20:05:49.776599+00	hello	{"x": 1}	f	\N	2026-02-23 20:05:49.775618+00
f2fd2d13-1089-40cc-a7d3-b43d116fdd56	-1001239815745	24858	-1001239815745	2026-02-23 22:56:04+00	For those who know me and follow me closely\n\nOver the past few weeks I’ve shown very bullish signs in my analysis.\n\n3 weeks ago before this announcement from JPM, I mentioned that banks are looking at moving gold allocations by +1%\n\nToday the news broke in the media and it looks like my suggestions of 8000 within 18 months are also closely being followed by major banks. \n\nDo I know the inside. Am I the inside. What I will say… I have direct access to the CEO of the largest investment fund in Europe. No more. \n\nTap the 🐐	{"_": "Message", "id": 24858, "out": false, "date": "2026-02-23 22:56:04+00:00", "post": true, "_meta": {"event_chat_id_raw": -1001239815745, "chat_id_normalized": -1001239815745}, "media": {"_": "MessageMediaPhoto", "photo": {"_": "Photo", "id": 4965586968980949924, "date": "2026-02-23 22:56:04+00:00", "dc_id": 1, "sizes": [{"_": "PhotoStrippedSize", "type": "i", "bytes": "b'\\\\x01(\\\\x14\\\\xd4\\\\xd8\\\\x06y\\\\x1di\\\\xc3\\\\xea?1M\\\\xcf\\\\xb2\\\\xfe\\\\x94\\\\xe0Gp\\\\xb4\\\\x00\\\\xe1\\\\x8f\\\\\\\\\\\\xd1@\\\\xdb\\\\x8e1E\\\\x003\\\\xbf\\\\x7f\\\\xca\\\\x8e\\\\x0fc\\\\xf9\\\\n6\\\\xf2x4\\\\xa1\\\\x01\\\\xed\\\\xfa\\\\x9a\\\\x00x\\\\xe9\\\\xd3\\\\x14R\\\\x01\\\\xc7\\\\xff\\\\x00^\\\\x8a\\\\x00\\\\x8f\\\\x03\\\\xbe?#J\\\\x02\\\\xe7\\\\x8e\\\\xbfCE\\\\x14\\\\x00\\\\xf1\\\\x9c\\\\x7f\\\\xf5\\\\xa8\\\\xa2\\\\x8a\\\\x00'"}, {"_": "PhotoSize", "h": 320, "w": 162, "size": 19176, "type": "m"}, {"_": "PhotoSize", "h": 800, "w": 406, "size": 90476, "type": "x"}, {"_": "PhotoSizeProgressive", "h": 1280, "w": 649, "type": "y", "sizes": [7218, 21882, 55123, 81059, 122396]}], "access_hash": 9200470255263601758, "video_sizes": [], "has_stickers": false, "file_reference": "b'\\\\x02I\\\\xe6\\\\x16A\\\\x00\\\\x00a\\\\x1ai\\\\x9c\\\\xdb\\\\xaa\\\\x0e\\\\x042\\\\xfb\\\\xd2\\\\x1d!\\\\xc3\\\\x0e\\\\x14UE\\\\x8b\\\\x90T\\\\x99'"}, "spoiler": false, "ttl_seconds": null}, "views": 1089, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": null, "message": "For those who know me and follow me closely\\n\\nOver the past few weeks I’ve shown very bullish signs in my analysis.\\n\\n3 weeks ago before this announcement from JPM, I mentioned that banks are looking at moving gold allocations by +1%\\n\\nToday the news broke in the media and it looks like my suggestions of 8000 within 18 months are also closely being followed by major banks. \\n\\nDo I know the inside. Am I the inside. What I will say… I have direct access to the CEO of the largest investment fund in Europe. No more. \\n\\nTap the 🐐", "offline": false, "peer_id": {"_": "PeerChannel", "channel_id": 1239815745}, "replies": null, "entities": [], "forwards": 4, "fwd_from": null, "reply_to": null, "edit_date": "2026-02-23 22:56:20+00:00", "edit_hide": true, "factcheck": null, "mentioned": false, "reactions": {"_": "MessageReactions", "min": false, "results": [{"_": "ReactionCount", "count": 267, "reaction": {"_": "ReactionCustomEmoji", "document_id": 5222141780476046109}, "chosen_order": null}, {"_": "ReactionCount", "count": 30, "reaction": {"_": "ReactionEmoji", "emoticon": "❤"}, "chosen_order": null}, {"_": "ReactionCount", "count": 4, "reaction": {"_": "ReactionEmoji", "emoticon": "🍌"}, "chosen_order": null}, {"_": "ReactionCount", "count": 3, "reaction": {"_": "ReactionCustomEmoji", "document_id": 4915721101134267103}, "chosen_order": null}, {"_": "ReactionCount", "count": 2, "reaction": {"_": "ReactionEmoji", "emoticon": "👍"}, "chosen_order": null}, {"_": "ReactionCount", "count": 2, "reaction": {"_": "ReactionEmoji", "emoticon": "🔥"}, "chosen_order": null}, {"_": "ReactionCount", "count": 1, "reaction": {"_": "ReactionEmoji", "emoticon": "🤩"}, "chosen_order": null}, {"_": "ReactionCount", "count": 1, "reaction": {"_": "ReactionEmoji", "emoticon": "💯"}, "chosen_order": null}], "can_see_list": false, "top_reactors": [], "recent_reactions": [], "reactions_as_tags": false}, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": "YVM", "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 22:58:50.274632+00
3ae69b34-6e5f-4d2c-bc4d-218803b64acd	222	1774375063	1	2026-03-24 17:57:43.358557+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:43.357961+00
0ef1c609-567a-49c0-9c09-f0439edba18b	8000082882460	1882460	\N	2026-03-24 18:48:43.767013+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:48:43.764923+00
6333620e-2f97-439f-b903-6c2e06f09a7d	333	1774378123	1	2026-03-24 18:48:43.872514+00	hello	{"x": 1}	f	\N	2026-03-24 18:48:43.872049+00
cb6ab049-b06e-4c10-9d96-c8e7c2619ed3	444	1774378123	1	2026-03-24 18:48:43.877057+00	hello	{"x": 1}	f	\N	2026-03-24 18:48:43.876576+00
43de33ed-dbcd-4050-a08d-e567e345e3da	-1003254187278	1030314	\N	\N	seed	{}	f	\N	2026-04-03 20:49:59.62046+00
1e3297b0-2607-42d8-a3f7-f1ea48ad9ed8	-1003254187278	1000808	\N	\N	seed	{}	f	\N	2026-04-03 20:49:59.634441+00
61254c17-c14b-4ad5-8c86-9a231c2277be	-1003254187278	1039822	\N	\N	seed	{}	f	\N	2026-04-03 20:49:59.645539+00
ed07d72a-7b87-4dd9-9989-111006078e45	-1001239815745	994918	\N	\N	seed	{}	f	\N	2026-04-03 20:58:49.611826+00
491dcfaf-ce2d-45f7-9a65-b30fc8a0647c	-1001239815745	986486	\N	\N	seed	{}	f	\N	2026-04-03 20:58:49.631+00
31517421-f213-4337-ae9d-b3e15827477f	-1003254187278	970743	\N	\N	seed trade	{}	f	\N	2026-04-03 21:06:27.823298+00
ad33b969-4cbe-4fbf-a380-e29c12f55af3	-1003254187278	970744	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:06:27.835898+00
814baf55-9a14-4704-9cc4-36d954843e87	-1003254187278	978216	\N	\N	seed trade	{}	f	\N	2026-04-03 21:27:58.561892+00
1d8b329e-954f-4b0e-a433-f82804f4cd51	-1003254187278	978217	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:27:58.57406+00
c1e864ce-85c6-48d8-83ec-eeea1a2eb081	-1001239815745	958324	\N	\N	seed	{}	f	\N	2026-04-03 22:18:21.672404+00
079c4383-e581-43f1-8f77-7cd50aa63746	-1001239815745	903160	\N	\N	seed	{}	f	\N	2026-04-03 22:18:21.712283+00
417dd781-4853-432e-aa08-44bead706160	-1001239815745	975207	\N	\N	seed	{}	f	\N	2026-04-03 22:18:21.723139+00
98cafbf0-e31b-479a-b1ef-26539c21806c	-1001239815745	951642	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:18:21.731582+00
7ab25a40-bcb1-4aeb-8ebb-62a3e275cd13	-1001239815745	962072	\N	\N	seed	{}	f	\N	2026-04-03 22:18:21.738179+00
5e3bd33a-daa2-4695-83fc-2b9902b5cdb2	-5211338635	1847	7622982526	2026-02-21 20:20:43+00	!setcontrol	{"_": "Message", "id": 1847, "out": true, "date": "2026-02-21 20:20:43+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!setcontrol", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 20:20:43.928013+00
1e85381f-b279-41e6-86e1-fe9b3085eed6	-5211338635	1848	8432659358	2026-02-21 20:20:44+00	✅ linked (control chat bound and saved)	{"_": "Message", "id": 1848, "out": false, "date": "2026-02-21 20:20:44+00:00", "post": null, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ linked (control chat bound and saved)", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-21 20:20:44.705079+00
fdd32ed9-6ec1-4105-bb24-c3a4855bf5e0	-5211338635	1849	7622982526	2026-02-21 20:20:55+00	!health	{"_": "Message", "id": 1849, "out": true, "date": "2026-02-21 20:20:55+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!health", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 20:20:55.77338+00
8a1fe611-7bcb-4b39-bd75-99f5e56e7221	333	1771877150	1	2026-02-23 20:05:50.912874+00	hello	{"x": 1}	f	\N	2026-02-23 20:05:50.911802+00
3811a070-5800-4e52-b7ff-8c8ea39f6edc	222	1774365839	1	2026-03-24 15:23:59.887615+00	hello	{"x": 1}	f	\N	2026-03-24 15:23:59.887297+00
48ef2a1f-b8b5-4449-b3d6-a846ced4f9c8	333	1774365839	1	2026-03-24 15:23:59.894367+00	hello	{"x": 1}	f	\N	2026-03-24 15:23:59.894029+00
3bc142f1-fe6e-4e54-be4d-a422798eb777	444	1774365839	1	2026-03-24 15:23:59.899117+00	hello	{"x": 1}	f	\N	2026-03-24 15:23:59.898774+00
5117e45f-b6cd-4b9e-a56b-e3843e52237b	8000029777593	1777593	\N	2026-03-24 17:58:36.730348+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 17:58:36.723571+00
a0a0c24c-d0f7-4b98-9a7c-0ca33068715f	222	1774375116	1	2026-03-24 17:58:36.855096+00	hello	{"x": 1}	f	\N	2026-03-24 17:58:36.854523+00
6ae0fef2-6f92-4ac9-9a2a-3931d4944601	222	1774378123	1	2026-03-24 18:48:43.869383+00	hello	{"x": 1}	f	\N	2026-03-24 18:48:43.868916+00
c1ed830f-8fb6-421a-9fb1-2c1fc0f9f098	-1001239815745	980001	\N	\N	seed	{}	f	\N	2026-04-03 20:39:29.340287+00
5094601c-95a2-46c2-a8c1-d0918755dad3	-1003254187278	1063235	\N	\N	seed	{}	f	\N	2026-04-03 20:51:05.535837+00
d9e6ac73-e7c8-4bcd-9c49-b482a100bab3	-1003254187278	979715	\N	\N	seed	{}	f	\N	2026-04-03 20:51:05.551267+00
820b81c8-42a2-4068-8524-38e822e63ead	-1003254187278	1025917	\N	\N	seed	{}	f	\N	2026-04-03 20:51:05.565345+00
7b61b20f-cce8-497e-88ab-b5531ae7c771	-1003254187278	956155	\N	\N	seed trade	{}	f	\N	2026-04-03 21:07:20.246035+00
94d3e4bf-6b61-4ab0-af76-f3f1cb764d98	-1003254187278	956156	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:07:20.274848+00
cd646c7a-8ce6-4922-a469-7223e22e183e	-1001239815745	1075358	\N	\N	seed	{}	f	\N	2026-04-03 21:27:56.792247+00
59d29aa1-6987-4297-beda-202eb37be535	-1001239815745	1017141	\N	\N	seed	{}	f	\N	2026-04-03 21:27:56.806971+00
ca3b59d4-90e3-4bf6-bd5a-fbdb7eddd612	-1001239815745	1011442	\N	\N	seed	{}	f	\N	2026-04-03 21:27:56.81633+00
c02e9a4c-e911-4580-b1c5-0178b4b41003	-1003254187278	950010	\N	\N	hello just info	{}	t	\N	2026-04-03 21:01:52.094096+00
9d9b0a99-85ca-4ce6-947d-c660f6b343e5	-1001239815745	929845	\N	\N	seed	{}	f	\N	2026-04-03 22:18:34.123482+00
b51eb9fa-b7a8-4b9f-b68f-75e0b1384f44	-1001239815745	970818	\N	\N	seed	{}	f	\N	2026-04-03 22:18:34.138995+00
730bdb9e-c5d0-4269-b435-7bd96c39b153	-1001239815745	986320	\N	\N	seed	{}	f	\N	2026-04-03 22:18:34.146141+00
0e98579e-062f-495e-9c61-66e7bc159841	-1001239815745	918341	\N	\N	I’m trying something out on a 5K side account I setup to have some fun on…	{}	f	\N	2026-04-03 22:18:34.154188+00
dc7047f9-abbc-4857-8410-99bc5e2c050f	-1001239815745	989114	\N	\N	seed	{}	f	\N	2026-04-03 22:18:34.160373+00
b0bea07d-d8ab-4d6d-a802-1cfaa6e2b26c	-5211338635	1850	8432659358	2026-02-21 20:20:56+00	✅ health\nDB: ok\nlast_ingested: 2026-02-21 20:20:44.705079+00:00\ncontrol_chat_id: -5211338635	{"_": "Message", "id": 1850, "out": false, "date": "2026-02-21 20:20:56+00:00", "post": null, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ health\\nDB: ok\\nlast_ingested: 2026-02-21 20:20:44.705079+00:00\\ncontrol_chat_id: -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-21 20:20:56.683572+00
2ce2e2f7-93df-4993-b680-e8a14267e755	-5211338635	1851	7622982526	2026-02-21 20:21:08+00	!testbuttons	{"_": "Message", "id": 1851, "out": true, "date": "2026-02-21 20:21:08+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!testbuttons", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 20:21:08.880335+00
1a58a61e-f4d8-47ec-9ef9-ae3f8342a62a	-5211338635	1852	8432659358	2026-02-21 20:21:09+00	🧪 Test buttons: click one to verify callback → DB enqueue.	{"_": "Message", "id": 1852, "out": false, "date": "2026-02-21 20:21:09+00:00", "post": false, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🧪 Test buttons: click one to verify callback → DB enqueue.", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": {"_": "ReplyInlineMarkup", "rows": [{"_": "KeyboardButtonRow", "buttons": [{"_": "KeyboardButtonCallback", "data": "b'approve'", "text": "✅ Approve", "requires_password": false}, {"_": "KeyboardButtonCallback", "data": "b'reject'", "text": "❌ Reject", "requires_password": false}, {"_": "KeyboardButtonCallback", "data": "b'snooze'", "text": "😴 Snooze", "requires_password": false}]}]}, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-21 20:21:09.192591+00
796e5ff4-9503-4f4c-81e7-492b1a6e3644	-5211338635	1853	8432659358	2026-02-21 20:21:14+00	✅ Callback received: approve (enqueued)	{"_": "Message", "id": 1853, "out": false, "date": "2026-02-21 20:21:14+00:00", "post": null, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ Callback received: approve (enqueued)", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-21 20:21:15.025908+00
78d32cbb-8882-4565-8bf3-169cec74285c	-5211338635	1854	7622982526	2026-02-23 18:43:32+00	!showrouting	{"_": "Message", "id": 1854, "out": true, "date": "2026-02-23 18:43:32+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 18:43:32.185588+00
22845405-2dc0-48c8-8a54-79038ceab719	-5211338635	1855	7622982526	2026-02-23 19:05:47+00	!showrouting	{"_": "Message", "id": 1855, "out": true, "date": "2026-02-23 19:05:47+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:05:47.992461+00
d30b041f-6bf6-47c5-8d0c-560dd9d835d9	333	1771877425	1	2026-02-23 20:10:25.126023+00	hello	{"x": 1}	f	\N	2026-02-23 20:10:25.126092+00
edaa5b0a-94b7-40ce-bf1c-44dd4d1bb73c	-5211338635	1856	7622982526	2026-02-23 19:06:56+00	!showrouting	{"_": "Message", "id": 1856, "out": true, "date": "2026-02-23 19:06:56+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:06:56.174177+00
6cd43030-0c7b-4c78-a437-a26c3da5192b	-5211338635	1857	7622982526	2026-02-23 19:09:35+00	!showrouting	{"_": "Message", "id": 1857, "out": true, "date": "2026-02-23 19:09:35+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:35.276979+00
23a61115-5375-4dda-b9a9-9b37e37ccb78	-5211338635	1858	8432659358	2026-02-23 19:09:35+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1858, "out": false, "date": "2026-02-23 19:09:35+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:36.072003+00
c2f4017f-a14a-44d7-b376-fedd26f615a1	-5211338635	1859	8432659358	2026-02-23 19:09:36+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1859, "out": false, "date": "2026-02-23 19:09:36+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:36.838617+00
2c384bf0-23a4-4268-97fd-81384bc38b2f	-5211338635	1860	8432659358	2026-02-23 19:09:37+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1860, "out": false, "date": "2026-02-23 19:09:37+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:37.509554+00
5044c0c2-c88d-404c-8373-d891483ac883	333	1771877986	1	2026-02-23 20:19:46.621436+00	hello	{"x": 1}	f	\N	2026-02-23 20:19:46.621168+00
deed5561-76a5-4fb9-a7df-32aaa5087b15	222	1774365858	1	2026-03-24 15:24:18.233772+00	hello	{"x": 1}	f	\N	2026-03-24 15:24:18.233358+00
be393da5-f855-4dd4-90a7-2b80b163e6ef	333	1774365858	1	2026-03-24 15:24:18.237457+00	hello	{"x": 1}	f	\N	2026-03-24 15:24:18.237053+00
351a7bc0-f6cf-4d48-9fc3-ed8170020aa4	444	1774365858	1	2026-03-24 15:24:18.241976+00	hello	{"x": 1}	f	\N	2026-03-24 15:24:18.241548+00
815ca4d1-aa55-4779-a054-7532751ac145	333	1774375116	1	2026-03-24 17:58:36.858889+00	hello	{"x": 1}	f	\N	2026-03-24 17:58:36.858281+00
08672811-ed1c-4c26-b060-c2b40bc3da47	444	1774375116	1	2026-03-24 17:58:36.865693+00	hello	{"x": 1}	f	\N	2026-03-24 17:58:36.865045+00
7daa3298-da1f-44bf-bae6-11eb3369f41f	-5211338635	1861	8432659358	2026-02-23 19:09:37+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1861, "out": false, "date": "2026-02-23 19:09:37+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:38.036819+00
12b2be2c-2068-4599-b2da-b185875fa1f0	-5211338635	1862	8432659358	2026-02-23 19:09:38+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1862, "out": false, "date": "2026-02-23 19:09:38+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:38.635811+00
2b692587-c0a6-46aa-b305-7e62ea69975c	-5211338635	1863	8432659358	2026-02-23 19:09:38+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1863, "out": false, "date": "2026-02-23 19:09:38+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:39.186419+00
49d2c0a2-7620-4d14-b91a-3dfb31ce2751	-5211338635	1864	8432659358	2026-02-23 19:09:42+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1864, "out": false, "date": "2026-02-23 19:09:42+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:43.026325+00
2ad2bc4f-5042-47fc-a0db-4d1cc22ac837	-5211338635	1865	8432659358	2026-02-23 19:09:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1865, "out": false, "date": "2026-02-23 19:09:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:43.6113+00
8fa3c929-3a7b-440a-b51a-79d9f68d9d9b	222	1774365904	1	2026-03-24 15:25:04.177795+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:04.177519+00
021f42a0-22d5-4c97-a527-4e02bc94d59d	-5211338635	1866	8432659358	2026-02-23 19:09:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1866, "out": false, "date": "2026-02-23 19:09:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:09:44.340955+00
e1f0e969-0f0e-4715-8717-dea48c33ebe2	-5211338635	1867	8432659358	2026-02-23 19:09:44+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1867, "out": false, "date": "2026-02-23 19:09:44+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:05.198567+00
5587c998-eaac-4ad2-a9a0-2353606118da	-5211338635	1868	8432659358	2026-02-23 19:10:05+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1868, "out": false, "date": "2026-02-23 19:10:05+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:05.905114+00
e68b88c3-9b6d-4f93-8765-352d4561950a	-5211338635	1869	8432659358	2026-02-23 19:10:06+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1869, "out": false, "date": "2026-02-23 19:10:06+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:06.826891+00
12855316-5585-47aa-afc3-5e170d060e00	-5211338635	1870	8432659358	2026-02-23 19:10:07+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1870, "out": false, "date": "2026-02-23 19:10:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:07.731056+00
1d15c3f5-d725-424f-b7f1-0f2ca601cd17	333	1774365904	1	2026-03-24 15:25:04.180858+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:04.18055+00
e023d667-46b2-45e1-b165-6559c8e7118b	444	1774365904	1	2026-03-24 15:25:04.185905+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:04.185558+00
5f9627df-f94e-4a3c-bee1-88cd07749933	-5211338635	1871	8432659358	2026-02-23 19:10:08+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1871, "out": false, "date": "2026-02-23 19:10:08+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:08.461401+00
483a65c3-7adb-418d-80d4-6d5fb8785b5e	-5211338635	1872	8432659358	2026-02-23 19:10:08+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1872, "out": false, "date": "2026-02-23 19:10:08+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:09.63871+00
b1ea3504-776f-44ef-8774-8e372d0ed403	-5211338635	1873	8432659358	2026-02-23 19:10:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1873, "out": false, "date": "2026-02-23 19:10:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:13.370313+00
7b3b52b5-9215-4c85-8bf5-3e0e7a97ed38	-5211338635	1874	8432659358	2026-02-23 19:10:13+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1874, "out": false, "date": "2026-02-23 19:10:13+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:14.393887+00
b3388b20-5b8d-4255-9e87-378fa5d82e4a	-5211338635	1875	8432659358	2026-02-23 19:10:14+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1875, "out": false, "date": "2026-02-23 19:10:14+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:15.229863+00
b9233054-ea06-473f-bfcb-dfb15b44004a	-1001239815745	872079875	\N	\N	\N	{}	f	\N	2026-03-24 15:25:33.994178+00
7b0648c0-1200-4d1b-86b0-ebcb1d952a80	222	1774365934	1	2026-03-24 15:25:34.174462+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:34.173743+00
6be737ff-fdba-4474-8446-f88ee1db34e5	-5211338635	1876	8432659358	2026-02-23 19:10:15+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1876, "out": false, "date": "2026-02-23 19:10:15+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:15.878636+00
caf2c8c8-6b6f-47da-9e2a-8ca9b3ba670a	-5211338635	1878	7622982526	2026-02-23 19:10:22+00	/health	{"_": "Message", "id": 1878, "out": true, "date": "2026-02-23 19:10:22+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "/health", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBotCommand", "length": 7, "offset": 0}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:22.589413+00
ff7a61e6-9d72-4604-8c80-d6273ca97b9c	-5211338635	1880	7622982526	2026-02-23 19:10:34+00	/health	{"_": "Message", "id": 1880, "out": true, "date": "2026-02-23 19:10:34+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "/health", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBotCommand", "length": 7, "offset": 0}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:34.337884+00
f03ec4c8-7c8b-4bbe-994e-c9dda9cf5f17	-5211338635	1879	8432659358	2026-02-23 19:10:22+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1879, "out": false, "date": "2026-02-23 19:10:22+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:35.650487+00
34ef6467-f345-4904-bcd2-bbd09420d030	-5211338635	1877	8432659358	2026-02-23 19:10:16+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1877, "out": false, "date": "2026-02-23 19:10:16+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:35.937136+00
b206ff12-e395-4dc6-9de5-610e8b284b4e	333	1774365934	1	2026-03-24 15:25:34.178492+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:34.177615+00
909e35e1-14d3-4070-a4f0-8bb4f6fbe2aa	444	1774365934	1	2026-03-24 15:25:34.18361+00	hello	{"x": 1}	f	\N	2026-03-24 15:25:34.182767+00
b4378065-98fd-4169-b56e-bcbfe849f7e0	8000024556310	1556310	\N	2026-03-24 17:58:53.619386+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 17:58:53.613575+00
fa396360-2357-4765-b96a-6955ce89ace4	-1001239815745	1040740	\N	\N	seed	{}	f	\N	2026-04-03 20:40:03.808341+00
adfabdc6-bee5-4b73-a2ae-7c1bbd969cae	-1001239815745	1022510	\N	\N	seed	{}	f	\N	2026-04-03 20:40:03.819489+00
bb1785d2-f9fc-4198-bd25-6edd8eca4a45	-1001239815745	987685	\N	\N	seed	{}	f	\N	2026-04-03 20:40:03.848728+00
8ebc009f-f915-4be5-8e22-660db1ca8ade	-5211338635	1882	8432659358	2026-02-23 19:10:35+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1882, "out": false, "date": "2026-02-23 19:10:35+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:36.281032+00
c9402ed5-0cae-441b-93ea-874c8d1f90c8	-5211338635	1881	8432659358	2026-02-23 19:10:34+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1881, "out": false, "date": "2026-02-23 19:10:34+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:38.304966+00
25ad8279-9d94-4b0e-b531-3a5b3da45dde	-5211338635	1884	8432659358	2026-02-23 19:10:39+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1884, "out": false, "date": "2026-02-23 19:10:39+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:39.636314+00
5472ab13-9c0b-4b53-92c7-20507d91c894	-5211338635	1883	8432659358	2026-02-23 19:10:39+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1883, "out": false, "date": "2026-02-23 19:10:39+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:39.813013+00
c3f740c3-339e-47f0-9da8-c729f9f08312	-5211338635	1885	8432659358	2026-02-23 19:10:39+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1885, "out": false, "date": "2026-02-23 19:10:39+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:39.900303+00
f1b41cd8-1862-4fef-bfdd-f3aac4aac242	-1001239815745	977898220	\N	\N	\N	{}	f	\N	2026-03-24 15:26:12.28315+00
2dd5bc62-2cb9-46ac-8e8a-c54b46ee2fe8	222	1774365972	1	2026-03-24 15:26:12.465464+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:12.464998+00
ce67b3d5-4eab-4df2-91e4-258810aa4d9c	-5211338635	1888	8432659358	2026-02-23 19:10:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1888, "out": false, "date": "2026-02-23 19:10:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:43.555759+00
0f29eca9-dd50-4d69-bc8c-c4b376aaada7	-5211338635	1887	8432659358	2026-02-23 19:10:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1887, "out": false, "date": "2026-02-23 19:10:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:43.582921+00
c0ebee61-5983-440d-b240-362a923f07b6	-5211338635	1886	8432659358	2026-02-23 19:10:42+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1886, "out": false, "date": "2026-02-23 19:10:42+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:10:43.611805+00
f8d97188-2ee7-4f10-89bd-2befe51cb701	-5211338635	1890	8432659358	2026-02-23 19:10:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1890, "out": false, "date": "2026-02-23 19:10:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:06.37086+00
d539cf43-6652-42bb-a3c0-53e60c1e13dc	-5211338635	1889	8432659358	2026-02-23 19:10:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1889, "out": false, "date": "2026-02-23 19:10:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:06.712143+00
dcbdd2e3-da30-4440-bd8b-c1db25b7bf68	333	1774365972	1	2026-03-24 15:26:12.468701+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:12.468193+00
ebca87b0-d8ca-4daa-9c97-20c65008ba0f	444	1774365972	1	2026-03-24 15:26:12.473384+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:12.472834+00
555832ac-2624-4ce1-8fcf-5efcfd08e5fe	-5211338635	1891	8432659358	2026-02-23 19:10:50+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1891, "out": false, "date": "2026-02-23 19:10:50+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:06.741011+00
c5cd2871-0e4d-4331-9441-7e125a7533f4	-5211338635	1892	8432659358	2026-02-23 19:11:06+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1892, "out": false, "date": "2026-02-23 19:11:06+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:07.133395+00
7a850fec-939a-46f5-9e4e-958b05e74cd2	-5211338635	1894	8432659358	2026-02-23 19:11:07+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1894, "out": false, "date": "2026-02-23 19:11:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:07.500718+00
54502088-d75b-4ddf-8172-c9ef98fc3fe7	-5211338635	1893	8432659358	2026-02-23 19:11:06+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1893, "out": false, "date": "2026-02-23 19:11:06+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:07.715397+00
8c2c6173-f3be-4c7e-bb96-211cab55acee	-5211338635	1895	8432659358	2026-02-23 19:11:07+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1895, "out": false, "date": "2026-02-23 19:11:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:07.908388+00
b8ccae3f-a11a-4f98-b3de-fb63d95cf60a	-1001239815745	686895205	\N	\N	\N	{}	f	\N	2026-03-24 15:26:57.604342+00
cb0f94da-b627-447c-852d-bb72b7832fde	222	1774366017	1	2026-03-24 15:26:57.786596+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:57.786016+00
d11b7758-0476-472f-b682-8ac6b0d9c02b	-5211338635	1896	8432659358	2026-02-23 19:11:07+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1896, "out": false, "date": "2026-02-23 19:11:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:08.321574+00
f08ac49d-d398-4383-8a2f-2af35eb86bc9	-5211338635	1898	8432659358	2026-02-23 19:11:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1898, "out": false, "date": "2026-02-23 19:11:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:12.675031+00
ebc63378-caad-4917-a505-b8952a04ca1f	-5211338635	1897	8432659358	2026-02-23 19:11:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1897, "out": false, "date": "2026-02-23 19:11:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:12.897855+00
7c6b169b-32d9-4e5a-961f-3096a389220f	-5211338635	1900	8432659358	2026-02-23 19:11:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1900, "out": false, "date": "2026-02-23 19:11:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:36.636116+00
dbd1e312-6b99-415c-b8f7-241f376fc1b9	-5211338635	1901	8432659358	2026-02-23 19:11:13+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1901, "out": false, "date": "2026-02-23 19:11:13+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:36.822243+00
5c636ce1-1848-42d1-a36f-7002495885fa	333	1774366017	1	2026-03-24 15:26:57.789827+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:57.789227+00
4bbaccb4-8219-4d1e-9151-ddd5959f3bc2	444	1774366017	1	2026-03-24 15:26:57.794803+00	hello	{"x": 1}	f	\N	2026-03-24 15:26:57.794169+00
2b212dde-e0fd-4fd1-b395-ee5b5b01e1cb	-5211338635	1899	8432659358	2026-02-23 19:11:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1899, "out": false, "date": "2026-02-23 19:11:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:37.031438+00
8434892c-2161-4f70-b085-0e0c86708ab4	-5211338635	1902	8432659358	2026-02-23 19:11:36+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1902, "out": false, "date": "2026-02-23 19:11:36+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:37.30714+00
0e8eff68-9e88-451b-88f9-8a4365d1b97b	-5211338635	1903	8432659358	2026-02-23 19:11:40+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1903, "out": false, "date": "2026-02-23 19:11:40+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:40.621238+00
c0bb5ebb-dfe3-45b6-8877-f4f9898d5c4b	-5211338635	1904	8432659358	2026-02-23 19:11:40+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1904, "out": false, "date": "2026-02-23 19:11:40+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:40.699066+00
f2131b36-0718-49af-be8f-768c199081d2	-5211338635	1905	8432659358	2026-02-23 19:11:40+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1905, "out": false, "date": "2026-02-23 19:11:40+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:40.70535+00
05687b3d-44ac-4a27-8035-d6e62ed07919	-1001239815745	1756751015	\N	\N	\N	{}	f	\N	2026-03-24 15:27:21.317342+00
3516ce67-da82-4eed-a622-2c5dd17cd5a1	222	1774366041	1	2026-03-24 15:27:21.487741+00	hello	{"x": 1}	f	\N	2026-03-24 15:27:21.486299+00
3dc47912-181c-44c3-b43e-9baf2a3f466b	-5211338635	1908	8432659358	2026-02-23 19:11:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1908, "out": false, "date": "2026-02-23 19:11:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:44.407032+00
93551d51-37b6-4206-b51b-eef0e81e1a24	-5211338635	1907	8432659358	2026-02-23 19:11:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1907, "out": false, "date": "2026-02-23 19:11:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:44.502523+00
dd906016-30c7-4dad-8043-49e45b3648d9	-5211338635	1906	8432659358	2026-02-23 19:11:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1906, "out": false, "date": "2026-02-23 19:11:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:11:44.614608+00
85008fb9-66c9-4283-9b74-483c539fd9ee	-5211338635	1912	7622982526	2026-02-23 19:12:12+00	Hey	{"_": "Message", "id": 1912, "out": true, "date": "2026-02-23 19:12:12+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "Hey", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:12.373951+00
90112d17-95be-4636-80b8-891a98c8dd29	-5211338635	1913	8432659358	2026-02-23 19:12:12+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1913, "out": false, "date": "2026-02-23 19:12:12+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:13.125366+00
be89e85e-c779-4cd4-9b55-cc1f89db0a40	333	1774366041	1	2026-03-24 15:27:21.490903+00	hello	{"x": 1}	f	\N	2026-03-24 15:27:21.489429+00
34eb459d-fd39-4306-874c-87c83c88ab9a	444	1774366041	1	2026-03-24 15:27:21.496029+00	hello	{"x": 1}	f	\N	2026-03-24 15:27:21.494508+00
44444444-4444-4444-4444-444444444444	8000061825860	1825860	\N	2026-03-24 18:05:11.198176+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:05:11.190799+00
65f8413f-427c-499b-a7d8-09a35d266211	-1001239815745	1026801	\N	\N	seed	{}	f	\N	2026-04-03 20:40:16.819243+00
a69e5834-a130-4a83-a795-2f1807379f84	-1001239815745	1022788	\N	\N	seed	{}	f	\N	2026-04-03 20:40:16.830315+00
e904f0cb-0d96-424f-a3ea-abf4efa1c430	-5211338635	1914	8432659358	2026-02-23 19:12:13+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1914, "out": false, "date": "2026-02-23 19:12:13+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:13.734381+00
aa5cd063-a2b3-4944-bae2-2869ea1be4aa	-5211338635	1915	8432659358	2026-02-23 19:12:13+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1915, "out": false, "date": "2026-02-23 19:12:13+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:14.79449+00
0cdf6b38-9a8f-4780-a1bd-f70690977bc5	-5211338635	1916	8432659358	2026-02-23 19:12:15+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1916, "out": false, "date": "2026-02-23 19:12:15+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:15.407512+00
7bb59c60-9452-4edf-8b65-1ec3c3feb514	-5211338635	1917	8432659358	2026-02-23 19:12:15+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1917, "out": false, "date": "2026-02-23 19:12:15+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:16.447285+00
54e81701-830b-4e85-b85c-13266ee10274	-5211338635	1918	8432659358	2026-02-23 19:12:16+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1918, "out": false, "date": "2026-02-23 19:12:16+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:17.068838+00
ae496022-c714-46f8-a2ca-929148a6deb0	-1001239815745	1576350422	\N	\N	\N	{}	f	\N	2026-03-24 15:28:12.457742+00
71c2e8b9-fc9d-4952-a612-391306fddabd	222	1774366092	1	2026-03-24 15:28:12.634939+00	hello	{"x": 1}	f	\N	2026-03-24 15:28:12.634089+00
86ae6644-c0e3-4214-8c4f-5ca593a07182	-5211338635	1919	8432659358	2026-02-23 19:12:20+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1919, "out": false, "date": "2026-02-23 19:12:20+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:20.869835+00
5ac05f65-26cb-409b-a72c-e411b16744af	-5211338635	1920	8432659358	2026-02-23 19:12:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1920, "out": false, "date": "2026-02-23 19:12:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:21.574127+00
cd660daf-2402-4650-a187-928fd7b8c8c1	-5211338635	1921	8432659358	2026-02-23 19:12:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1921, "out": false, "date": "2026-02-23 19:12:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:22.190578+00
1aaf7eca-9406-445f-af9d-60e36b28f5cb	-5211338635	1922	8432659358	2026-02-23 19:12:22+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1922, "out": false, "date": "2026-02-23 19:12:22+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:22.779778+00
02c9fc7a-1e2b-4695-845f-990f89c79e85	-5211338635	1923	8432659358	2026-02-23 19:12:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1923, "out": false, "date": "2026-02-23 19:12:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:43.668223+00
b07e9927-0e9a-4a0a-a223-9df7f8e9bfe8	333	1774366092	1	2026-03-24 15:28:12.638361+00	hello	{"x": 1}	f	\N	2026-03-24 15:28:12.637505+00
90bc8208-6087-4919-a498-6d2a89260582	444	1774366092	1	2026-03-24 15:28:12.645002+00	hello	{"x": 1}	f	\N	2026-03-24 15:28:12.644099+00
dca7d7a9-f529-4955-a249-acd1167060dd	-5211338635	1924	8432659358	2026-02-23 19:12:43+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1924, "out": false, "date": "2026-02-23 19:12:43+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:44.253162+00
e4161099-1206-4614-9de9-24bfe1fa057e	-5211338635	1925	8432659358	2026-02-23 19:12:44+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1925, "out": false, "date": "2026-02-23 19:12:44+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:44.83727+00
39a1fc8e-e998-45d4-bf5b-976fa3783bd4	-5211338635	1926	8432659358	2026-02-23 19:12:45+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1926, "out": false, "date": "2026-02-23 19:12:45+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:45.630766+00
f28a9c79-c3b3-4a0c-8b45-71c2390bd2be	-5211338635	1927	8432659358	2026-02-23 19:12:46+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1927, "out": false, "date": "2026-02-23 19:12:46+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:46.676388+00
244220e9-84d5-4085-84f3-415c9f12be01	-5211338635	1928	8432659358	2026-02-23 19:12:46+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1928, "out": false, "date": "2026-02-23 19:12:46+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:47.370271+00
089a4a1e-7c2a-4aea-ac4b-e785578f4475	-1001239815745	485689549	\N	\N	\N	{}	f	\N	2026-03-24 15:29:15.660967+00
0eb11e47-617d-40cd-a4da-89919ea06734	222	1774366155	1	2026-03-24 15:29:15.726703+00	hello	{"x": 1}	f	\N	2026-03-24 15:29:15.7265+00
22f35980-1a09-4273-96c1-727e7c1addfb	-5211338635	1929	8432659358	2026-02-23 19:12:50+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1929, "out": false, "date": "2026-02-23 19:12:50+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:50.977785+00
02d34ad9-6dfb-4902-9d3f-79172cc965c5	-5211338635	1930	8432659358	2026-02-23 19:12:51+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1930, "out": false, "date": "2026-02-23 19:12:51+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:51.518661+00
37a600e4-37a5-4934-b42c-b07210c467ee	-5211338635	1931	8432659358	2026-02-23 19:12:51+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1931, "out": false, "date": "2026-02-23 19:12:51+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:52.151361+00
2edd0b57-8d62-4ca6-a352-e50a11835e6e	-5211338635	1932	8432659358	2026-02-23 19:12:52+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1932, "out": false, "date": "2026-02-23 19:12:52+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:12:52.820294+00
e0dadce9-898f-4d69-8034-3b833dd96404	-5211338635	1933	8432659358	2026-02-23 19:12:53+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1933, "out": false, "date": "2026-02-23 19:12:53+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:14.622587+00
b39e9ac1-7742-43d3-b95c-2cb389bfa77f	333	1774366155	1	2026-03-24 15:29:15.729878+00	hello	{"x": 1}	f	\N	2026-03-24 15:29:15.729777+00
cce57b31-4dbb-49d7-b110-e401e40f198e	444	1774366155	1	2026-03-24 15:29:15.735097+00	hello	{"x": 1}	f	\N	2026-03-24 15:29:15.734839+00
f6d1e272-c05b-4808-b788-29a9ab3a8aa6	-5211338635	1934	8432659358	2026-02-23 19:13:14+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1934, "out": false, "date": "2026-02-23 19:13:14+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:15.243648+00
2e1bbf82-28a3-4191-bd35-934832bbfb93	-5211338635	1935	8432659358	2026-02-23 19:13:15+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1935, "out": false, "date": "2026-02-23 19:13:15+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:15.945536+00
6eeab5d7-e71e-4382-8333-f9c075fa6205	-5211338635	1936	8432659358	2026-02-23 19:13:16+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1936, "out": false, "date": "2026-02-23 19:13:16+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:16.734905+00
df077c0a-a142-42ce-b896-6ec4edf3465f	-5211338635	1937	8432659358	2026-02-23 19:13:16+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1937, "out": false, "date": "2026-02-23 19:13:16+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:17.282182+00
35c1f8d8-151c-4fcf-98d2-019f4b330739	-5211338635	1938	8432659358	2026-02-23 19:13:17+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1938, "out": false, "date": "2026-02-23 19:13:17+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:17.885057+00
6d45aaa7-84e3-48ec-8224-776082c967cd	-1001239815745	100701789	\N	\N	\N	{}	f	\N	2026-03-24 15:30:02.813922+00
55555555-5555-5555-5555-555555555555	8000002282325	1282325	\N	2026-03-24 18:05:11.210453+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:05:11.2052+00
14fbec49-9304-4ee9-9eaa-470d1059be9e	-5211338635	1939	8432659358	2026-02-23 19:13:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1939, "out": false, "date": "2026-02-23 19:13:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:21.648005+00
2845fadd-717e-4f90-8d41-be3954acc4b7	-5211338635	1940	8432659358	2026-02-23 19:13:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1940, "out": false, "date": "2026-02-23 19:13:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:22.330403+00
ef148598-a8d2-4765-9a62-1dd572c11937	-5211338635	1941	8432659358	2026-02-23 19:13:22+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1941, "out": false, "date": "2026-02-23 19:13:22+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:22.85291+00
0b0d8520-cf4f-45f0-b1cf-ab9feb667ff1	-5211338635	1942	8432659358	2026-02-23 19:13:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1942, "out": false, "date": "2026-02-23 19:13:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:23.501416+00
fcf4be42-8725-441d-9538-0456e74d2d13	-5211338635	1943	8432659358	2026-02-23 19:13:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1943, "out": false, "date": "2026-02-23 19:13:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:46.306863+00
eab38fdb-6564-43ff-9340-4d47ca24a711	-1001239815745	1616358087	\N	\N	\N	{}	f	\N	2026-03-24 16:06:05.954701+00
7517b929-4831-4b19-b734-cbffdd970ada	222	1774368365	1	2026-03-24 16:06:05.993059+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:05.992562+00
809a4b1f-c623-4454-8c66-f7967b202f5b	-5211338635	1944	8432659358	2026-02-23 19:13:46+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1944, "out": false, "date": "2026-02-23 19:13:46+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:47.064857+00
511b836b-736a-4986-936b-a6824ee21a4c	-5211338635	1945	8432659358	2026-02-23 19:13:47+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1945, "out": false, "date": "2026-02-23 19:13:47+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:47.92572+00
2f028929-11a0-4926-bf69-3eb3cba05306	-5211338635	1946	8432659358	2026-02-23 19:13:48+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1946, "out": false, "date": "2026-02-23 19:13:48+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:48.679658+00
75671e3e-caaf-4705-a7ea-77fa77b19198	-5211338635	1947	8432659358	2026-02-23 19:13:49+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1947, "out": false, "date": "2026-02-23 19:13:49+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:49.727725+00
6dbe1210-085a-460a-891c-e6976d166aba	-5211338635	1948	8432659358	2026-02-23 19:13:50+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1948, "out": false, "date": "2026-02-23 19:13:50+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:50.641205+00
abce0e79-0c51-44dd-9fcf-9df99700e191	333	1774368365	1	2026-03-24 16:06:05.997387+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:05.996867+00
9756fcef-795f-45c8-974a-0b5e1ed25acc	444	1774368366	1	2026-03-24 16:06:06.004041+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:06.00351+00
cf37b2e4-1e58-4c7b-877a-66cbb08781ab	-5211338635	1949	8432659358	2026-02-23 19:13:53+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1949, "out": false, "date": "2026-02-23 19:13:53+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:54.379557+00
98d2badd-5f08-4b3c-8231-b9fc8b1e6c43	-5211338635	1950	8432659358	2026-02-23 19:13:54+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1950, "out": false, "date": "2026-02-23 19:13:54+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:55.029635+00
c2547701-b202-4c68-9e66-4301d6bbaf1b	-5211338635	1951	8432659358	2026-02-23 19:13:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1951, "out": false, "date": "2026-02-23 19:13:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:55.613626+00
ad2c6d8b-94ad-4acf-863d-72be0d913894	-5211338635	1952	8432659358	2026-02-23 19:13:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1952, "out": false, "date": "2026-02-23 19:13:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:13:56.258795+00
28ed7ea9-453f-45ec-b9be-6274053d7cae	-5211338635	1953	8432659358	2026-02-23 19:13:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1953, "out": false, "date": "2026-02-23 19:13:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:17.191376+00
c4889396-b065-41b7-92fc-ce2b25e135d3	-1001239815745	1534172994	\N	\N	\N	{}	f	\N	2026-03-24 16:06:16.598163+00
3358ba55-6597-479d-9e15-b38ca7ee4b36	222	1774368376	1	2026-03-24 16:06:16.663165+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:16.662655+00
628a0ea9-7dfc-4731-b1d3-bb2665e76ce2	-5211338635	1954	8432659358	2026-02-23 19:14:17+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1954, "out": false, "date": "2026-02-23 19:14:17+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:17.97088+00
9ccbb154-e1be-46dd-adda-6e9d11f6b8ea	-5211338635	1955	8432659358	2026-02-23 19:14:18+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1955, "out": false, "date": "2026-02-23 19:14:18+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:18.67464+00
cf58876e-914e-4592-aa79-ac36724178bf	-5211338635	1956	8432659358	2026-02-23 19:14:18+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1956, "out": false, "date": "2026-02-23 19:14:18+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:19.476299+00
aecebb2a-b621-4f1f-83db-fb52d7c2157f	-5211338635	1957	8432659358	2026-02-23 19:14:19+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1957, "out": false, "date": "2026-02-23 19:14:19+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:20.144731+00
c94fb92d-8dfd-47cd-a894-01c22925b0e1	-5211338635	1958	8432659358	2026-02-23 19:14:20+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1958, "out": false, "date": "2026-02-23 19:14:20+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:20.777712+00
44707700-af50-403e-be61-6fdcd089b0be	333	1774368376	1	2026-03-24 16:06:16.666399+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:16.665846+00
15b8157f-6b70-46b5-8695-0f0159fbc2b3	444	1774368376	1	2026-03-24 16:06:16.671586+00	hello	{"x": 1}	f	\N	2026-03-24 16:06:16.67106+00
5498b0ad-44be-4440-a0f6-9ee00f8d1c90	-5211338635	1959	8432659358	2026-02-23 19:14:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1959, "out": false, "date": "2026-02-23 19:14:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:24.442935+00
50dcea71-4c22-4701-a102-9078b34e16b5	-5211338635	1960	8432659358	2026-02-23 19:14:24+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1960, "out": false, "date": "2026-02-23 19:14:24+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:25.307143+00
4ced1fc5-3521-48a7-b503-9073773a8e1f	-5211338635	1961	8432659358	2026-02-23 19:14:25+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1961, "out": false, "date": "2026-02-23 19:14:25+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:26.002394+00
815b5fe1-3152-4ef0-a20d-4122a07ac25e	-5211338635	1962	8432659358	2026-02-23 19:14:26+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1962, "out": false, "date": "2026-02-23 19:14:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:26.673688+00
27e2011d-ab38-4f76-b83e-c1940b93b60e	-5211338635	1963	8432659358	2026-02-23 19:14:26+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1963, "out": false, "date": "2026-02-23 19:14:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:47.622959+00
a9435900-db7b-4f57-b7d7-3b508e1e2162	-1001239815745	1385802693	\N	\N	\N	{}	f	\N	2026-03-24 16:07:04.156571+00
99999999-9999-9999-9999-999999999999	8000064108185	1108185	\N	2026-03-24 18:12:08.106551+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:12:08.095555+00
f124790c-4c00-4cf8-a358-737c0ba95298	-5211338635	1964	8432659358	2026-02-23 19:14:47+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1964, "out": false, "date": "2026-02-23 19:14:47+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:48.380904+00
ee014ba4-bc26-4c91-81ad-0e68c3a2d8ef	-5211338635	1965	8432659358	2026-02-23 19:14:48+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1965, "out": false, "date": "2026-02-23 19:14:48+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:49.033544+00
4d29ec2a-ccfb-4c43-be70-a05d821daa0d	-5211338635	1966	8432659358	2026-02-23 19:14:49+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1966, "out": false, "date": "2026-02-23 19:14:49+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:49.698819+00
6e2e7555-b338-46e4-8028-c9a6f05e97ba	-5211338635	1967	8432659358	2026-02-23 19:14:49+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1967, "out": false, "date": "2026-02-23 19:14:49+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:50.47298+00
23308dfb-2bef-4c07-93e5-4fd3f468d548	-5211338635	1968	8432659358	2026-02-23 19:14:50+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1968, "out": false, "date": "2026-02-23 19:14:50+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:51.188407+00
f90e0255-86b7-4031-a26c-e94d889e8326	-1001239815745	846004462	\N	\N	\N	{}	f	\N	2026-03-24 16:17:10.333717+00
b8302422-07ce-4c71-b78d-41a52ca0fd46	8000002456263	1456263	\N	2026-03-24 18:14:41.146309+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:14:41.142985+00
db47762a-b03a-4bea-bce7-876eb591e6dd	-5211338635	1969	8432659358	2026-02-23 19:14:54+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1969, "out": false, "date": "2026-02-23 19:14:54+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:54.834879+00
95905bda-855a-454a-9084-6503cba560b0	-5211338635	1970	8432659358	2026-02-23 19:14:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1970, "out": false, "date": "2026-02-23 19:14:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:55.45764+00
bba3ce32-2684-4cda-aeb2-752da1a0dc52	-5211338635	1971	8432659358	2026-02-23 19:14:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1971, "out": false, "date": "2026-02-23 19:14:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:56.396401+00
0ca1e8cd-acf5-4a31-896b-8daec2e0409a	-5211338635	1972	8432659358	2026-02-23 19:14:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1972, "out": false, "date": "2026-02-23 19:14:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:14:57.06241+00
b159ce12-f54b-4ef5-8765-824625abb4a7	-5211338635	1973	8432659358	2026-02-23 19:14:57+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1973, "out": false, "date": "2026-02-23 19:14:57+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:18.950315+00
d3c33e6b-4888-4ebe-905c-0ccad2942fd8	-1001239815745	1519312035	\N	\N	\N	{}	f	\N	2026-03-24 16:25:15.085424+00
9714ccbe-cb87-4dd4-97b4-8995f0fc65db	222	1774376081	1	2026-03-24 18:14:41.2877+00	hello	{"x": 1}	f	\N	2026-03-24 18:14:41.286416+00
100ae7d2-633f-4b67-9385-ab4c5dc42628	-5211338635	1974	8432659358	2026-02-23 19:15:19+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1974, "out": false, "date": "2026-02-23 19:15:19+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:19.66257+00
279d0651-7c28-4955-b6d1-5041e610abd7	-5211338635	1975	8432659358	2026-02-23 19:15:19+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1975, "out": false, "date": "2026-02-23 19:15:19+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:20.392347+00
82d5c938-ebf3-45e6-8249-cb3ed1cdb992	-5211338635	1976	8432659358	2026-02-23 19:15:20+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1976, "out": false, "date": "2026-02-23 19:15:20+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:20.936996+00
0371facb-41a6-49b2-b020-466427f03958	-5211338635	1977	8432659358	2026-02-23 19:15:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1977, "out": false, "date": "2026-02-23 19:15:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:21.982283+00
10340f1c-865a-442b-b777-b890417a54df	-5211338635	1978	8432659358	2026-02-23 19:15:22+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1978, "out": false, "date": "2026-02-23 19:15:22+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:22.635085+00
fac9e243-848d-45bb-8c6c-9bdc37821fc6	-1001239815745	688099862	\N	\N	\N	{}	f	\N	2026-03-24 16:26:08.701279+00
4ba75d02-5c5b-4e54-9c6e-406334badc21	222	1774369568	1	2026-03-24 16:26:08.764685+00	hello	{"x": 1}	f	\N	2026-03-24 16:26:08.763928+00
1b4ab366-9991-483b-b044-6dfa64b01076	-5211338635	1979	8432659358	2026-02-23 19:15:25+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1979, "out": false, "date": "2026-02-23 19:15:25+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:26.459193+00
17a18181-963f-4beb-bced-1df9bda0e59c	-5211338635	1980	8432659358	2026-02-23 19:15:26+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1980, "out": false, "date": "2026-02-23 19:15:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:27.365392+00
c746e7b5-2717-4d29-9e7d-35245266baab	-5211338635	1981	8432659358	2026-02-23 19:15:27+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1981, "out": false, "date": "2026-02-23 19:15:27+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:28.182479+00
0df8a006-dae8-425b-b891-b30deca35480	-5211338635	1982	8432659358	2026-02-23 19:15:28+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1982, "out": false, "date": "2026-02-23 19:15:28+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:28.849848+00
af969f5d-b5a6-45f2-9199-8d4c1863030c	-5211338635	1983	8432659358	2026-02-23 19:15:29+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1983, "out": false, "date": "2026-02-23 19:15:29+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:49.720218+00
a49655b3-9405-44a1-ae48-ca0e5ad067e6	333	1774369568	1	2026-03-24 16:26:08.768201+00	hello	{"x": 1}	f	\N	2026-03-24 16:26:08.7675+00
63481efe-283e-40e8-b9a9-7456492ca0fc	444	1774369568	1	2026-03-24 16:26:08.77365+00	hello	{"x": 1}	f	\N	2026-03-24 16:26:08.772828+00
a389124c-a90f-4954-be0b-8f2d3bec50fb	-5211338635	1984	8432659358	2026-02-23 19:15:49+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1984, "out": false, "date": "2026-02-23 19:15:49+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:50.382249+00
9bc97546-23fe-4eb3-9bcc-95ac7f05a564	-5211338635	1985	8432659358	2026-02-23 19:15:50+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1985, "out": false, "date": "2026-02-23 19:15:50+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:50.988218+00
e62c28b8-4443-475a-8eb0-2544941d39a6	-5211338635	1986	8432659358	2026-02-23 19:15:51+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1986, "out": false, "date": "2026-02-23 19:15:51+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:51.750416+00
efefde12-707e-421f-835e-c90901eeaecc	-5211338635	1987	8432659358	2026-02-23 19:15:51+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1987, "out": false, "date": "2026-02-23 19:15:51+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:52.420257+00
5cf1a51d-cc7c-4ff2-a1f7-02f3de44cc5b	-5211338635	1988	8432659358	2026-02-23 19:15:52+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1988, "out": false, "date": "2026-02-23 19:15:52+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:53.034597+00
49f0e3f3-a058-44fc-9d74-f4c8e008e53d	-1001239815745	900001	\N	\N	\N	{}	f	\N	2026-03-24 16:29:24.595768+00
a430edb4-a3bc-472d-ad0e-a60cfa3153a9	-1002298510219	900002	\N	\N	\N	{}	f	\N	2026-03-24 16:29:24.60451+00
2b0b8877-5dc2-440e-b527-ce87565e1dde	-1001239815745	900003	\N	\N	\N	{}	f	\N	2026-03-24 16:29:24.610281+00
fbc82904-df2e-42a0-b611-5ca79053d158	-5211338635	1989	8432659358	2026-02-23 19:15:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1989, "out": false, "date": "2026-02-23 19:15:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:56.719883+00
f54fdff5-3d04-4d0e-861d-411286a73769	-5211338635	1990	8432659358	2026-02-23 19:15:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1990, "out": false, "date": "2026-02-23 19:15:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:57.379024+00
9d0bdc17-dfc8-45a6-ac86-22db2ef985ee	-5211338635	1991	8432659358	2026-02-23 19:15:57+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1991, "out": false, "date": "2026-02-23 19:15:57+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:58.172556+00
b3cde7f7-7f1c-490e-8764-d446cfa76651	-5211338635	1992	8432659358	2026-02-23 19:15:58+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1992, "out": false, "date": "2026-02-23 19:15:58+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:15:58.910085+00
83731929-474b-427c-8a5e-7ff7cf2a4a85	-5211338635	1993	8432659358	2026-02-23 19:15:59+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1993, "out": false, "date": "2026-02-23 19:15:59+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:20.717047+00
95b6f110-e484-4948-8ce4-89482c81904c	-5211338635	1994	8432659358	2026-02-23 19:16:20+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1994, "out": false, "date": "2026-02-23 19:16:20+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:21.389018+00
ece1ec3d-e465-4bce-b6ad-452e5d1d4540	-5211338635	1995	8432659358	2026-02-23 19:16:21+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1995, "out": false, "date": "2026-02-23 19:16:21+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:22.227171+00
9b3c98e3-1280-40c9-83e3-5117ad4a1784	-5211338635	1996	8432659358	2026-02-23 19:16:22+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1996, "out": false, "date": "2026-02-23 19:16:22+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:22.986934+00
af0ed2ef-dc54-4672-86cd-617f0af641a3	-5211338635	1997	8432659358	2026-02-23 19:16:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1997, "out": false, "date": "2026-02-23 19:16:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:24.066171+00
707b400a-3af6-412a-8709-2801805ca2ff	-5211338635	1998	8432659358	2026-02-23 19:16:24+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1998, "out": false, "date": "2026-02-23 19:16:24+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:24.847973+00
45d9c437-4217-43d0-b228-a3fe95483d65	222	1774369786	1	2026-03-24 16:29:46.842004+00	hello	{"x": 1}	f	\N	2026-03-24 16:29:46.841728+00
c52ca687-7794-4a2f-bb77-cee9a5e324c9	333	1774369786	1	2026-03-24 16:29:46.845773+00	hello	{"x": 1}	f	\N	2026-03-24 16:29:46.845669+00
6c151b24-937f-4e23-a19a-165ed5d846ca	-5211338635	1999	8432659358	2026-02-23 19:16:28+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 1999, "out": false, "date": "2026-02-23 19:16:28+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:28.557855+00
7cd9f02b-173a-416a-9b49-a3ff9bcfb001	-5211338635	2000	8432659358	2026-02-23 19:16:28+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2000, "out": false, "date": "2026-02-23 19:16:28+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:29.302206+00
ee559fd4-d72b-4127-aa67-cab32ca1f2a3	-5211338635	2001	8432659358	2026-02-23 19:16:29+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2001, "out": false, "date": "2026-02-23 19:16:29+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:30.098029+00
5d44e7c7-f385-4afc-a1d5-7d5cf2d56b27	-5211338635	2002	8432659358	2026-02-23 19:16:30+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2002, "out": false, "date": "2026-02-23 19:16:30+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:30.682931+00
bcffce4f-fe3b-4e97-847d-63c6fbf20ae9	-5211338635	2003	8432659358	2026-02-23 19:16:30+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2003, "out": false, "date": "2026-02-23 19:16:30+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:52.567829+00
62ed87e3-301d-4a32-b2bd-235ab04b6e66	444	1774369786	1	2026-03-24 16:29:46.851601+00	hello	{"x": 1}	f	\N	2026-03-24 16:29:46.851238+00
75270099-19f8-42ee-b930-638561ef6869	333	1774376081	1	2026-03-24 18:14:41.291129+00	hello	{"x": 1}	f	\N	2026-03-24 18:14:41.289839+00
a42a7490-e652-4ab5-b287-8d469061c42b	-5211338635	2004	8432659358	2026-02-23 19:16:52+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2004, "out": false, "date": "2026-02-23 19:16:52+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:53.527308+00
cafbad6d-adb6-43de-93bf-c13792ba31df	-5211338635	2005	8432659358	2026-02-23 19:16:53+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2005, "out": false, "date": "2026-02-23 19:16:53+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:54.303739+00
2fbd35f0-84ff-4a21-a401-cf4a6680ba98	-5211338635	2006	8432659358	2026-02-23 19:16:54+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2006, "out": false, "date": "2026-02-23 19:16:54+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:54.837583+00
b665c338-2dfc-4321-b431-b04f9603c3f4	-5211338635	2007	8432659358	2026-02-23 19:16:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2007, "out": false, "date": "2026-02-23 19:16:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:55.711864+00
c088aa21-ba18-4b2b-b503-bd5eb188f3f8	-5211338635	2008	8432659358	2026-02-23 19:16:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2008, "out": false, "date": "2026-02-23 19:16:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:56.320074+00
277d6ac9-c1d5-4dea-b2c5-8ff54b3fab8f	-5211338635	2009	8432659358	2026-02-23 19:16:59+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2009, "out": false, "date": "2026-02-23 19:16:59+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:16:59.964004+00
d4c4eb91-ca74-4922-ad49-a267505768a8	-5211338635	2010	8432659358	2026-02-23 19:17:00+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2010, "out": false, "date": "2026-02-23 19:17:00+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:00.51057+00
bb337d13-66e0-438f-b79a-49c57a4d4897	-5211338635	2011	8432659358	2026-02-23 19:17:00+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2011, "out": false, "date": "2026-02-23 19:17:00+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:01.121901+00
fdc1fde1-d28d-4443-a0bd-f277801c91c2	-5211338635	2012	8432659358	2026-02-23 19:17:01+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2012, "out": false, "date": "2026-02-23 19:17:01+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:01.798291+00
826c7586-3359-4a77-a007-c0653081a1ec	-5211338635	2013	8432659358	2026-02-23 19:17:02+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2013, "out": false, "date": "2026-02-23 19:17:02+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:23.721543+00
34318afb-9b3a-4931-a3ec-f2e7ae650a4d	222	1774369809	1	2026-03-24 16:30:09.540576+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:09.540017+00
43482450-bf7c-4845-bf76-a9e6845ced3d	333	1774369809	1	2026-03-24 16:30:09.545305+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:09.544692+00
de6bddbf-e819-4ae2-ac62-ab7b43f1cf0f	-5211338635	2014	8432659358	2026-02-23 19:17:23+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2014, "out": false, "date": "2026-02-23 19:17:23+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:24.35231+00
5ab143aa-207f-41f3-9e6f-afaaef03b636	-5211338635	2015	8432659358	2026-02-23 19:17:24+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2015, "out": false, "date": "2026-02-23 19:17:24+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:25.0736+00
5a11c1fd-ebf9-4937-a55e-3fcb2e978acc	-5211338635	2016	8432659358	2026-02-23 19:17:25+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2016, "out": false, "date": "2026-02-23 19:17:25+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:25.693311+00
65048d95-6fb8-450a-ba68-03457a38dda8	-5211338635	2017	8432659358	2026-02-23 19:17:25+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2017, "out": false, "date": "2026-02-23 19:17:25+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:26.235393+00
c16df9af-f3a5-42be-9870-47c56be70883	-5211338635	2018	8432659358	2026-02-23 19:17:26+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2018, "out": false, "date": "2026-02-23 19:17:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:26.794561+00
8211dfe9-6cdc-41b5-bc4d-7dfbf8ef43d1	444	1774369809	1	2026-03-24 16:30:09.550699+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:09.549986+00
f4d08306-d4c8-48be-880e-fbd58d296710	444	1774376081	1	2026-03-24 18:14:41.296776+00	hello	{"x": 1}	f	\N	2026-03-24 18:14:41.295449+00
fa95fe51-0d5d-4883-b7c8-657b59301673	-5211338635	2019	8432659358	2026-02-23 19:17:30+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2019, "out": false, "date": "2026-02-23 19:17:30+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:30.502385+00
ba60e2c1-6e21-4965-ba21-5c90a880674c	-5211338635	2020	8432659358	2026-02-23 19:17:30+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2020, "out": false, "date": "2026-02-23 19:17:30+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:31.364808+00
968ae8a3-1b69-4f88-9f80-05d76b46ca61	-5211338635	2021	8432659358	2026-02-23 19:17:31+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2021, "out": false, "date": "2026-02-23 19:17:31+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:32.067176+00
91f00071-d538-4124-9dee-e586a6fbfefa	-5211338635	2022	8432659358	2026-02-23 19:17:32+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2022, "out": false, "date": "2026-02-23 19:17:32+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:32.638707+00
adf9fbcb-5bf9-4eff-9b0b-ddaef66314b3	-5211338635	2023	8432659358	2026-02-23 19:17:32+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2023, "out": false, "date": "2026-02-23 19:17:32+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:55.487457+00
5f7d7126-8ff9-4a74-be82-ae8460fbfc9e	222	1774369844	1	2026-03-24 16:30:44.639533+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:44.638832+00
1ab73268-08d4-48c0-b7e0-affde432da6d	333	1774369844	1	2026-03-24 16:30:44.643431+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:44.642797+00
61975c75-f50b-437b-bbff-a73287d02fe1	-5211338635	2024	8432659358	2026-02-23 19:17:55+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2024, "out": false, "date": "2026-02-23 19:17:55+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:56.105292+00
467be1e9-bc00-4388-b1c1-6635534f515c	-5211338635	2025	8432659358	2026-02-23 19:17:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2025, "out": false, "date": "2026-02-23 19:17:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:56.595466+00
dd11bb53-878c-41ab-bc9f-632bfeb3536c	-5211338635	2026	8432659358	2026-02-23 19:17:56+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2026, "out": false, "date": "2026-02-23 19:17:56+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:57.207091+00
faa7556b-e8f6-477c-b92d-8165e9f86fd6	-5211338635	2027	8432659358	2026-02-23 19:17:57+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2027, "out": false, "date": "2026-02-23 19:17:57+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:57.817551+00
95193feb-584b-42e1-b039-5ffc96ced5f0	-5211338635	2028	8432659358	2026-02-23 19:17:58+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2028, "out": false, "date": "2026-02-23 19:17:58+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:17:58.501656+00
dbdcef20-553c-459b-a0c2-9f7e1e88ea8b	444	1774369844	1	2026-03-24 16:30:44.648856+00	hello	{"x": 1}	f	\N	2026-03-24 16:30:44.648243+00
3f13fff7-6f1f-41df-bb28-09ced07cd5cd	-1001239815745	1031821	\N	\N	seed	{}	f	\N	2026-04-03 20:40:16.838117+00
4ec6e5ad-8900-4f13-a941-170904b2f677	-5211338635	2029	8432659358	2026-02-23 19:18:01+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2029, "out": false, "date": "2026-02-23 19:18:01+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:02.372674+00
fdc6895f-e3f6-480f-ac21-66fd109126dc	-5211338635	2030	8432659358	2026-02-23 19:18:02+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2030, "out": false, "date": "2026-02-23 19:18:02+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:03.20407+00
4692ffc0-a90a-495d-ad8d-4b6c3be89637	-5211338635	2031	8432659358	2026-02-23 19:18:03+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2031, "out": false, "date": "2026-02-23 19:18:03+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:03.967252+00
2b75dd81-0d37-43d4-891d-8c2908869714	-5211338635	2032	8432659358	2026-02-23 19:18:04+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2032, "out": false, "date": "2026-02-23 19:18:04+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:04.532386+00
261921ae-157c-4ade-9bd1-263c56063111	-5211338635	2033	8432659358	2026-02-23 19:18:04+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2033, "out": false, "date": "2026-02-23 19:18:04+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:27.226919+00
2cb54364-5ae2-4ce6-96af-31553fc6a54c	-1001239815745	910001	\N	\N	BUY GOLD now\nSL 2010\nTP 2030 2040	{}	f	\N	2026-03-24 16:34:35.958339+00
fd991847-43d8-4e83-b231-537e0dcad552	-1001239815745	910002	\N	\N	BUY GOLD now\nSL 2010\nTP 2030	{}	f	\N	2026-03-24 16:34:36.088486+00
90c74a30-8a87-4b81-b0bf-81872fa20347	-5211338635	2034	8432659358	2026-02-23 19:18:27+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2034, "out": false, "date": "2026-02-23 19:18:27+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:27.855656+00
70f89e61-3a09-4999-a17b-538cef2c03b9	-5211338635	2035	8432659358	2026-02-23 19:18:28+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2035, "out": false, "date": "2026-02-23 19:18:28+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:28.578886+00
4ee94be8-a1e1-4114-a620-64aacb4c5ee2	-5211338635	2036	8432659358	2026-02-23 19:18:28+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2036, "out": false, "date": "2026-02-23 19:18:28+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:29.212514+00
2938c324-c59d-4b5a-afb4-ffa0d6f92e3f	-5211338635	2037	8432659358	2026-02-23 19:18:29+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2037, "out": false, "date": "2026-02-23 19:18:29+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:29.876609+00
080bf636-dc7a-4297-9e62-e6c76a625b2b	-5211338635	2038	8432659358	2026-02-23 19:18:30+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2038, "out": false, "date": "2026-02-23 19:18:30+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:30.691113+00
5919aa78-bbc9-4d34-9378-0a81ca7f47a0	-1002298510219	910003	\N	\N	BTC update: TP1 to 53000	{}	f	\N	2026-03-24 16:34:36.205366+00
aa77a3c8-a664-479c-a184-462a1862f7eb	-1001239815745	1048779	\N	\N	seed	{}	f	\N	2026-04-03 20:40:36.001292+00
e38f40ba-452f-4955-9daf-c91f255e7373	-5211338635	2039	8432659358	2026-02-23 19:18:33+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2039, "out": false, "date": "2026-02-23 19:18:33+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:34.44306+00
c556692a-9979-4ebb-8006-5713053df18d	-5211338635	2040	8432659358	2026-02-23 19:18:34+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2040, "out": false, "date": "2026-02-23 19:18:34+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:35.219811+00
7965b242-7954-44f8-b82c-879cd3bf060c	-5211338635	2041	8432659358	2026-02-23 19:18:35+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2041, "out": false, "date": "2026-02-23 19:18:35+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:35.969113+00
0ea4deb0-12da-423d-aef9-4898766fefa7	-5211338635	2042	8432659358	2026-02-23 19:18:36+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2042, "out": false, "date": "2026-02-23 19:18:36+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:36.622661+00
aa9d07fb-f700-4e47-a49f-2aadf62a0d49	-5211338635	2043	8432659358	2026-02-23 19:18:36+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2043, "out": false, "date": "2026-02-23 19:18:36+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:58.472926+00
f9d65699-8e23-4d17-88ff-0367beea7931	222	1774370116	1	2026-03-24 16:35:16.122536+00	hello	{"x": 1}	f	\N	2026-03-24 16:35:16.121934+00
87203eab-3546-42d1-a786-5f41990d9f24	333	1774370116	1	2026-03-24 16:35:16.126716+00	hello	{"x": 1}	f	\N	2026-03-24 16:35:16.125976+00
8e6d6325-ccc9-4876-a170-862866c378f0	-5211338635	2044	8432659358	2026-02-23 19:18:58+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2044, "out": false, "date": "2026-02-23 19:18:58+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:59.13107+00
81895277-5a1e-41b0-b397-a1199cf08a4b	-5211338635	2045	8432659358	2026-02-23 19:18:59+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2045, "out": false, "date": "2026-02-23 19:18:59+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:18:59.774923+00
1e005bcd-0be9-40d4-a732-4d9b1219cbd8	-5211338635	2046	8432659358	2026-02-23 19:19:00+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2046, "out": false, "date": "2026-02-23 19:19:00+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:00.802649+00
25afa4e7-67b9-42a8-ba20-885de29ba4a6	-5211338635	2047	8432659358	2026-02-23 19:19:00+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2047, "out": false, "date": "2026-02-23 19:19:00+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:01.638967+00
3d22d1ec-9e18-49ea-b2ac-94ac141a3848	-5211338635	2048	8432659358	2026-02-23 19:19:01+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2048, "out": false, "date": "2026-02-23 19:19:01+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:02.492896+00
860f9956-915f-43da-8e31-b0e333ab87f0	444	1774370116	1	2026-03-24 16:35:16.132789+00	hello	{"x": 1}	f	\N	2026-03-24 16:35:16.131963+00
7f7e2df3-752a-4808-a076-0153328ad287	-1001239815745	1016775	\N	\N	seed	{}	f	\N	2026-04-03 20:40:36.01819+00
a0cd2232-2fe1-4f19-905a-6c8bbdf298d0	-5211338635	2049	8432659358	2026-02-23 19:19:05+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2049, "out": false, "date": "2026-02-23 19:19:05+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:06.26409+00
c8882e34-1f3f-480e-9628-a5005fe44406	-5211338635	2050	8432659358	2026-02-23 19:19:06+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2050, "out": false, "date": "2026-02-23 19:19:06+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:07.101825+00
78960426-c895-4bfd-9a8f-97c74f0d8150	-5211338635	2051	8432659358	2026-02-23 19:19:07+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2051, "out": false, "date": "2026-02-23 19:19:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:07.969137+00
52979eef-8220-49fd-8223-b51fa9eabe6e	-5211338635	2052	8432659358	2026-02-23 19:19:08+00	🚨 ROUTING ALERT\n\nUnknown chat_id -5211338635\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -5211338635	{"_": "Message", "id": 2052, "out": false, "date": "2026-02-23 19:19:08+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -5211338635\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 11, "offset": 34}, {"_": "MessageEntityCode", "length": 34, "offset": 77}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:19:08.578728+00
583969b9-7c79-4ac1-bfaf-0bc7bcebc400	-5211338635	2054	7622982526	2026-02-23 19:20:32+00	Test	{"_": "Message", "id": 2054, "out": true, "date": "2026-02-23 19:20:32+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "Test", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:20:32.828148+00
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa	8000004564650	1564650	\N	2026-03-24 18:21:46.753449+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606\nTP2 4610\nTP3 4613\nTP4 4626\n	{}	f	\N	2026-03-24 18:21:46.745636+00
356f6b7f-e577-4cc4-a41d-9dc83ed2e823	-1001239815745	1043907	\N	\N	seed	{}	f	\N	2026-04-03 20:40:36.026382+00
1df792f5-3619-405e-a554-10756fc9d3fd	-1003254187278	993991	\N	\N	seed trade	{}	f	\N	2026-04-03 21:02:50.065587+00
9f8bcf59-ae30-42f7-82d8-2c70e77ca384	-5211338635	2055	7622982526	2026-02-23 19:22:28+00	!showrouting	{"_": "Message", "id": 2055, "out": true, "date": "2026-02-23 19:22:28+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:22:28.930501+00
547a23a2-ef75-48e0-8e04-a4c34c9eab2d	-5211338635	2056	7622982526	2026-02-23 19:22:37+00	!health	{"_": "Message", "id": 2056, "out": true, "date": "2026-02-23 19:22:37+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!health", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:22:37.628102+00
d280de83-03a3-45ce-b11e-31790dbcca47	-5211338635	2057	8432659358	2026-02-23 19:22:37+00	✅ health\nDB: ok\nlast_ingested: 2026-02-23 19:22:37.628102+00:00\ncontrol_chat_id: -5211338635	{"_": "Message", "id": 2057, "out": false, "date": "2026-02-23 19:22:37+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ health\\nDB: ok\\nlast_ingested: 2026-02-23 19:22:37.628102+00:00\\ncontrol_chat_id: -5211338635", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:22:38.243088+00
54742f9a-dd6f-4a8a-b61c-f8ac4e4c8346	-5211338635	2058	7622982526	2026-02-23 19:23:49+00	Test	{"_": "Message", "id": 2058, "out": true, "date": "2026-02-23 19:23:49+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "Test", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:23:49.755374+00
fd998490-30fa-4302-a8ee-2a7a07edf821	-5211338635	2059	7622982526	2026-02-23 19:31:55+00	!showrouting	{"_": "Message", "id": 2059, "out": true, "date": "2026-02-23 19:31:55+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:31:55.983679+00
7e040388-2904-43f6-8d80-2882eb109720	-5211338635	2060	7622982526	2026-02-23 19:34:04+00	!showrouting	{"_": "Message", "id": 2060, "out": true, "date": "2026-02-23 19:34:04+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:34:05.155632+00
22222222-2222-2222-2222-222222222222	8000080912930	1912930	\N	2026-03-24 17:56:09.907492+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 17:56:09.899268+00
2693c1fb-603c-4a15-8984-e33465512b6c	8000025827745	1827745	\N	2026-03-24 18:26:55.461094+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:26:55.45374+00
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb	-1002298510219	990001	\N	\N	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606\nTP2 4610\nTP3 4613\nTP4 4626\n	{}	f	\N	2026-04-03 20:12:24.224722+00
e73bc068-b3f0-4196-a906-c2c5d607d907	-1001239815745	1016151	\N	\N	seed	{}	f	\N	2026-04-03 20:44:28.893629+00
b9664d5d-534b-40a3-a23f-692c40a7e778	-1001239815745	991688	\N	\N	seed	{}	f	\N	2026-04-03 20:44:28.900736+00
1e441748-cd52-4310-95f7-bc7bf8122561	-5211338635	2061	8432659358	2026-02-23 19:34:05+00	📌 Current routing\n\nbillionaire_club\n• Channels:\n  - -1003254187278\n  - -1002997989063\n  - -1002467468850\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\n\nfredtrading\n• Channels:\n  - -1002208969496\n  - -1001979286278\n  - -1001239815745\n• Target account: 21ef5d9a-3798-4990-9839-32e1e8dd37ba (ftmo/mt5/prop_funded) — FTMO - Execution\n\nmubeen\n• Channels:\n  - -1002808934766\n  - -1002298510219\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution	{"_": "Message", "id": 2061, "out": false, "date": "2026-02-23 19:34:05+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "📌 Current routing\\n\\nbillionaire_club\\n• Channels:\\n  - -1003254187278\\n  - -1002997989063\\n  - -1002467468850\\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\\n\\nfredtrading\\n• Channels:\\n  - -1002208969496\\n  - -1001979286278\\n  - -1001239815745\\n• Target account: 21ef5d9a-3798-4990-9839-32e1e8dd37ba (ftmo/mt5/prop_funded) — FTMO - Execution\\n\\nmubeen\\n• Channels:\\n  - -1002808934766\\n  - -1002298510219\\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 15, "offset": 3}, {"_": "MessageEntityBold", "length": 16, "offset": 20}, {"_": "MessageEntityCode", "length": 14, "offset": 53}, {"_": "MessageEntityCode", "length": 14, "offset": 72}, {"_": "MessageEntityCode", "length": 14, "offset": 91}, {"_": "MessageEntityCode", "length": 36, "offset": 124}, {"_": "MessageEntityBold", "length": 11, "offset": 218}, {"_": "MessageEntityCode", "length": 14, "offset": 246}, {"_": "MessageEntityCode", "length": 14, "offset": 265}, {"_": "MessageEntityCode", "length": 14, "offset": 284}, {"_": "MessageEntityCode", "length": 36, "offset": 317}, {"_": "MessageEntityBold", "length": 6, "offset": 397}, {"_": "MessageEntityCode", "length": 14, "offset": 420}, {"_": "MessageEntityCode", "length": 14, "offset": 439}, {"_": "MessageEntityCode", "length": 36, "offset": 472}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:34:05.879591+00
8492ddef-269c-40de-b31b-6da99b2e380d	-5211338635	2062	7622982526	2026-02-23 19:36:06+00	/health	{"_": "Message", "id": 2062, "out": true, "date": "2026-02-23 19:36:06+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "/health", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBotCommand", "length": 7, "offset": 0}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 19:36:06.310986+00
a29ec40e-7201-4753-a4a9-f45d82bac8a7	-5211338635	2063	8432659358	2026-02-23 19:36:06+00	🩺 Health\n• DB: OK ✅\n• Mapped chats: 8\n• Active provider routes: 3\n• Last telegram message: 2026-02-23 19:36:06+00:00\n• Last routing decision: 2026-02-23 19:19:08.578728+00:00	{"_": "Message", "id": 2063, "out": false, "date": "2026-02-23 19:36:06+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🩺 Health\\n• DB: OK ✅\\n• Mapped chats: 8\\n• Active provider routes: 3\\n• Last telegram message: 2026-02-23 19:36:06+00:00\\n• Last routing decision: 2026-02-23 19:19:08.578728+00:00", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 6, "offset": 3}, {"_": "MessageEntityBold", "length": 1, "offset": 37}, {"_": "MessageEntityBold", "length": 1, "offset": 65}, {"_": "MessageEntityCode", "length": 25, "offset": 92}, {"_": "MessageEntityCode", "length": 32, "offset": 143}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 19:36:07.363497+00
4a538009-4124-45c3-bd1f-17c01b914684	-1001239815745	1771875923	123456	2026-02-23 19:45:23.028882+00	SIMULATED MESSAGE: happy path	{"case": "happy_path", "simulated": true}	f	\N	2026-02-23 19:45:23.072698+00
6fcb3c42-6125-431c-b619-c6680b9687b6	-1001239815745	1771875924	123456	2026-02-23 19:45:23.085398+00	SIMULATED MESSAGE: unknown mapping	{"case": "unknown_mapping", "simulated": true}	f	\N	2026-02-23 19:45:23.085455+00
89eef95c-8747-4829-8d44-16c9dd137c26	-1001239815745	1771875925	123456	2026-02-23 19:45:23.092553+00	SIMULATED MESSAGE: no active route	{"case": "no_active_route", "simulated": true}	f	\N	2026-02-23 19:45:23.09335+00
55aef8ed-0d84-483c-85f1-b41a9fdccd20	-1001234567890	42	111	2026-02-23 19:53:52.74029+00	hello	{"id": 42, "date": "2026-02-23T19:53:52.740283+00:00", "message": "hello"}	f	\N	2026-02-23 19:53:52.738629+00
94570764-0520-4597-9eb2-3367a1abaf92	333	1771876432	1	2026-02-23 19:53:52.875396+00	hello	{"x": 1}	f	\N	2026-02-23 19:53:52.874342+00
4cbf6e16-406e-4974-991c-e84eef2dff21	333	1771876551	1	2026-02-23 19:55:51.667188+00	hello	{"x": 1}	f	\N	2026-02-23 19:55:51.667262+00
7596dab4-73a8-4759-84d2-61163f469593	333	1771876626	1	2026-02-23 19:57:06.938349+00	hello	{"x": 1}	f	\N	2026-02-23 19:57:06.939236+00
7802988a-451e-4751-9b5d-1e2884409f01	333	1771876693	1	2026-02-23 19:58:13.687545+00	hello	{"x": 1}	f	\N	2026-02-23 19:58:13.688087+00
463407b7-d66b-4533-830f-f77138490caa	333	1771876731	1	2026-02-23 19:58:51.851478+00	hello	{"x": 1}	f	\N	2026-02-23 19:58:51.85102+00
1e7fd268-2db6-4b6c-95e4-6b22cb185444	333	1771876761	1	2026-02-23 19:59:21.862721+00	hello	{"x": 1}	f	\N	2026-02-23 19:59:21.862519+00
9a7eae58-2237-4d7d-8824-139940ac9e9f	333	1771876967	1	2026-02-23 20:02:47.599524+00	hello	{"x": 1}	f	\N	2026-02-23 20:02:47.599185+00
bcc71cf1-e071-40eb-ab5e-a8b3d52ccf55	-1002298510219	1946	-1002298510219	2026-02-23 20:22:54+00	🔥Running 🔥\n       +400	{"_": "Message", "id": 1946, "out": false, "date": "2026-02-23 20:22:54+00:00", "post": true, "_meta": {"event_chat_id_raw": -1002298510219, "chat_id_normalized": -1002298510219}, "media": null, "views": 2, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": null, "message": "🔥Running 🔥\\n       +400", "offline": false, "peer_id": {"_": "PeerChannel", "channel_id": 2298510219}, "replies": null, "entities": [], "forwards": 0, "fwd_from": null, "reply_to": {"_": "MessageReplyHeader", "quote": false, "quote_text": null, "reply_from": null, "forum_topic": false, "reply_media": null, "quote_offset": null, "todo_item_id": null, "quote_entities": [], "reply_to_msg_id": 1936, "reply_to_top_id": null, "reply_to_peer_id": null, "reply_to_scheduled": false}, "edit_date": "2026-02-23 20:23:06+00:00", "edit_hide": true, "factcheck": null, "mentioned": false, "reactions": {"_": "MessageReactions", "min": false, "results": [], "can_see_list": false, "top_reactors": [], "recent_reactions": [], "reactions_as_tags": false}, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": "Mubeen", "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	t	2026-02-23 20:23:06+00	2026-02-23 20:22:54.622113+00
c160040c-5506-4a47-8a9b-828333c90c15	-5211338635	2072	7622982526	2026-02-23 20:34:11+00	!whoami	{"_": "Message", "id": 2072, "out": true, "date": "2026-02-23 20:34:11+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!whoami", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:34:12.01963+00
ec11a18c-69be-4116-8a63-c06824f32334	-5211338635	2073	8432659358	2026-02-23 20:34:11+00	⛔ Not authorized.	{"_": "Message", "id": 2073, "out": false, "date": "2026-02-23 20:34:11+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "⛔ Not authorized.", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:34:12.161167+00
cb82f901-2b68-436e-87ab-1b366f607e93	-5211338635	2074	7622982526	2026-02-23 20:36:07+00	!whoami	{"_": "Message", "id": 2074, "out": true, "date": "2026-02-23 20:36:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!whoami", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:36:08.157158+00
3dc7dfa8-fd46-4700-8be1-f0fcb418104f	-5211338635	2075	8432659358	2026-02-23 20:36:07+00	⛔ Not authorized.	{"_": "Message", "id": 2075, "out": false, "date": "2026-02-23 20:36:07+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "⛔ Not authorized.", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:36:08.346956+00
f845a57c-28eb-4581-aee7-7b1ff72febb9	-5211338635	2076	7622982526	2026-02-23 20:38:03+00	!whoami	{"_": "Message", "id": 2076, "out": true, "date": "2026-02-23 20:38:03+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!whoami", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:38:03.852726+00
41420677-e278-4515-9525-409729ee0f65	-5211338635	2077	8432659358	2026-02-23 20:38:03+00	⛔ Not authorized.	{"_": "Message", "id": 2077, "out": false, "date": "2026-02-23 20:38:03+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "⛔ Not authorized.", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:38:04.063447+00
9798d466-25f1-45f9-9548-b69b0530915b	-5211338635	2078	7622982526	2026-02-23 20:39:53+00	!whoami	{"_": "Message", "id": 2078, "out": true, "date": "2026-02-23 20:39:53+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!whoami", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:39:54.432191+00
1808c240-9380-4820-9d05-5bf36411ac74	-5211338635	2079	8432659358	2026-02-23 20:39:54+00	⛔ Not authorized.	{"_": "Message", "id": 2079, "out": false, "date": "2026-02-23 20:39:54+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "⛔ Not authorized.", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:39:54.666564+00
1fc77442-7d30-4481-abaf-a0c4087a157a	-5211338635	2085	7622982526	2026-02-23 20:44:26+00	!showrouting	{"_": "Message", "id": 2085, "out": true, "date": "2026-02-23 20:44:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:26.872588+00
02b4d776-b231-4ce5-a1be-81fcbfb50452	222	1774375049	1	2026-03-24 17:57:29.18101+00	hello	{"x": 1}	f	\N	2026-03-24 17:57:29.180466+00
602b3e3e-80e6-49be-a3da-0228cbb08f1d	8000013194395	1194395	\N	2026-03-24 18:27:02.313705+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-03-24 18:27:02.311575+00
adb4c9ad-2b6a-4bd2-b6b1-e3b284d971b2	333	1774376822	1	2026-03-24 18:27:02.42842+00	hello	{"x": 1}	f	\N	2026-03-24 18:27:02.42785+00
557c25a7-5c28-46ec-b020-414afe2b2f19	444	1774376822	1	2026-03-24 18:27:02.433619+00	hello	{"x": 1}	f	\N	2026-03-24 18:27:02.433012+00
7054009c-a865-4261-880f-be2f48eb2a8b	8000045733158	1733158	\N	2026-04-03 20:18:21.884093+00	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{}	f	\N	2026-04-03 20:18:21.879648+00
6967f7be-6081-4433-a653-324228c2a222	-1001239815745	1088274	\N	\N	seed	{}	f	\N	2026-04-03 20:44:28.905251+00
db00dc25-1341-4a01-a247-73750b0866ca	-1001239815745	994778	\N	\N	seed	{}	f	\N	2026-04-03 20:44:28.908225+00
dd674525-c8ad-4622-8b31-87b1e4e09125	-1001239815745	960001	\N	\N	seed	{}	f	\N	2026-04-03 20:57:32.607904+00
ab0f59ac-5e14-4dd0-9b17-01a2e7ecfcab	-1003254187278	993992	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:02:50.078933+00
c5d23d9c-9d0a-4999-8916-fefabd1ef16c	-1003254187278	988945	\N	\N	seed trade	{}	f	\N	2026-04-03 21:07:44.477234+00
087634b0-1e83-418e-8c0c-8da09f911adb	-1003254187278	988946	\N	\N	Position is running nicely! I will Move stop loss to break even!	{}	t	\N	2026-04-03 21:07:44.504832+00
0a553bc3-8689-457c-85ca-42690397932a	-1001239815745	1019962	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.23103+00
fbb197c2-2ff3-4742-9f6d-03a7afa44509	-1001239815745	1082105	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.237922+00
79e2e5ee-2079-4815-bb26-0ddcabb25811	-1001239815745	1001217	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.242417+00
134bbb9a-73e8-4984-abb5-9686fa861b31	-1001239815745	1030913	\N	\N	seed	{}	f	\N	2026-04-03 21:27:57.244792+00
43c2eb86-3455-48ab-8275-262bb9ee866a	-1001239815745	930001	\N	\N	seed	{}	f	\N	2026-04-03 22:17:26.49059+00
a140d085-8ba5-4f7b-b944-89444051455f	-1001239815745	991662	\N	\N	seed	{}	f	\N	2026-04-03 22:18:52.136249+00
f94bbb91-972c-4e07-984b-5d18647bac75	-1001239815745	983443	\N	\N	seed	{}	f	\N	2026-04-03 22:18:52.149992+00
58b642b5-8114-4957-84bb-689143080a9a	-1001239815745	944206	\N	\N	seed	{}	f	\N	2026-04-03 22:18:52.158023+00
9de4a6b9-9d0f-4fa5-aba1-d48046f2fccb	-5211338635	2080	8432659358	2026-02-23 20:41:26+00	🚨 ROUTING ALERT\n\nUnknown chat_id -1001239815745\nMessage ignored.\n\nAdd mapping:\n!addchannel <provider> -1001239815745	{"_": "Message", "id": 2080, "out": false, "date": "2026-02-23 20:41:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "🚨 ROUTING ALERT\\n\\nUnknown chat_id -1001239815745\\nMessage ignored.\\n\\nAdd mapping:\\n!addchannel <provider> -1001239815745", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 14, "offset": 34}, {"_": "MessageEntityCode", "length": 37, "offset": 80}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:41:26.794543+00
adcdd1cb-7e21-4b34-961a-fe217d053bb5	-5211338635	2081	7622982526	2026-02-23 20:41:37+00	!whoami	{"_": "Message", "id": 2081, "out": true, "date": "2026-02-23 20:41:37+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!whoami", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:41:38.41146+00
9b9c6073-ac9c-4b13-a15e-fa33215df647	-5211338635	2082	8432659358	2026-02-23 20:41:38+00	👤 Your Telegram user_id: 7622982526	{"_": "Message", "id": 2082, "out": false, "date": "2026-02-23 20:41:38+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "👤 Your Telegram user_id: 7622982526", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityCode", "length": 10, "offset": 26}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:41:38.608614+00
73b0d5b1-6e94-4ee7-99ce-66d0bcf63c59	-5211338635	2083	103751272	2026-02-23 20:43:19+00	!showrouting	{"_": "Message", "id": 2083, "out": false, "date": "2026-02-23 20:43:19+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 103751272}, "message": "!showrouting", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:43:19.556887+00
c8e67796-52e5-4aeb-915b-7fbf16e4c04b	-5211338635	2084	8432659358	2026-02-23 20:43:19+00	⛔ Not authorized.	{"_": "Message", "id": 2084, "out": false, "date": "2026-02-23 20:43:19+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "⛔ Not authorized.", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:43:19.728158+00
a8ac39b3-8333-42a8-b278-90a343921f97	-5211338635	2086	8432659358	2026-02-23 20:44:26+00	📌 Current routing\n\nbillionaire_club\n• Channels:\n  - -1003254187278\n  - -1002997989063\n  - -1002467468850\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\n\nfredtrading\n• Channels:\n  - -1002208969496\n  - -1001979286278\n  - 111\n  - 222 — test\n  - 444 — test\n  - 777001\n• Target account: 84ae6451-c235-4f91-a058-7d9d6a72ff13 (ftmo/mt5/personal_live) — test-ftmo\n\nmubeen\n• Channels:\n  - -1002808934766\n  - -1002298510219 — Mubeen Trading\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution	{"_": "Message", "id": 2086, "out": false, "date": "2026-02-23 20:44:26+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "📌 Current routing\\n\\nbillionaire_club\\n• Channels:\\n  - -1003254187278\\n  - -1002997989063\\n  - -1002467468850\\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\\n\\nfredtrading\\n• Channels:\\n  - -1002208969496\\n  - -1001979286278\\n  - 111\\n  - 222 — test\\n  - 444 — test\\n  - 777001\\n• Target account: 84ae6451-c235-4f91-a058-7d9d6a72ff13 (ftmo/mt5/personal_live) — test-ftmo\\n\\nmubeen\\n• Channels:\\n  - -1002808934766\\n  - -1002298510219 — Mubeen Trading\\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 15, "offset": 3}, {"_": "MessageEntityBold", "length": 16, "offset": 20}, {"_": "MessageEntityCode", "length": 14, "offset": 53}, {"_": "MessageEntityCode", "length": 14, "offset": 72}, {"_": "MessageEntityCode", "length": 14, "offset": 91}, {"_": "MessageEntityCode", "length": 36, "offset": 124}, {"_": "MessageEntityBold", "length": 11, "offset": 218}, {"_": "MessageEntityCode", "length": 14, "offset": 246}, {"_": "MessageEntityCode", "length": 14, "offset": 265}, {"_": "MessageEntityCode", "length": 3, "offset": 284}, {"_": "MessageEntityCode", "length": 10, "offset": 292}, {"_": "MessageEntityCode", "length": 10, "offset": 307}, {"_": "MessageEntityCode", "length": 6, "offset": 322}, {"_": "MessageEntityCode", "length": 36, "offset": 347}, {"_": "MessageEntityBold", "length": 6, "offset": 422}, {"_": "MessageEntityCode", "length": 14, "offset": 445}, {"_": "MessageEntityCode", "length": 31, "offset": 464}, {"_": "MessageEntityCode", "length": 36, "offset": 514}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:26.975682+00
6baeac96-72ca-48d4-bbaf-63bc62b6c40e	-5211338635	2087	7622982526	2026-02-23 20:44:38+00	!addchannel	{"_": "Message", "id": 2087, "out": true, "date": "2026-02-23 20:44:38+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!addchannel", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:38.807743+00
322fe7fe-b642-46a2-88e6-827202f054b2	-5211338635	2088	8432659358	2026-02-23 20:44:38+00	Usage\n!addchannel <provider> <channel_id>\n!removechannel <provider> <channel_id>	{"_": "Message", "id": 2088, "out": false, "date": "2026-02-23 20:44:38+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "Usage\\n!addchannel <provider> <channel_id>\\n!removechannel <provider> <channel_id>", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 5, "offset": 0}, {"_": "MessageEntityCode", "length": 35, "offset": 6}, {"_": "MessageEntityCode", "length": 38, "offset": 42}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:39.150485+00
46699d06-0423-48d2-b4a1-90b3c9d36c09	-5211338635	2089	7622982526	2026-02-23 20:44:46+00	!removechannel	{"_": "Message", "id": 2089, "out": true, "date": "2026-02-23 20:44:46+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!removechannel", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:47.424742+00
6117e829-c19e-400e-b5cf-168c648bd6d0	-5211338635	2090	8432659358	2026-02-23 20:44:46+00	Usage\n!addchannel <provider> <channel_id>\n!removechannel <provider> <channel_id>	{"_": "Message", "id": 2090, "out": false, "date": "2026-02-23 20:44:46+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "Usage\\n!addchannel <provider> <channel_id>\\n!removechannel <provider> <channel_id>", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 5, "offset": 0}, {"_": "MessageEntityCode", "length": 35, "offset": 6}, {"_": "MessageEntityCode", "length": 38, "offset": 42}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:44:47.512691+00
c6dd236b-f945-418b-8210-91f135e5ec0f	333	1771879546	1	2026-02-23 20:45:46.771109+00	hello	{"x": 1}	f	\N	2026-02-23 20:45:46.770777+00
1ad39d3b-083a-4797-9b79-2d4617606cfc	-5211338635	2092	7622982526	2026-02-23 20:59:01+00	!addchannel fredtrading -1001239815745	{"_": "Message", "id": 2092, "out": true, "date": "2026-02-23 20:59:01+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!addchannel fredtrading -1001239815745", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 20:59:01.374546+00
c4bd9bc5-d01d-4fa9-9223-df7fad3ab3de	-5211338635	2093	8432659358	2026-02-23 20:59:01+00	✅ Channel mapped\n• provider: fredtrading\n• chat_id: -1001239815745	{"_": "Message", "id": 2093, "out": false, "date": "2026-02-23 20:59:01+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "✅ Channel mapped\\n• provider: fredtrading\\n• chat_id: -1001239815745", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 14, "offset": 2}, {"_": "MessageEntityCode", "length": 11, "offset": 29}, {"_": "MessageEntityCode", "length": 14, "offset": 52}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 20:59:01.880439+00
2f7c53e9-a899-4673-a3f0-4b41d76711da	333	1771880390	1	2026-02-23 20:59:50.315869+00	hello	{"x": 1}	f	\N	2026-02-23 20:59:50.315948+00
0e643ff1-5e38-4e93-bf5e-2ec3e41127f5	-5211338635	2094	7622982526	2026-02-23 21:02:37+00	!showrouting	{"_": "Message", "id": 2094, "out": true, "date": "2026-02-23 21:02:37+00:00", "post": false, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": {"_": "PeerUser", "user_id": 7622982526}, "message": "!showrouting", "offline": false, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	f	\N	2026-02-23 21:02:37.351306+00
95483a18-1cf5-4104-90ea-a14ec30db7d3	-5211338635	2095	8432659358	2026-02-23 21:02:37+00	📌 Current routing\n\nbillionaire_club\n• Channels:\n  - -1003254187278\n  - -1002997989063\n  - -1002467468850\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\n\nfredtrading\n• Channels:\n  - -1002208969496\n  - -1001979286278\n  - -1001239815745 — Fredtrading - VIP - Main channel\n• Target account: 0bf2975d-3c7f-4573-b6f2-97d4d6ae3f4a (ftmo/mt5/personal_live) — test-ftmo\n\nmubeen\n• Channels:\n  - -1002808934766\n  - -1002298510219 — Mubeen Trading\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution	{"_": "Message", "id": 2095, "out": false, "date": "2026-02-23 21:02:37+00:00", "post": null, "_meta": {"event_chat_id_raw": -5211338635, "chat_id_normalized": -5211338635}, "media": null, "views": null, "effect": null, "legacy": null, "pinned": null, "silent": false, "from_id": {"_": "PeerUser", "user_id": 8432659358}, "message": "📌 Current routing\\n\\nbillionaire_club\\n• Channels:\\n  - -1003254187278\\n  - -1002997989063\\n  - -1002467468850\\n• Target account: d072812f-88e8-4870-8f5c-3dd0d3772164 (traderscale/mt5/prop_funded) — Traderscale - Execution\\n\\nfredtrading\\n• Channels:\\n  - -1002208969496\\n  - -1001979286278\\n  - -1001239815745 — Fredtrading - VIP - Main channel\\n• Target account: 0bf2975d-3c7f-4573-b6f2-97d4d6ae3f4a (ftmo/mt5/personal_live) — test-ftmo\\n\\nmubeen\\n• Channels:\\n  - -1002808934766\\n  - -1002298510219 — Mubeen Trading\\n• Target account: 7ddf54ff-1cb1-468c-80f3-e7cc2808bcf7 (fundednext/mt5/prop_funded) — FundedNext - Execution", "offline": null, "peer_id": {"_": "PeerChat", "chat_id": 5211338635}, "replies": null, "entities": [{"_": "MessageEntityBold", "length": 15, "offset": 3}, {"_": "MessageEntityBold", "length": 16, "offset": 20}, {"_": "MessageEntityCode", "length": 14, "offset": 53}, {"_": "MessageEntityCode", "length": 14, "offset": 72}, {"_": "MessageEntityCode", "length": 14, "offset": 91}, {"_": "MessageEntityCode", "length": 36, "offset": 124}, {"_": "MessageEntityBold", "length": 11, "offset": 218}, {"_": "MessageEntityCode", "length": 14, "offset": 246}, {"_": "MessageEntityCode", "length": 14, "offset": 265}, {"_": "MessageEntityCode", "length": 49, "offset": 284}, {"_": "MessageEntityCode", "length": 36, "offset": 352}, {"_": "MessageEntityBold", "length": 6, "offset": 427}, {"_": "MessageEntityCode", "length": 14, "offset": 450}, {"_": "MessageEntityCode", "length": 31, "offset": 469}, {"_": "MessageEntityCode", "length": 36, "offset": 519}], "forwards": null, "fwd_from": null, "reply_to": null, "edit_date": null, "edit_hide": null, "factcheck": null, "mentioned": false, "reactions": null, "grouped_id": null, "noforwards": null, "ttl_period": null, "via_bot_id": null, "post_author": null, "invert_media": null, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": null, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": null, "quick_reply_shortcut_id": null, "video_processing_pending": null, "paid_suggested_post_stars": null, "report_delivery_until_date": null}	f	\N	2026-02-23 21:02:38.00243+00
af964d6b-08b9-472b-92bb-f283eb0e7d6e	-1001239815745	24857	-1001239815745	2026-02-23 21:10:09+00	The market today.. red. \n\nYVM trades… blue\n\nShow your blues for today!! Here\n\nhttps://t.me/c/1622898322/1/3955532\n\nSeven hundred thousand million billion willion lost in the market today… but we managed to win. How does he do it.\n\nShow us!!!	{"_": "Message", "id": 24857, "out": false, "date": "2026-02-23 21:10:09+00:00", "post": true, "_meta": {"event_chat_id_raw": -1001239815745, "chat_id_normalized": -1001239815745}, "media": {"_": "MessageMediaPhoto", "photo": {"_": "Photo", "id": 4965586968980949911, "date": "2026-02-23 21:10:08+00:00", "dc_id": 1, "sizes": [{"_": "PhotoStrippedSize", "type": "i", "bytes": "b\\"\\\\x01\\\\x1b(e\\\\xdf\\\\xf0q\\\\x9ej\\\\xbf>im\\\\xa0`\\\\xe7\\\\x18\\\\xab\\\\x17\\\\x99\\\\x011\\\\xefU\\\\xfenI#'\\\\xd6\\\\xb3:\\\\xa8\\\\xfc\\\\x08a\\\\x1c\\\\xd2\\\\xaf\\\\x07\\\\xa7oJNy\\\\xcf'\\\\xda\\\\x93#\\\\x8e\\\\xbf\\\\x9d\\\\x16*\\\\xfa\\\\xdc\\\\xd7\\\\x1d\\\\x05\\\\x14/\\\\xdd\\\\x14Pp=\\\\xc1 I\\\\x94\\\\xee]\\\\xc4t\\\\xe4\\\\xd3\\\\xbe\\\\xc5\\\\x17\\\\xfc\\\\xf3?\\\\x99\\\\xa9,\\\\xc0!\\\\xf23\\\\xc8\\\\xab;\\\\x17?tU\\\\xe8i\\\\x19I+\\\\\\\\\\\\xa6,m\\\\xb1\\\\xccn\\\\t\\\\xfa\\\\xd04\\\\xfbS\\\\xd27\\\\x1f\\\\x89\\\\x15s\\\\xcbO\\\\xee\\\\x8au\\\\x1a\\\\x0f\\\\x9a]\\\\xca\\\\x04`\\\\xe3\\\\xd2\\\\x8aq\\\\xfb\\\\xc6\\\\x8a\\\\x83#\\""}, {"_": "PhotoSize", "h": 218, "w": 320, "size": 25373, "type": "m"}, {"_": "PhotoSize", "h": 545, "w": 800, "size": 101005, "type": "x"}, {"_": "PhotoSizeProgressive", "h": 867, "w": 1272, "type": "y", "sizes": [12667, 35552, 56202, 78869, 128763]}], "access_hash": -4042980785333479945, "video_sizes": [], "has_stickers": false, "file_reference": "b'\\\\x02I\\\\xe6\\\\x16A\\\\x00\\\\x00a\\\\x19i\\\\x9c\\\\xc2B\\\\xff\\\\x00#\\\\xe8\\\\xd2<\\\\x015\\\\xc3r\\\\x7fkh/3\\\\x00'"}, "spoiler": false, "ttl_seconds": null}, "views": 183, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": null, "message": "The market today.. red. \\n\\nYVM trades… blue\\n\\nShow your blues for today!! Here\\n\\nhttps://t.me/c/1622898322/1/3955532\\n\\nSeven hundred thousand million billion willion lost in the market today… but we managed to win. How does he do it.\\n\\nShow us!!!", "offline": false, "peer_id": {"_": "PeerChannel", "channel_id": 1239815745}, "replies": null, "entities": [{"_": "MessageEntityUrl", "length": 35, "offset": 78}], "forwards": 3, "fwd_from": null, "reply_to": null, "edit_date": "2026-02-23 21:10:26+00:00", "edit_hide": true, "factcheck": null, "mentioned": false, "reactions": {"_": "MessageReactions", "min": true, "results": [{"_": "ReactionCount", "count": 1, "reaction": {"_": "ReactionEmoji", "emoticon": "❤"}, "chosen_order": null}], "can_see_list": false, "top_reactors": [], "recent_reactions": [], "reactions_as_tags": false}, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": "YVM", "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	t	2026-02-23 21:10:26+00	2026-02-23 21:10:29.055184+00
052edaa1-317b-4d95-82e7-f045f530e077	-1001239815745	24856	-1001239815745	2026-02-23 20:41:13+00	Nah.\nIGNORE me\n\nTP3 Hit anyway ✅	{"_": "Message", "id": 24856, "out": false, "date": "2026-02-23 20:41:13+00:00", "post": true, "_meta": {"event_chat_id_raw": -1001239815745, "chat_id_normalized": -1001239815745}, "media": null, "views": 3170, "effect": null, "legacy": false, "pinned": false, "silent": false, "from_id": null, "message": "Nah.\\nIGNORE me\\n\\nTP3 Hit anyway ✅", "offline": false, "peer_id": {"_": "PeerChannel", "channel_id": 1239815745}, "replies": null, "entities": [], "forwards": 7, "fwd_from": null, "reply_to": {"_": "MessageReplyHeader", "quote": false, "quote_text": null, "reply_from": null, "forum_topic": false, "reply_media": null, "quote_offset": null, "todo_item_id": null, "quote_entities": [], "reply_to_msg_id": 24846, "reply_to_top_id": null, "reply_to_peer_id": null, "reply_to_scheduled": false}, "edit_date": "2026-02-23 21:10:40+00:00", "edit_hide": false, "factcheck": null, "mentioned": false, "reactions": {"_": "MessageReactions", "min": true, "results": [{"_": "ReactionCount", "count": 162, "reaction": {"_": "ReactionEmoji", "emoticon": "❤"}, "chosen_order": null}, {"_": "ReactionCount", "count": 131, "reaction": {"_": "ReactionCustomEmoji", "document_id": 5222141780476046109}, "chosen_order": null}, {"_": "ReactionCount", "count": 31, "reaction": {"_": "ReactionEmoji", "emoticon": "👍"}, "chosen_order": null}, {"_": "ReactionCount", "count": 21, "reaction": {"_": "ReactionEmoji", "emoticon": "🔥"}, "chosen_order": null}, {"_": "ReactionCount", "count": 14, "reaction": {"_": "ReactionEmoji", "emoticon": "🍌"}, "chosen_order": null}, {"_": "ReactionCount", "count": 6, "reaction": {"_": "ReactionEmoji", "emoticon": "🤩"}, "chosen_order": null}, {"_": "ReactionCount", "count": 5, "reaction": {"_": "ReactionEmoji", "emoticon": "💯"}, "chosen_order": null}, {"_": "ReactionCount", "count": 3, "reaction": {"_": "ReactionEmoji", "emoticon": "🏆"}, "chosen_order": null}], "can_see_list": false, "top_reactors": [], "recent_reactions": [], "reactions_as_tags": false}, "grouped_id": null, "noforwards": false, "ttl_period": null, "via_bot_id": null, "post_author": "YVM", "invert_media": false, "media_unread": false, "reply_markup": null, "saved_peer_id": null, "from_scheduled": false, "suggested_post": null, "paid_message_stars": null, "restriction_reason": [], "from_boosts_applied": null, "via_business_bot_id": null, "paid_suggested_post_ton": false, "quick_reply_shortcut_id": null, "video_processing_pending": false, "paid_suggested_post_stars": false, "report_delivery_until_date": null}	t	2026-02-23 21:10:40+00	2026-02-23 20:41:26.146119+00
48adc8ec-e3bd-469a-894c-b8b327023add	333	1771884027	1	2026-02-23 22:00:27.332668+00	hello	{"x": 1}	f	\N	2026-02-23 22:00:27.333381+00
90ffabae-5614-4aa1-befd-692924f6adf5	333	1771884136	1	2026-02-23 22:02:16.421884+00	hello	{"x": 1}	f	\N	2026-02-23 22:02:16.422268+00
0bcdaa7b-06b2-42c5-8762-bbcab03e4f6e	222	1771884182	1	2026-02-23 22:03:02.859853+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:02.859514+00
043c4ec3-0ade-424a-a137-e940a0b37e22	333	1771884182	1	2026-02-23 22:03:02.865904+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:02.865639+00
2c5bb2a3-fbfe-433e-b12e-328dcf16d632	444	1771884182	1	2026-02-23 22:03:02.873749+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:02.873316+00
f00b90d6-7483-4b69-9fd4-500c80b57fce	222	1771884233	1	2026-02-23 22:03:53.186062+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:53.186442+00
0faa00a8-49b9-473c-99ae-4679bb43cbbe	333	1771884233	1	2026-02-23 22:03:53.191645+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:53.191958+00
20a9b9f7-69eb-41ea-9190-73e9c39e55e0	444	1771884233	1	2026-02-23 22:03:53.200504+00	hello	{"x": 1}	f	\N	2026-02-23 22:03:53.20083+00
274d6844-c434-43a2-92fa-b0f5fcc98967	222	1771885179	1	2026-02-23 22:19:39.836555+00	hello	{"x": 1}	f	\N	2026-02-23 22:19:39.83655+00
1a0e0579-d1e7-45fe-a4f6-d9cc73bd0b75	333	1771885179	1	2026-02-23 22:19:39.841725+00	hello	{"x": 1}	f	\N	2026-02-23 22:19:39.841761+00
a29460a4-cd56-4a7f-9d29-5f7ad0d6d502	444	1771885179	1	2026-02-23 22:19:39.851382+00	hello	{"x": 1}	f	\N	2026-02-23 22:19:39.851322+00
edc2e3ef-bb74-4f35-a97a-1c0c6d3c1ca8	-1001239815745	9999991	\N	\N	\N	{}	f	\N	2026-03-24 15:24:18.060949+00
\.


--
-- Data for Name: trade_families; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.trade_families (family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk, symbol_canonical, side, entry_price, sl_price, tp_count, state, is_stub, management_rules, meta, created_at, updated_at) FROM stdin;
d7443925-4c6f-4c37-878c-664e3dc46a03	6384ef2b-88d3-4e9c-9dc5-0e89c700b609	dd09c66a-5ee3-4d52-8d08-d9650f1c82f4	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	fa396360-2357-4765-b96a-6955ce89ace4	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:03.813228+00	2026-04-03 20:40:03.813228+00
7ab068fb-d972-40db-9059-c95323383c0c	94b5efcd-e18b-414f-87df-326ca0df9fa1	6053ef95-4504-483e-afce-dbb170903cb3	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	adfabdc6-bee5-4b73-a2ae-7c1bbd969cae	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:03.822037+00	2026-04-03 20:40:03.822037+00
07150cc8-50f9-443c-aa12-905c7915b48e	5036b649-b3c1-46e5-b5e3-12ec1b529e11	47118e92-5c4a-4805-a6ed-28d73c13c29e	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	bb1785d2-f9fc-4198-bd25-6edd8eca4a45	XAUUSD	buy	2025.0000000000	\N	1	PENDING_UPDATE	t	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:03.851935+00	2026-04-03 20:40:03.851935+00
307859ce-a790-4a23-950c-2b4a79b3b701	2020f1c5-e82d-4275-9fce-30c065dcbee1	0c1a7071-240a-401b-9668-644ad45a122b	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	65f8413f-427c-499b-a7d8-09a35d266211	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:16.824323+00	2026-04-03 20:40:16.824323+00
9ac2507b-6eee-479b-bcf9-cddd1e7220f3	bf84564a-8075-47e0-9a5e-c188b3f18bf0	3b5b3754-91cc-41e7-9c8a-291626b6cf95	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	a69e5834-a130-4a83-a795-2f1807379f84	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:16.832841+00	2026-04-03 20:40:16.832841+00
34c78733-b36d-42f6-9b13-3a6f14bf8b97	cbc19947-48a3-4fff-aab1-c19529691879	e88af324-4082-475a-8f14-ac5f8683d407	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	3f13fff7-6f1f-41df-bb28-09ced07cd5cd	XAUUSD	buy	2025.0000000000	\N	1	PENDING_UPDATE	t	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:16.841636+00	2026-04-03 20:40:16.841636+00
264f7fd6-6254-4fe3-b719-fc4ec103e89a	78e1d4c7-221d-4bc0-8cde-7bd790aa8d9b	87b36464-2ebe-4d51-9239-ee0cb6557a51	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	aa77a3c8-a664-479c-a184-462a1862f7eb	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:36.011901+00	2026-04-03 20:40:36.011901+00
fa0a5ce9-c7fe-4533-8024-1abd0374c145	4e058e7a-c512-4ff6-825f-8c399835c395	6383b998-dcf3-4ec5-8abf-0e62c086ea12	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	7f7e2df3-752a-4808-a076-0153328ad287	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:36.020903+00	2026-04-03 20:40:36.020903+00
15467611-0a52-4344-af36-915050a112fa	5e85c36a-7fb4-4cad-8f5f-db75eb673035	03c3f7d4-82c3-46d8-b22d-2756d281be26	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	356f6b7f-e577-4cc4-a41d-9dc83ed2e823	XAUUSD	buy	2025.0000000000	\N	1	PENDING_UPDATE	t	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:40:36.029073+00	2026-04-03 20:40:36.029073+00
c56e8b28-f758-44ec-a031-bfd7f290e7c1	beba9d63-2807-4fc0-9ee1-c636301889ad	\N	fredtrading	\N	\N	e73bc068-b3f0-4196-a906-c2c5d607d907	XAUUSD-PENDING-99a8b86d	buy	\N	\N	0	PENDING_UPDATE	f	{}	{}	2026-04-03 20:44:28.893629+00	2026-04-03 20:44:28.893629+00
fd915bf6-9b84-4c64-8ec3-33f3156a2949	4e40463b-6c30-4b26-9980-4ada0c310770	\N	fredtrading	\N	\N	b9664d5d-534b-40a3-a23f-692c40a7e778	XAUUSD-OPEN-cdd03154	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:28.900736+00	2026-04-03 20:44:28.900736+00
0ccae5e2-4174-48ca-a1ff-4e9f31d958dc	2e6e90a7-2444-44b6-9cfe-200f28f2b9a1	\N	fredtrading	\N	\N	6967f7be-6081-4433-a653-324228c2a222	XAUUSD-MULTI-79d5861a	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:28.905251+00	2026-04-03 20:44:28.905251+00
63c211ec-ba6d-42d0-87a5-77d549cdfdaa	51e6d045-312f-457b-817e-03d65fc6b897	\N	fredtrading	\N	\N	db00dc25-1341-4a01-a247-73750b0866ca	XAUUSD-MULTI-79d5861a	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:28.908225+00	2026-04-03 20:44:28.908225+00
ef920b30-c8f7-40b6-be62-8b9c249e9eb3	1002076d-87f0-4776-a2ad-1edac6cca64d	\N	fredtrading	\N	\N	fba35e5e-a288-42ea-9468-8386f5bbfe42	XAUUSD-PENDING-41a073f0	buy	\N	\N	0	PENDING_UPDATE	f	{}	{}	2026-04-03 20:44:43.581371+00	2026-04-03 20:44:43.581371+00
89b73b4c-36af-49bf-a506-d654c8c4c5a7	eede786b-5fd1-4534-81e7-47afdf27a6e1	\N	fredtrading	\N	\N	d443a189-5136-4b65-a438-eaddbb821bff	XAUUSD-OPEN-4a1602e8	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:43.589173+00	2026-04-03 20:44:43.589173+00
0a33b802-4c48-4754-8c24-f051f462868e	654b6708-6e1f-4adf-98c6-a67ad9370bb7	\N	fredtrading	\N	\N	d6be1687-a315-4638-a7a1-d1fb04c75af0	XAUUSD-MULTI-a67996a2	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:43.593681+00	2026-04-03 20:44:43.593681+00
2e914a21-14f7-49c6-9105-2e4b432c18a1	585f5244-07d4-4523-ac6d-7040b31a4039	\N	fredtrading	\N	\N	7dd803c0-7fe2-460b-9ea4-5352ec647976	XAUUSD-MULTI-a67996a2	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 20:44:43.596306+00	2026-04-03 20:44:43.596306+00
9e46c74e-d0a6-4d1a-9e80-7fd1774e8599	cdedf728-de44-4550-b3aa-69a6885d9e65	3b32a1f3-6389-4b4a-a43e-f5206dd076a6	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	afb32ec3-fcc0-42a8-8eac-6aa5c78c919a	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:46.376123+00	2026-04-03 20:49:46.383042+00
bfa84fad-1267-4c71-91ac-4dfcef3e1c7e	b2de2bb3-ea10-49ed-87ba-bc1f19505c7e	ad21ccbb-6744-405a-bc8e-d6875a31085c	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	73c274f1-7be4-41d1-b2b3-eb2bba2e46a7	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:46.389385+00	2026-04-03 20:49:46.389385+00
70fcc16b-97fe-43b6-97ad-5bc96d01da24	a301185b-7bb4-44c3-95fb-5f2b6ba8db94	6507e6e7-d200-4b4a-b79a-410b4318fcad	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	3e25a084-0373-4e67-884e-3398956545bf	XAUUSD	buy	4922.0000000000	4916.0000000000	5	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:46.416911+00	2026-04-03 20:49:46.421244+00
94ab7795-50e8-4363-990e-d54952aac121	3ea697d7-758b-463c-a4bc-cf4b5b82ef7c	1e0d5493-5182-4ea1-bd86-5ab6feeca72b	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	43de33ed-dbcd-4050-a08d-e567e345e3da	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:59.625487+00	2026-04-03 20:49:59.63064+00
2009c972-dfaa-466c-8cf0-c1d69fef90ec	e08335eb-ffc7-467c-a0e5-38bccb316968	d655bcf0-e019-402b-afdf-5ef89997810d	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	1e3297b0-2607-42d8-a3f7-f1ea48ad9ed8	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:59.636674+00	2026-04-03 20:49:59.636674+00
62470ddb-9d50-4b8b-8edd-08e14075380e	1e065d1a-2a6f-4674-96f8-5faa9159ed76	74121f45-a56c-4253-980b-ed4fadc299f4	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	61254c17-c14b-4ad5-8c86-9a231c2277be	XAUUSD	buy	4922.0000000000	4916.0000000000	5	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:49:59.647966+00	2026-04-03 20:49:59.651809+00
5b907b8d-754e-4c56-ac83-0cf371a52f4c	c4165dd6-1995-4003-a6d6-6f240120323d	50172180-f869-43ce-9242-63a80f5877aa	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	5094601c-95a2-46c2-a8c1-d0918755dad3	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:51:05.542921+00	2026-04-03 20:51:05.547512+00
33f7c544-3008-4998-b715-370270a12ba5	c1a91826-79eb-4ec9-988a-0c3d8c041249	774ec162-a8e6-4a46-a5f9-b61ec6c42347	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	d9e6ac73-e7c8-4bcd-9c49-b482a100bab3	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:51:05.555094+00	2026-04-03 20:51:05.555094+00
df093d93-bf7c-4144-82d1-d22309273d72	1788158b-a537-4b9d-bac2-ad112b154362	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	820b81c8-42a2-4068-8524-38e822e63ead	XAUUSD	buy	4922.0000000000	4916.0000000000	5	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:51:05.567619+00	2026-04-03 20:51:05.570821+00
1d53212f-dc71-4cc8-a8fe-24c11dfeb66d	0210b7d9-44d1-44ed-8b49-7509329d08a9	47ac7599-af82-494c-9b8a-078a4d7f5b41	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	dd674525-c8ad-4622-8b31-87b1e4e09125	XAUUSD	buy	2025.0000000000	2025.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:57:32.614734+00	2026-04-03 20:57:32.622617+00
b9930696-4bc0-47ca-81ba-477d0563eb70	297ff76e-a63a-473a-9c2e-eb40a55c501a	66068c90-0e07-4356-8ee2-3ca9d04b0a7d	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	21cdacc8-4a19-478c-8734-3becb3f23602	XAUUSD	buy	2025.0000000000	2025.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:57:53.431386+00	2026-04-03 20:57:53.438359+00
864a9165-9861-422f-9852-1c2cc77bba9a	2790b42d-55c5-403f-aa2d-f641ee074a81	f1a8bc8b-874f-4437-911e-413f9eda1e0b	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	854a4391-1134-44be-b8e4-7370313eccfb	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:57:53.444853+00	2026-04-03 20:57:53.444853+00
be106770-7c24-4c42-a8fc-abc72e778bda	5255ff19-41ce-4397-9205-f07cd4146ad3	22fefe9d-909c-4b6e-b070-feb72ca4d03c	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	99d5fa1b-56ab-422b-8578-f8348ef5c5a7	XAUUSD	buy	2025.0000000000	2025.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:58:14.227358+00	2026-04-03 20:58:14.233403+00
159a8cfd-5c92-4cbe-8fa8-db706edc0d46	7ec485d1-8d41-476d-a307-fbca8fc8af5e	44306f74-b4cd-4a42-8f48-eb535711b730	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	67a64823-749b-4242-bd24-ca5397e93dac	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:58:14.240171+00	2026-04-03 20:58:14.240171+00
68e22a40-8306-48ba-a937-a390bd99f6fb	9647ad4d-4764-4302-9093-1fcc2e49b19a	5f2e4012-6c15-4a1f-850f-ad2c5ab66178	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	ed07d72a-7b87-4dd9-9989-111006078e45	XAUUSD	buy	2025.0000000000	2025.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:58:49.621316+00	2026-04-03 20:58:49.626939+00
1350d079-c3c5-4532-8e55-86d0cd1674dc	df23dcdf-f648-4a77-89c2-2c7dc0c801e1	4952c1e5-c64e-4a6b-9986-583413a6f7fe	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	491dcfaf-ce2d-45f7-9a65-b30fc8a0647c	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 20:58:49.633411+00	2026-04-03 20:58:49.633411+00
ff2b7a78-9d21-4645-8149-44ef7a3e54b4	bcae035f-75e3-4f4a-b86e-8e776907e826	c1ebf6bc-b98c-434a-a5e4-75d7feb88363	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	1df792f5-3619-405e-a554-10756fc9d3fd	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:02:50.073599+00	2026-04-03 21:02:50.073599+00
be7e79ad-80be-4d7b-9782-7213acb513d0	732e5e56-2872-449c-b399-750184f73370	0dc82ac2-6e34-4f03-add2-c75ea138488f	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	eddcfad4-64e9-48d0-8a6a-82c3b08f880c	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:03:29.16467+00	2026-04-03 21:03:29.16467+00
a3d78771-9aaa-416d-8c47-e5e0d2abb4dd	ab42dbbb-1183-44ba-90cb-231a472e00b1	04d0b113-af12-4b6d-890c-aade61af6bed	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	246e8e21-89ad-46bf-9240-19d95f3817d9	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:05:08.800821+00	2026-04-03 21:05:08.800821+00
20850be3-a68a-4f65-834b-4886c44b23ec	c889c719-bf17-41c4-8d06-4273f9826340	1cafb528-0fb5-4e68-aeb6-42e71f6ac92a	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	31517421-f213-4337-ae9d-b3e15827477f	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:06:27.830836+00	2026-04-03 21:06:27.839641+00
c9d419fb-0142-4c59-8558-aa725ae06559	04fb282d-144b-460e-bb6b-9831a0bf0885	7c566562-2f73-4d2d-b26c-2ea5606539d6	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	fe364df0-35dc-4eb5-8823-9097a83ca3c7	XAUUSD	buy	2025.0000000000	2025.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:58.116584+00	2026-04-03 21:27:58.122825+00
fdfbef6a-63fb-4bb0-96d2-4fc4de29837a	bee37c84-17ed-4eae-b73a-3b9829bea716	397218b7-4b22-4041-a5af-d192fa9ca1b4	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	7b61b20f-cce8-497e-88ab-b5531ae7c771	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:07:20.256197+00	2026-04-03 21:07:20.278066+00
fdffe50a-c339-4214-95f2-24055fbf7bdb	542e566a-c6b0-46bc-9840-469af776ad3d	11d7b2a7-d24c-4be6-bec6-b12f8fca4c42	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	db5b3bcb-7abb-46df-a0eb-fb774ea19055	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:58.129972+00	2026-04-03 21:27:58.129972+00
2a4d6c00-fe6c-40c3-b08c-c36c7f21fd7d	cda005ea-8c2f-4cdd-a171-1658b24fa6e8	ff8ffeef-a997-40fd-a11f-6be642acac0d	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	c5d23d9c-9d0a-4999-8916-fefabd1ef16c	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:07:44.486809+00	2026-04-03 21:07:44.507742+00
106c8a28-e8c6-457d-a5d9-7b90ef5b4504	0c3a607b-bfb7-4cf2-a1d4-2599be25fada	a7f9d16d-d7c7-4483-959a-5955c7413803	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	814baf55-9a14-4704-9cc4-36d954843e87	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:58.569245+00	2026-04-03 21:27:58.578299+00
a4a8dd56-b69f-40c3-8090-a3f48bf7148a	f296cf43-3ada-4adf-9e6b-ef0aad515aa9	f6b5dc43-f372-4555-9ce7-2a310f91ea72	billionaire_club	3124081e-3ba8-4ffb-9ab8-6e2df38aa102	-1001239815745	7ab25a40-bcb1-4aeb-8ebb-62a3e275cd13	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:21.741467+00	2026-04-03 22:18:21.741467+00
2438c80a-bf70-452b-8f4f-fbb86db33f36	ff05bf6e-7959-4a6a-a7ff-45b20190a7ae	0c34e9d0-ec5b-4210-9d65-74249d3ae549	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	6d9e3aec-b826-41df-842a-da6c8231f184	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:26:13.228648+00	2026-04-03 21:26:13.236321+00
61efca0a-fc62-424c-82e0-cdfac34adea6	ce2dc344-76bd-4d9c-ae55-6df40570dc27	4fe39f82-6d44-432a-b2db-158508055a0a	fredtrading	5cd409c1-539b-4090-9463-807acf89608d	-1001239815745	9d9b0a99-85ca-4ce6-947d-c660f6b343e5	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:34.131612+00	2026-04-03 22:18:34.131612+00
bfcb9ac3-6b3d-45c0-8ddb-74c93050eb55	b884ecc4-05b6-4fa5-a4f9-164b5af0f122	a0388a18-6936-4fed-8749-8034132a02ba	fredtrading	6666dd6e-a1b6-468b-8254-60d08a0343e8	-1001239815745	b51eb9fa-b7a8-4b9f-b68f-75e0b1384f44	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:34.141839+00	2026-04-03 22:18:34.141839+00
85fc65fd-86b6-42d8-bba1-ef167a13a0b0	36b6828b-503f-4da0-abf7-51c942ceb90a	a9f60005-b92f-4fb8-91eb-5944812f1c30	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	cd646c7a-8ce6-4922-a469-7223e22e183e	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:56.80102+00	2026-04-03 21:27:56.80102+00
c6c78b3b-effe-442a-9532-a3a049a8ba50	2ff82c48-7800-4e9a-b28a-5990ee777efa	e2a59494-cfb8-4108-a1f2-9563cc0c319b	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	59d29aa1-6987-4297-beda-202eb37be535	XAUUSD	buy	2025.0000000000	2010.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:56.811064+00	2026-04-03 21:27:56.811064+00
fe4680bf-6dd4-47f7-b332-97367087e98b	53b639b2-b507-497d-b674-b877bb093d5d	9f3d69d2-fd8f-4bef-81fc-2ae2e8834683	fredtrading	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1001239815745	ca3b59d4-90e3-4bf6-bd5a-fbdb7eddd612	XAUUSD	buy	2025.0000000000	\N	1	PENDING_UPDATE	t	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:56.818612+00	2026-04-03 21:27:56.818612+00
3a69047a-46f3-4941-a951-ac5fcbc017c7	afa5b8e4-93fb-4298-8e25-abe14b6726e7	\N	fredtrading	\N	\N	0a553bc3-8689-457c-85ca-42690397932a	XAUUSD-PENDING-5f43625c	buy	\N	\N	0	PENDING_UPDATE	f	{}	{}	2026-04-03 21:27:57.23103+00	2026-04-03 21:27:57.23103+00
8e4f395f-b0c4-4bfa-ae0a-15192e0bfec8	cc9967a4-fd19-464f-ac57-734ea5a66d6b	\N	fredtrading	\N	\N	fbb197c2-2ff3-4742-9f6d-03a7afa44509	XAUUSD-OPEN-9850dbbd	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 21:27:57.237922+00	2026-04-03 21:27:57.237922+00
77d2c369-722f-42c6-aa38-aef136fe3662	83dd64db-655a-4771-9640-3240adab39ed	\N	fredtrading	\N	\N	79e2e5ee-2079-4815-bb26-0ddcabb25811	XAUUSD-MULTI-2a6a02c4	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 21:27:57.242417+00	2026-04-03 21:27:57.242417+00
1a69d354-2ce7-474c-b4a4-c6652770e991	2210f012-4cdb-493c-b621-d0c185dbfb2c	\N	fredtrading	\N	\N	134bbb9a-73e8-4984-abb5-9686fa861b31	XAUUSD-MULTI-2a6a02c4	buy	\N	\N	0	OPEN	f	{}	{}	2026-04-03 21:27:57.244792+00	2026-04-03 21:27:57.244792+00
8b495e7a-16a3-47f2-b496-506f3fc7e3a5	dcaf24cf-0523-43b4-8e31-5f3bfff18b11	fe7b5960-a6f5-4fde-bac9-ad12eaa9cbff	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	6a298cba-67f2-4d3e-a012-491af948c11f	XAUUSD	buy	4922.0000000000	4922.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:57.673046+00	2026-04-03 21:27:57.677557+00
5cfb7c99-a700-4695-ac4a-eb95a1e2e747	83a7e7f7-e03f-4cee-bd07-172d0ae157fb	fe933205-2ffb-46f6-981d-3c566fc70355	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	8dcbb517-45dd-4363-8a89-02a034141a1b	XAUUSD	buy	4922.0000000000	4916.0000000000	3	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:57.683903+00	2026-04-03 21:27:57.683903+00
797785e9-75a0-4a71-a5eb-2a0db7316dfd	95b26403-e600-412d-95d1-d1f3f7b20141	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	billionaire_club	21ef5d9a-3798-4990-9839-32e1e8dd37ba	-1003254187278	cbff70c3-750b-4590-8e59-93f9fd35a45c	XAUUSD	buy	4922.0000000000	4916.0000000000	5	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 21:27:57.693683+00	2026-04-03 21:27:57.696834+00
56c08e89-1735-48b1-835a-55776b941c9a	d153b796-93db-453c-bacd-715fe2ed1148	26d8f3b3-0c73-4576-8493-4be89f81cbc3	fredtrading	ef228b4f-1aac-46b3-84d4-ee5ca0a54da6	-1001239815745	c1e864ce-85c6-48d8-83ec-eeea1a2eb081	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:21.680378+00	2026-04-03 22:18:21.680378+00
f22f4393-3b18-4cfc-8921-c794f505d579	9d80fa21-706f-4f1f-bdc4-c8875fb9315d	8c6f6ce5-639e-4232-807f-7760bb545b35	fredtrading	daffc05c-6315-4b19-8819-652140b7cbe1	-1001239815745	079c4383-e581-43f1-8f77-7cd50aa63746	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:21.717697+00	2026-04-03 22:18:21.717697+00
69a0d61f-c5b6-4915-9782-e59fc2ceb5f1	b5c3b213-d159-4a99-a6ad-7063d2022e80	41904e23-5ad5-4f91-aa3c-9c725960812c	fredtrading	7ccae282-2a32-4214-b81e-0469462064a8	-1001239815745	417dd781-4853-432e-aa08-44bead706160	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:21.726787+00	2026-04-03 22:18:21.726787+00
7e97b199-c034-49cf-8962-ad461ab03d06	a02d2c14-3de2-4431-b77f-ee71c579d9b8	c8facc82-a136-4de7-a9aa-5d2803019dbe	fredtrading	23bf57be-08ef-48f0-a55b-ee27f8832feb	-1001239815745	98cafbf0-e31b-479a-b1ef-26539c21806c	XAUUSD	buy	2025.0000000000	2010.0000000000	2	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:21.734543+00	2026-04-03 22:18:21.734543+00
5b2cbc57-63ca-4baf-8ca5-97e1b366efe3	0a95f015-a32b-47f0-a09b-b533d47e7616	c6093315-90a1-4fa0-a84f-30520c8f029e	fredtrading	a232161d-b7eb-4352-b294-9a032e9f3dbd	-1001239815745	730bdb9e-c5d0-4269-b435-7bd96c39b153	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:34.149623+00	2026-04-03 22:18:34.149623+00
9d0be965-2983-4951-9efb-5a3f05a9331a	30f22593-11a3-4fcb-87ea-0e012fa19031	dc8b8c43-a9b2-4a53-9b1d-d917c58ab82e	fredtrading	77931193-66f4-4059-9a45-8fd508202ad7	-1001239815745	0e98579e-062f-495e-9c61-66e7bc159841	XAUUSD	buy	2025.0000000000	2010.0000000000	2	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:34.156809+00	2026-04-03 22:18:34.156809+00
cdcc4da3-2998-4409-9e2b-85c078cac2cb	5aadc761-827e-4835-96f9-7adb10428207	2165441a-4f1c-40c0-8655-05e15cb77afe	billionaire_club	4968e2f2-56bd-48b8-995f-5afae76c5e17	-1001239815745	dc7047f9-abbc-4857-8410-99bc5e2c050f	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:34.163921+00	2026-04-03 22:18:34.163921+00
07810645-f584-428f-980e-a477d96fe881	a7af5b1d-125d-4c32-9384-a0d291bd4f1a	a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	fredtrading	4844ef78-0ecb-47e4-8804-63f1d0e0bf1f	-1001239815745	a140d085-8ba5-4f7b-b944-89444051455f	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:52.141688+00	2026-04-03 22:18:52.141688+00
acba5d94-cc9b-4baa-a0c1-1ec6c554bb53	1e960f4b-7143-409b-83aa-e0d6fdb527c2	258c8c76-d09b-47c2-92c2-9f4878faed73	fredtrading	2dea5bda-b6b9-4140-bb17-b96491985e6c	-1001239815745	f94bbb91-972c-4e07-984b-5d18647bac75	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:52.152841+00	2026-04-03 22:18:52.152841+00
60d37206-7cb5-4055-bd8b-7134b6a1faac	b7f56819-0e26-4b9d-9e26-d6b7169c9e2a	666edf02-f17b-47c2-9b5f-51252bf33338	fredtrading	0e2087ea-a5a5-42b1-b25e-fbc5671bce67	-1001239815745	58b642b5-8114-4957-84bb-689143080a9a	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:52.160911+00	2026-04-03 22:18:52.160911+00
a1ea73d2-c543-49e6-8889-6debf5c9305c	9ecc9106-b955-440f-a78f-788bd8649202	7c1a0e9f-8324-4d19-92d9-2ce5d3dce2cc	fredtrading	b0b638a8-0bc6-44cb-ada3-b828f3641e7d	-1001239815745	f6b53e0c-8b5b-4ccc-83bf-01ce74214545	XAUUSD	buy	2025.0000000000	2010.0000000000	2	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:52.168409+00	2026-04-03 22:18:52.168409+00
ea7ea8b2-8606-4365-9c04-4f90028e1c7d	3835649c-e0f9-4d82-83a9-3fa7039a39ab	6d9905d4-78ee-4c46-96c8-e252a7112f18	billionaire_club	847d1eb6-b556-4aee-bbba-fe940171153c	-1001239815745	b6085613-24ba-4e96-83ab-0b84e6911dbb	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:18:52.174536+00	2026-04-03 22:18:52.174536+00
08f20fea-bec3-44bd-9a86-217368c783ee	87addf72-f3e9-4126-9d86-a970f5cda2f6	318d72a0-26ef-47cc-b8d8-181cb75c6f3b	fredtrading	6a8ced54-c85e-4104-9b6d-9515240f5799	-1001239815745	fa105fb5-a28d-4f52-bcd1-de736d865904	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:21:53.333963+00	2026-04-03 22:21:53.333963+00
bdaed2ce-29ea-46b2-b321-efa558272674	3e6f896d-de30-49fc-8953-b7734dcd7676	3e96ea12-917e-423d-8835-fdcf6e96c974	fredtrading	4b23c3da-90e6-4113-b8f8-953d75f563d6	-1001239815745	157f181b-feb4-487e-b1e5-6816e796c15b	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:21:53.346302+00	2026-04-03 22:21:53.346302+00
9b05146b-62be-46e5-8242-e7364991e200	53e1ce2f-0430-41cb-8b89-528fb4acd976	1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	fredtrading	cad218aa-a82d-4d08-b01b-5c69448b6370	-1001239815745	1e01948b-b735-400c-8f2a-439921c9f5c6	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:21:53.353469+00	2026-04-03 22:21:53.353469+00
4a25a111-6298-471a-bd05-f2c64a629c5d	33993392-8a9a-42b0-b443-da0601eb9e2e	81c9d440-379a-43af-8908-2dcd55d4bd8c	fredtrading	d911eab5-c050-4fbc-84b0-2d5a4e6065d3	-1001239815745	a10da90c-58fe-44c3-af32-1a23a83110a1	XAUUSD	buy	2025.0000000000	2010.0000000000	2	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:21:53.360403+00	2026-04-03 22:21:53.360403+00
662a77bf-524f-4ed4-9db0-39a200a0a18a	65abf42e-cda2-4514-9e3b-113456a6d4c0	05bb2611-213f-458b-bcd8-df8c7b3a0a60	billionaire_club	fb88b82f-5e04-4fa3-8eaf-9c15cc1a8f65	-1001239815745	c9fe9608-65a1-4f6d-9b3a-6f6a3ea36b5b	XAUUSD	buy	2025.0000000000	2010.0000000000	4	OPEN	f	{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}	{}	2026-04-03 22:21:53.366298+00	2026-04-03 22:21:53.366298+00
\.


--
-- Data for Name: trade_intents; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.trade_intents (intent_id, user_id, provider, chat_id, source_msg_pk, source_message_id, dedupe_hash, parse_confidence, status, symbol_canonical, symbol_raw, side, order_type, entry_price, sl_price, tp_prices, has_runner, risk_tag, is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta, created_at, updated_at) FROM stdin;
3e00c0bc-0cbe-494f-89b5-3830dc725aae	\N	fredtrading	-1001239815745	d3c33e6b-4888-4ebe-905c-0ccad2942fd8	1519312035	499744b9cb750203dbd39f5b52efedde24014fb6ebdd8722fbe955db2b48b533	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\\\nSL 2010\\\\nTP 2030", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:25:15.089676+00	2026-03-24 16:25:15.089676+00
fb423f2d-3275-438c-9664-690ab8bb0bb8	\N	fredtrading	-1001239815745	fac9e243-848d-45bb-8c6c-9bdc37821fc6	688099862	e9b0ce29afbd41ba8ececc6c908df12aaa4076fc316ca4e97edcad5cb542c2c5	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\\\nSL 2010\\\\nTP 2030", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:26:08.703525+00	2026-03-24 16:26:08.703525+00
806d115d-777a-4149-ab3d-fba67a044c8d	\N	fredtrading	-1001239815745	49f0e3f3-a058-44fc-9d74-f4c8e008e53d	900001	e739c64b1e2363201b3912dd759bf2116096cc63c2a67ea91de04bcac2cac275	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030 2040	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\\\nSL 2010\\\\nTP 2030 2040", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030 2040", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:29:24.599099+00	2026-03-24 16:29:24.599099+00
da1a1c5b-e3b8-44aa-9ae5-bb7c6ee8827b	\N	fredtrading	-1001239815745	2b0b8877-5dc2-440e-b527-ce87565e1dde	900003	9288f6a1e0974294701df72205bd479ad177e293cb8a5d47fb6c31ab68b32576	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\\\nSL 2010\\\\nTP 2030", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:29:24.611745+00	2026-03-24 16:29:24.611745+00
cbca4475-fc36-449a-8c29-262e85f4c0b6	\N	fredtrading	-1001239815745	2cb54364-5ae2-4ce6-96af-31553fc6a54c	910001	c6cd3f1b41513b7328b6178a860cfe2fca14c589658511e88f24412b09f4763e	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030 2040	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\nSL 2010\\nTP 2030 2040", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030 2040", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:35:06.383969+00	2026-03-24 16:35:06.383969+00
ac583eea-fda3-4707-b832-5d9b4fa154ce	\N	fredtrading	-1001239815745	fd991847-43d8-4e83-b231-537e0dcad552	910002	874e2f0b9ffac911797a53a2086f16f6a8b018e859df14bdf1266e6b7e29d4e6	1.000	received	XAUUSD	GOLD	buy	market	2010.0000000000	2010.0000000000	{2030.0000000000}	f	unknown	f	f	f	f	BUY GOLD now\nSL 2010\nTP 2030	{"sl": "2010", "tps": ["2030"], "meta": {}, "side": "BUY", "entry": "2010", "flags": [], "symbol": "XAUUSD", "update": null, "raw_text": "BUY GOLD now\\nSL 2010\\nTP 2030", "be_at_tp1": true, "clean_text": "BUY GOLD now\\nSL 2010\\nTP 2030", "confidence": 100, "order_type": "market", "raw_symbol": "GOLD", "unofficial": false, "message_type": "NEW_TRADE", "provider_code": "fredtrading"}	2026-03-24 16:35:06.392069+00	2026-03-24 16:35:06.392069+00
a96dd72d-e1d4-49f6-b0a4-41fd04dbc821	\N	mubeen	-1002298510219	bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb	990001	smoke-approval-dedupe	0.900	received	XAUUSD	XAUUSD	buy	market	4603.0000000000	4597.0000000000	{4606.0000000000,4610.0000000000,4613.0000000000,4626.0000000000}	f	high	f	f	f	f	High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606\nTP2 4610\nTP3 4613\nTP4 4626\n	{}	2026-04-03 20:12:24.224722+00	2026-04-03 20:12:24.224722+00
a0e70f8c-ea66-4366-a024-ffe35cf378ff	\N	mubeen	8000061825860	44444444-4444-4444-4444-444444444444	1825860	e22cad4f83eec8e49b7c3bb931bbad51b8b3c0671f21f07d46e1715d607daadd	1.000	candidate_pending	\N	XAUUSD	buy	market	4603.0000000000	4597.0000000000	{4606.0000000000}	f	high	f	f	f	f	High risk\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{"source": "approvals_service", "decision_reason": "mubeen_high_risk_requires_approval"}	2026-04-03 20:20:09.447733+00	2026-04-03 20:20:09.447733+00
3658bdd4-ca6d-4d4c-af58-40013b3cf875	\N	mubeen	8000002282325	55555555-5555-5555-5555-555555555555	1282325	b21cbfedc9c872f1703a0fabeec02bb55e6980998fc1d378322d6e2477d3be3a	1.000	candidate_pending	\N	XAUUSD	buy	market	4603.0000000000	4597.0000000000	{4606.0000000000}	f	high	f	f	f	f	High risk\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606	{"source": "approvals_service", "decision_reason": "mubeen_high_risk_requires_approval"}	2026-04-03 20:20:09.454022+00	2026-04-03 20:20:09.454022+00
802a7a20-488f-4691-a22e-c96c4a608783	\N	fredtrading	-1001239815745	c1ed830f-8fb6-421a-9fb1-2c1fc0f9f098	980001	seed-c1ed830f-8fb6-421a-9fb1-2c1fc0f9f098	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:39:29.340287+00	2026-04-03 20:39:29.340287+00
6384ef2b-88d3-4e9c-9dc5-0e89c700b609	\N	fredtrading	-1001239815745	fa396360-2357-4765-b96a-6955ce89ace4	1040740	seed-fa396360-2357-4765-b96a-6955ce89ace4	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:03.808341+00	2026-04-03 20:40:03.808341+00
94b5efcd-e18b-414f-87df-326ca0df9fa1	\N	fredtrading	-1001239815745	adfabdc6-bee5-4b73-a2ae-7c1bbd969cae	1022510	seed-adfabdc6-bee5-4b73-a2ae-7c1bbd969cae	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:03.819489+00	2026-04-03 20:40:03.819489+00
5036b649-b3c1-46e5-b5e3-12ec1b529e11	\N	fredtrading	-1001239815745	bb1785d2-f9fc-4198-bd25-6edd8eca4a45	987685	seed-bb1785d2-f9fc-4198-bd25-6edd8eca4a45	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	\N	{}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:03.848728+00	2026-04-03 20:40:03.848728+00
2020f1c5-e82d-4275-9fce-30c065dcbee1	\N	fredtrading	-1001239815745	65f8413f-427c-499b-a7d8-09a35d266211	1026801	seed-65f8413f-427c-499b-a7d8-09a35d266211	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:16.819243+00	2026-04-03 20:40:16.819243+00
bf84564a-8075-47e0-9a5e-c188b3f18bf0	\N	fredtrading	-1001239815745	a69e5834-a130-4a83-a795-2f1807379f84	1022788	seed-a69e5834-a130-4a83-a795-2f1807379f84	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:16.830315+00	2026-04-03 20:40:16.830315+00
cbc19947-48a3-4fff-aab1-c19529691879	\N	fredtrading	-1001239815745	3f13fff7-6f1f-41df-bb28-09ced07cd5cd	1031821	seed-3f13fff7-6f1f-41df-bb28-09ced07cd5cd	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	\N	{}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:16.838117+00	2026-04-03 20:40:16.838117+00
78e1d4c7-221d-4bc0-8cde-7bd790aa8d9b	\N	fredtrading	-1001239815745	aa77a3c8-a664-479c-a184-462a1862f7eb	1048779	seed-aa77a3c8-a664-479c-a184-462a1862f7eb	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:36.001292+00	2026-04-03 20:40:36.001292+00
4e058e7a-c512-4ff6-825f-8c399835c395	\N	fredtrading	-1001239815745	7f7e2df3-752a-4808-a076-0153328ad287	1016775	seed-7f7e2df3-752a-4808-a076-0153328ad287	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:36.01819+00	2026-04-03 20:40:36.01819+00
5e85c36a-7fb4-4cad-8f5f-db75eb673035	\N	fredtrading	-1001239815745	356f6b7f-e577-4cc4-a41d-9dc83ed2e823	1043907	seed-356f6b7f-e577-4cc4-a41d-9dc83ed2e823	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	\N	{}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:40:36.026382+00	2026-04-03 20:40:36.026382+00
beba9d63-2807-4fc0-9ee1-c636301889ad	\N	fredtrading	-1001239815745	e73bc068-b3f0-4196-a906-c2c5d607d907	1016151	seed-e73bc068-b3f0-4196-a906-c2c5d607d907	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:28.893629+00	2026-04-03 20:44:28.893629+00
4e40463b-6c30-4b26-9980-4ada0c310770	\N	fredtrading	-1001239815745	b9664d5d-534b-40a3-a23f-692c40a7e778	991688	seed-b9664d5d-534b-40a3-a23f-692c40a7e778	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:28.900736+00	2026-04-03 20:44:28.900736+00
2e6e90a7-2444-44b6-9cfe-200f28f2b9a1	\N	fredtrading	-1001239815745	6967f7be-6081-4433-a653-324228c2a222	1088274	seed-6967f7be-6081-4433-a653-324228c2a222	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:28.905251+00	2026-04-03 20:44:28.905251+00
51e6d045-312f-457b-817e-03d65fc6b897	\N	fredtrading	-1001239815745	db00dc25-1341-4a01-a247-73750b0866ca	994778	seed-db00dc25-1341-4a01-a247-73750b0866ca	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:28.908225+00	2026-04-03 20:44:28.908225+00
1002076d-87f0-4776-a2ad-1edac6cca64d	\N	fredtrading	-1001239815745	fba35e5e-a288-42ea-9468-8386f5bbfe42	1061714	seed-fba35e5e-a288-42ea-9468-8386f5bbfe42	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:43.581371+00	2026-04-03 20:44:43.581371+00
eede786b-5fd1-4534-81e7-47afdf27a6e1	\N	fredtrading	-1001239815745	d443a189-5136-4b65-a438-eaddbb821bff	1087087	seed-d443a189-5136-4b65-a438-eaddbb821bff	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:43.589173+00	2026-04-03 20:44:43.589173+00
654b6708-6e1f-4adf-98c6-a67ad9370bb7	\N	fredtrading	-1001239815745	d6be1687-a315-4638-a7a1-d1fb04c75af0	1077472	seed-d6be1687-a315-4638-a7a1-d1fb04c75af0	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:43.593681+00	2026-04-03 20:44:43.593681+00
585f5244-07d4-4523-ac6d-7040b31a4039	\N	fredtrading	-1001239815745	7dd803c0-7fe2-460b-9ea4-5352ec647976	1034502	seed-7dd803c0-7fe2-460b-9ea4-5352ec647976	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:44:43.596306+00	2026-04-03 20:44:43.596306+00
cdedf728-de44-4550-b3aa-69a6885d9e65	\N	billionaire_club	-1003254187278	afb32ec3-fcc0-42a8-8eac-6aa5c78c919a	1053706	seed-afb32ec3-fcc0-42a8-8eac-6aa5c78c919a	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:46.367059+00	2026-04-03 20:49:46.367059+00
b2de2bb3-ea10-49ed-87ba-bc1f19505c7e	\N	billionaire_club	-1003254187278	73c274f1-7be4-41d1-b2b3-eb2bba2e46a7	1055735	seed-73c274f1-7be4-41d1-b2b3-eb2bba2e46a7	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:46.386882+00	2026-04-03 20:49:46.386882+00
a301185b-7bb4-44c3-95fb-5f2b6ba8db94	\N	billionaire_club	-1003254187278	3e25a084-0373-4e67-884e-3398956545bf	1040527	seed-3e25a084-0373-4e67-884e-3398956545bf	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:46.413466+00	2026-04-03 20:49:46.413466+00
3ea697d7-758b-463c-a4bc-cf4b5b82ef7c	\N	billionaire_club	-1003254187278	43de33ed-dbcd-4050-a08d-e567e345e3da	1030314	seed-43de33ed-dbcd-4050-a08d-e567e345e3da	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:59.62046+00	2026-04-03 20:49:59.62046+00
e08335eb-ffc7-467c-a0e5-38bccb316968	\N	billionaire_club	-1003254187278	1e3297b0-2607-42d8-a3f7-f1ea48ad9ed8	1000808	seed-1e3297b0-2607-42d8-a3f7-f1ea48ad9ed8	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:59.634441+00	2026-04-03 20:49:59.634441+00
1e065d1a-2a6f-4674-96f8-5faa9159ed76	\N	billionaire_club	-1003254187278	61254c17-c14b-4ad5-8c86-9a231c2277be	1039822	seed-61254c17-c14b-4ad5-8c86-9a231c2277be	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:49:59.645539+00	2026-04-03 20:49:59.645539+00
c4165dd6-1995-4003-a6d6-6f240120323d	\N	billionaire_club	-1003254187278	5094601c-95a2-46c2-a8c1-d0918755dad3	1063235	seed-5094601c-95a2-46c2-a8c1-d0918755dad3	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:51:05.535837+00	2026-04-03 20:51:05.535837+00
c1a91826-79eb-4ec9-988a-0c3d8c041249	\N	billionaire_club	-1003254187278	d9e6ac73-e7c8-4bcd-9c49-b482a100bab3	979715	seed-d9e6ac73-e7c8-4bcd-9c49-b482a100bab3	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:51:05.551267+00	2026-04-03 20:51:05.551267+00
1788158b-a537-4b9d-bac2-ad112b154362	\N	billionaire_club	-1003254187278	820b81c8-42a2-4068-8524-38e822e63ead	1025917	seed-820b81c8-42a2-4068-8524-38e822e63ead	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:51:05.565345+00	2026-04-03 20:51:05.565345+00
0210b7d9-44d1-44ed-8b49-7509329d08a9	\N	fredtrading	-1001239815745	dd674525-c8ad-4622-8b31-87b1e4e09125	960001	seed-dd674525-c8ad-4622-8b31-87b1e4e09125	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:57:32.607904+00	2026-04-03 20:57:32.607904+00
297ff76e-a63a-473a-9c2e-eb40a55c501a	\N	fredtrading	-1001239815745	21cdacc8-4a19-478c-8734-3becb3f23602	944722	seed-21cdacc8-4a19-478c-8734-3becb3f23602	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:57:53.426095+00	2026-04-03 20:57:53.426095+00
2790b42d-55c5-403f-aa2d-f641ee074a81	\N	fredtrading	-1001239815745	854a4391-1134-44be-b8e4-7370313eccfb	997303	seed-854a4391-1134-44be-b8e4-7370313eccfb	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:57:53.442426+00	2026-04-03 20:57:53.442426+00
5255ff19-41ce-4397-9205-f07cd4146ad3	\N	fredtrading	-1001239815745	99d5fa1b-56ab-422b-8578-f8348ef5c5a7	939630	seed-99d5fa1b-56ab-422b-8578-f8348ef5c5a7	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:58:14.220531+00	2026-04-03 20:58:14.220531+00
7ec485d1-8d41-476d-a307-fbca8fc8af5e	\N	fredtrading	-1001239815745	67a64823-749b-4242-bd24-ca5397e93dac	921199	seed-67a64823-749b-4242-bd24-ca5397e93dac	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:58:14.237699+00	2026-04-03 20:58:14.237699+00
9647ad4d-4764-4302-9093-1fcc2e49b19a	\N	fredtrading	-1001239815745	ed07d72a-7b87-4dd9-9989-111006078e45	994918	seed-ed07d72a-7b87-4dd9-9989-111006078e45	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:58:49.611826+00	2026-04-03 20:58:49.611826+00
df23dcdf-f648-4a77-89c2-2c7dc0c801e1	\N	fredtrading	-1001239815745	491dcfaf-ce2d-45f7-9a65-b30fc8a0647c	986486	seed-491dcfaf-ce2d-45f7-9a65-b30fc8a0647c	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 20:58:49.631+00	2026-04-03 20:58:49.631+00
bcae035f-75e3-4f4a-b86e-8e776907e826	\N	billionaire_club	-1003254187278	1df792f5-3619-405e-a554-10756fc9d3fd	993991	seed-1df792f5-3619-405e-a554-10756fc9d3fd	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:02:50.065587+00	2026-04-03 21:02:50.065587+00
732e5e56-2872-449c-b399-750184f73370	\N	billionaire_club	-1003254187278	eddcfad4-64e9-48d0-8a6a-82c3b08f880c	975345	seed-eddcfad4-64e9-48d0-8a6a-82c3b08f880c	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:03:29.155382+00	2026-04-03 21:03:29.155382+00
ab42dbbb-1183-44ba-90cb-231a472e00b1	\N	billionaire_club	-1003254187278	246e8e21-89ad-46bf-9240-19d95f3817d9	923989	seed-246e8e21-89ad-46bf-9240-19d95f3817d9	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:05:08.79502+00	2026-04-03 21:05:08.79502+00
c889c719-bf17-41c4-8d06-4273f9826340	\N	billionaire_club	-1003254187278	31517421-f213-4337-ae9d-b3e15827477f	970743	seed-31517421-f213-4337-ae9d-b3e15827477f	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:06:27.823298+00	2026-04-03 21:06:27.823298+00
bee37c84-17ed-4eae-b73a-3b9829bea716	\N	billionaire_club	-1003254187278	7b61b20f-cce8-497e-88ab-b5531ae7c771	956155	smoke-7b61b20f-cce8-497e-88ab-b5531ae7c771	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:07:20.246035+00	2026-04-03 21:07:20.246035+00
cda005ea-8c2f-4cdd-a171-1658b24fa6e8	\N	billionaire_club	-1003254187278	c5d23d9c-9d0a-4999-8916-fefabd1ef16c	988945	smoke-c5d23d9c-9d0a-4999-8916-fefabd1ef16c	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:07:44.477234+00	2026-04-03 21:07:44.477234+00
ff05bf6e-7959-4a6a-a7ff-45b20190a7ae	\N	billionaire_club	-1003254187278	6d9e3aec-b826-41df-842a-da6c8231f184	980819	seed-6d9e3aec-b826-41df-842a-da6c8231f184	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:26:13.222477+00	2026-04-03 21:26:13.222477+00
36b6828b-503f-4da0-abf7-51c942ceb90a	\N	fredtrading	-1001239815745	cd646c7a-8ce6-4922-a469-7223e22e183e	1075358	seed-cd646c7a-8ce6-4922-a469-7223e22e183e	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:56.792247+00	2026-04-03 21:27:56.792247+00
2ff82c48-7800-4e9a-b28a-5990ee777efa	\N	fredtrading	-1001239815745	59d29aa1-6987-4297-beda-202eb37be535	1017141	seed-59d29aa1-6987-4297-beda-202eb37be535	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:56.806971+00	2026-04-03 21:27:56.806971+00
53b639b2-b507-497d-b674-b877bb093d5d	\N	fredtrading	-1001239815745	ca3b59d4-90e3-4bf6-bd5a-fbdb7eddd612	1011442	seed-ca3b59d4-90e3-4bf6-bd5a-fbdb7eddd612	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	\N	{}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:56.81633+00	2026-04-03 21:27:56.81633+00
afa5b8e4-93fb-4298-8e25-abe14b6726e7	\N	fredtrading	-1001239815745	0a553bc3-8689-457c-85ca-42690397932a	1019962	seed-0a553bc3-8689-457c-85ca-42690397932a	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.23103+00	2026-04-03 21:27:57.23103+00
cc9967a4-fd19-464f-ac57-734ea5a66d6b	\N	fredtrading	-1001239815745	fbb197c2-2ff3-4742-9f6d-03a7afa44509	1082105	seed-fbb197c2-2ff3-4742-9f6d-03a7afa44509	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.237922+00	2026-04-03 21:27:57.237922+00
83dd64db-655a-4771-9640-3240adab39ed	\N	fredtrading	-1001239815745	79e2e5ee-2079-4815-bb26-0ddcabb25811	1001217	seed-79e2e5ee-2079-4815-bb26-0ddcabb25811	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.242417+00	2026-04-03 21:27:57.242417+00
2210f012-4cdb-493c-b621-d0c185dbfb2c	\N	fredtrading	-1001239815745	134bbb9a-73e8-4984-abb5-9686fa861b31	1030913	seed-134bbb9a-73e8-4984-abb5-9686fa861b31	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.244792+00	2026-04-03 21:27:57.244792+00
dcaf24cf-0523-43b4-8e31-5f3bfff18b11	\N	billionaire_club	-1003254187278	6a298cba-67f2-4d3e-a012-491af948c11f	1055599	seed-6a298cba-67f2-4d3e-a012-491af948c11f	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.666223+00	2026-04-03 21:27:57.666223+00
83a7e7f7-e03f-4cee-bd07-172d0ae157fb	\N	billionaire_club	-1003254187278	8dcbb517-45dd-4363-8a89-02a034141a1b	1017291	seed-8dcbb517-45dd-4363-8a89-02a034141a1b	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.681386+00	2026-04-03 21:27:57.681386+00
95b26403-e600-412d-95d1-d1f3f7b20141	\N	billionaire_club	-1003254187278	cbff70c3-750b-4590-8e59-93f9fd35a45c	1028140	seed-cbff70c3-750b-4590-8e59-93f9fd35a45c	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:57.691476+00	2026-04-03 21:27:57.691476+00
04fb282d-144b-460e-bb6b-9831a0bf0885	\N	fredtrading	-1001239815745	fe364df0-35dc-4eb5-8823-9097a83ca3c7	924362	seed-fe364df0-35dc-4eb5-8823-9097a83ca3c7	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:58.10856+00	2026-04-03 21:27:58.10856+00
542e566a-c6b0-46bc-9840-469af776ad3d	\N	fredtrading	-1001239815745	db5b3bcb-7abb-46df-a0eb-fb774ea19055	994813	seed-db5b3bcb-7abb-46df-a0eb-fb774ea19055	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:58.127538+00	2026-04-03 21:27:58.127538+00
0c3a607b-bfb7-4cf2-a1d4-2599be25fada	\N	billionaire_club	-1003254187278	814baf55-9a14-4704-9cc4-36d954843e87	978216	seed-814baf55-9a14-4704-9cc4-36d954843e87	0.950	received	XAUUSD	XAUUSD	buy	market	4922.0000000000	4916.0000000000	{4925.0000000000,4928.0000000000,4934.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 21:27:58.561892+00	2026-04-03 21:27:58.561892+00
07c17981-c2e3-49ee-9203-e58057e8a2b5	\N	fredtrading	-1001239815745	43c2eb86-3455-48ab-8275-262bb9ee866a	930001	seed-43c2eb86-3455-48ab-8275-262bb9ee866a	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:17:26.49059+00	2026-04-03 22:17:26.49059+00
363bc708-9411-4ef2-b41b-0f40a14267ef	\N	fredtrading	-1001239815745	c8105c91-9b5c-4a94-b4c6-805f84ad1471	930698	seed-c8105c91-9b5c-4a94-b4c6-805f84ad1471	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:17:42.087418+00	2026-04-03 22:17:42.087418+00
84421644-aac4-4f4c-83dd-72d41c96c5b2	\N	fredtrading	-1001239815745	c5df57ad-24c5-480d-bca8-7040fb6c5f6f	978877	seed-c5df57ad-24c5-480d-bca8-7040fb6c5f6f	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:17:42.216003+00	2026-04-03 22:17:42.216003+00
d188c938-552a-490f-851d-5c4b7752e608	\N	fredtrading	-1001239815745	75bf6072-b429-4e91-be79-83bf74de8df2	994305	seed-75bf6072-b429-4e91-be79-83bf74de8df2	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:17:42.324965+00	2026-04-03 22:17:42.324965+00
45ba3329-4aed-4f2a-8bfd-f0f65292cdf2	\N	fredtrading	-1001239815745	5508cbd1-c749-4b05-b169-778eba50e40e	955155	seed-5508cbd1-c749-4b05-b169-778eba50e40e	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:17:42.432171+00	2026-04-03 22:17:42.432171+00
e01d8f16-1a70-4fb4-979c-d9b9e0583621	\N	billionaire_club	-1001239815745	68c610c9-62ee-4197-b885-52c1193aa1a4	953500	seed-68c610c9-62ee-4197-b885-52c1193aa1a4	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:17:42.539643+00	2026-04-03 22:17:42.539643+00
9933c38c-7289-48b5-b4fc-f627207e50b3	\N	fredtrading	-1001239815745	69e0d9fe-bd8e-42b8-86a7-c72efc4596ee	906059	seed-69e0d9fe-bd8e-42b8-86a7-c72efc4596ee	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:05.780998+00	2026-04-03 22:18:05.780998+00
2bb69f0f-18c1-40d3-8068-2d2c815271ad	\N	fredtrading	-1001239815745	be40ac15-6dc6-4741-a31a-714ea5c4d9f8	996188	seed-be40ac15-6dc6-4741-a31a-714ea5c4d9f8	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:18:05.907617+00	2026-04-03 22:18:05.907617+00
d1ac0956-c112-4508-b7d6-233a276b9b6f	\N	fredtrading	-1001239815745	d5b6eecc-ec15-4e41-b31d-f991385e9227	934193	seed-d5b6eecc-ec15-4e41-b31d-f991385e9227	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:18:06.019037+00	2026-04-03 22:18:06.019037+00
67ae54be-a296-4e24-9806-35ee3877140c	\N	fredtrading	-1001239815745	215490eb-68eb-4133-a7e1-726fa5432168	944615	seed-215490eb-68eb-4133-a7e1-726fa5432168	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:18:06.130525+00	2026-04-03 22:18:06.130525+00
d31e9f5e-b578-47a6-b910-05edcbbf42f6	\N	billionaire_club	-1001239815745	e51ce1a6-36a6-4c46-9fb5-594362fc0455	985205	seed-e51ce1a6-36a6-4c46-9fb5-594362fc0455	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:06.240272+00	2026-04-03 22:18:06.240272+00
d153b796-93db-453c-bacd-715fe2ed1148	\N	fredtrading	-1001239815745	c1e864ce-85c6-48d8-83ec-eeea1a2eb081	958324	seed-c1e864ce-85c6-48d8-83ec-eeea1a2eb081	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:21.672404+00	2026-04-03 22:18:21.672404+00
9d80fa21-706f-4f1f-bdc4-c8875fb9315d	\N	fredtrading	-1001239815745	079c4383-e581-43f1-8f77-7cd50aa63746	903160	seed-079c4383-e581-43f1-8f77-7cd50aa63746	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:18:21.712283+00	2026-04-03 22:18:21.712283+00
b5c3b213-d159-4a99-a6ad-7063d2022e80	\N	fredtrading	-1001239815745	417dd781-4853-432e-aa08-44bead706160	975207	seed-417dd781-4853-432e-aa08-44bead706160	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:18:21.723139+00	2026-04-03 22:18:21.723139+00
a02d2c14-3de2-4431-b77f-ee71c579d9b8	\N	fredtrading	-1001239815745	98cafbf0-e31b-479a-b1ef-26539c21806c	951642	seed-98cafbf0-e31b-479a-b1ef-26539c21806c	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:18:21.731582+00	2026-04-03 22:18:21.731582+00
f296cf43-3ada-4adf-9e6b-ef0aad515aa9	\N	billionaire_club	-1001239815745	7ab25a40-bcb1-4aeb-8ebb-62a3e275cd13	962072	seed-7ab25a40-bcb1-4aeb-8ebb-62a3e275cd13	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:21.738179+00	2026-04-03 22:18:21.738179+00
ce2dc344-76bd-4d9c-ae55-6df40570dc27	\N	fredtrading	-1001239815745	9d9b0a99-85ca-4ce6-947d-c660f6b343e5	929845	seed-9d9b0a99-85ca-4ce6-947d-c660f6b343e5	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:34.123482+00	2026-04-03 22:18:34.123482+00
b884ecc4-05b6-4fa5-a4f9-164b5af0f122	\N	fredtrading	-1001239815745	b51eb9fa-b7a8-4b9f-b68f-75e0b1384f44	970818	seed-b51eb9fa-b7a8-4b9f-b68f-75e0b1384f44	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:18:34.138995+00	2026-04-03 22:18:34.138995+00
0a95f015-a32b-47f0-a09b-b533d47e7616	\N	fredtrading	-1001239815745	730bdb9e-c5d0-4269-b435-7bd96c39b153	986320	seed-730bdb9e-c5d0-4269-b435-7bd96c39b153	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:18:34.146141+00	2026-04-03 22:18:34.146141+00
30f22593-11a3-4fcb-87ea-0e012fa19031	\N	fredtrading	-1001239815745	0e98579e-062f-495e-9c61-66e7bc159841	918341	seed-0e98579e-062f-495e-9c61-66e7bc159841	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:18:34.154188+00	2026-04-03 22:18:34.154188+00
5aadc761-827e-4835-96f9-7adb10428207	\N	billionaire_club	-1001239815745	dc7047f9-abbc-4857-8410-99bc5e2c050f	989114	seed-dc7047f9-abbc-4857-8410-99bc5e2c050f	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:34.160373+00	2026-04-03 22:18:34.160373+00
a7af5b1d-125d-4c32-9384-a0d291bd4f1a	\N	fredtrading	-1001239815745	a140d085-8ba5-4f7b-b944-89444051455f	991662	seed-a140d085-8ba5-4f7b-b944-89444051455f	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:52.136249+00	2026-04-03 22:18:52.136249+00
1e960f4b-7143-409b-83aa-e0d6fdb527c2	\N	fredtrading	-1001239815745	f94bbb91-972c-4e07-984b-5d18647bac75	983443	seed-f94bbb91-972c-4e07-984b-5d18647bac75	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:18:52.149992+00	2026-04-03 22:18:52.149992+00
b7f56819-0e26-4b9d-9e26-d6b7169c9e2a	\N	fredtrading	-1001239815745	58b642b5-8114-4957-84bb-689143080a9a	944206	seed-58b642b5-8114-4957-84bb-689143080a9a	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:18:52.158023+00	2026-04-03 22:18:52.158023+00
9ecc9106-b955-440f-a78f-788bd8649202	\N	fredtrading	-1001239815745	f6b53e0c-8b5b-4ccc-83bf-01ce74214545	933555	seed-f6b53e0c-8b5b-4ccc-83bf-01ce74214545	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:18:52.165817+00	2026-04-03 22:18:52.165817+00
3835649c-e0f9-4d82-83a9-3fa7039a39ab	\N	billionaire_club	-1001239815745	b6085613-24ba-4e96-83ab-0b84e6911dbb	984233	seed-b6085613-24ba-4e96-83ab-0b84e6911dbb	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:18:52.17185+00	2026-04-03 22:18:52.17185+00
87addf72-f3e9-4126-9d86-a970f5cda2f6	\N	fredtrading	-1001239815745	fa105fb5-a28d-4f52-bcd1-de736d865904	907593	seed-fa105fb5-a28d-4f52-bcd1-de736d865904	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:21:53.327781+00	2026-04-03 22:21:53.327781+00
3e6f896d-de30-49fc-8953-b7734dcd7676	\N	fredtrading	-1001239815745	157f181b-feb4-487e-b1e5-6816e796c15b	939117	seed-157f181b-feb4-487e-b1e5-6816e796c15b	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	half	f	f	f	f	seed	{}	2026-04-03 22:21:53.343125+00	2026-04-03 22:21:53.343125+00
53e1ce2f-0430-41cb-8b89-528fb4acd976	\N	fredtrading	-1001239815745	1e01948b-b735-400c-8f2a-439921c9f5c6	984428	seed-1e01948b-b735-400c-8f2a-439921c9f5c6	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	t	f	f	seed	{}	2026-04-03 22:21:53.350739+00	2026-04-03 22:21:53.350739+00
33993392-8a9a-42b0-b443-da0601eb9e2e	\N	fredtrading	-1001239815745	a10da90c-58fe-44c3-af32-1a23a83110a1	938546	seed-a10da90c-58fe-44c3-af32-1a23a83110a1	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{4690.0000000000,4701.0000000000}	f	normal	f	f	f	f	I’m trying something out on a 5K side account I setup to have some fun on…	{}	2026-04-03 22:21:53.357547+00	2026-04-03 22:21:53.357547+00
65abf42e-cda2-4514-9e3b-113456a6d4c0	\N	billionaire_club	-1001239815745	c9fe9608-65a1-4f6d-9b3a-6f6a3ea36b5b	981434	seed-c9fe9608-65a1-4f6d-9b3a-6f6a3ea36b5b	0.950	received	XAUUSD	XAUUSD	buy	market	2025.0000000000	2010.0000000000	{2030.0000000000,2040.0000000000,2050.0000000000,2060.0000000000}	f	normal	f	f	f	f	seed	{}	2026-04-03 22:21:53.363786+00	2026-04-03 22:21:53.363786+00
\.


--
-- Data for Name: trade_legs; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.trade_legs (leg_id, plan_id, idx, role, entry_price, sl_price, tp_price, lots, entry_jitter_applied, entry_jitter_policy_id, move_sl_to_entry_at_tp1, is_tp1, meta, created_at, family_id, leg_index, state) FROM stdin;
4675a64e-da81-495e-8e78-2c15b0649efd	dd09c66a-5ee3-4d52-8d08-d9650f1c82f4	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.813228+00	d7443925-4c6f-4c37-878c-664e3dc46a03	1	OPEN
fbd2c833-be48-43db-b5b7-a25e541ede49	dd09c66a-5ee3-4d52-8d08-d9650f1c82f4	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.813228+00	d7443925-4c6f-4c37-878c-664e3dc46a03	2	OPEN
bd7ce692-3a1d-4185-b3fc-86ac37ad3cf0	dd09c66a-5ee3-4d52-8d08-d9650f1c82f4	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.813228+00	d7443925-4c6f-4c37-878c-664e3dc46a03	3	OPEN
8f91e3b2-679a-4ca2-9ea2-c19271be238a	6053ef95-4504-483e-afce-dbb170903cb3	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.822037+00	7ab068fb-d972-40db-9059-c95323383c0c	1	OPEN
3cb6b36c-88e7-4819-a349-6534bdaa5b88	6053ef95-4504-483e-afce-dbb170903cb3	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.822037+00	7ab068fb-d972-40db-9059-c95323383c0c	2	OPEN
04adc084-ed0e-47b9-ad9a-5a722affddbf	6053ef95-4504-483e-afce-dbb170903cb3	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.822037+00	7ab068fb-d972-40db-9059-c95323383c0c	3	OPEN
c1ddab3c-3c8d-4cb7-a573-646d34ef64ea	47118e92-5c4a-4805-a6ed-28d73c13c29e	1	tp	2025.0000000000	\N	\N	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:03.851935+00	07150cc8-50f9-443c-aa12-905c7915b48e	1	OPEN
5abab738-4491-4007-a596-200820374d32	0c1a7071-240a-401b-9668-644ad45a122b	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.824323+00	307859ce-a790-4a23-950c-2b4a79b3b701	1	OPEN
33a5819c-415a-4ac6-b9a3-0247422dc3b6	0c1a7071-240a-401b-9668-644ad45a122b	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.824323+00	307859ce-a790-4a23-950c-2b4a79b3b701	2	OPEN
e54c4abf-74f6-46ae-9038-d2f1a38fccdc	0c1a7071-240a-401b-9668-644ad45a122b	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.824323+00	307859ce-a790-4a23-950c-2b4a79b3b701	3	OPEN
979dd8a0-d0e7-4c7d-aab7-ec7d9bd96d82	3b5b3754-91cc-41e7-9c8a-291626b6cf95	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.832841+00	9ac2507b-6eee-479b-bcf9-cddd1e7220f3	1	OPEN
983db4fe-f961-4c70-b49c-58a5d3a9ce26	3b5b3754-91cc-41e7-9c8a-291626b6cf95	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.832841+00	9ac2507b-6eee-479b-bcf9-cddd1e7220f3	2	OPEN
c70fae71-1f60-4937-8395-fcbca9522a3f	3b5b3754-91cc-41e7-9c8a-291626b6cf95	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.832841+00	9ac2507b-6eee-479b-bcf9-cddd1e7220f3	3	OPEN
d9ca9d32-f071-4a5e-a076-b7eed2fe90b5	e88af324-4082-475a-8f14-ac5f8683d407	1	tp	2025.0000000000	\N	\N	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:16.841636+00	34c78733-b36d-42f6-9b13-3a6f14bf8b97	1	OPEN
2e22c4a9-935a-4d3d-9c02-d83bee138b2e	87b36464-2ebe-4d51-9239-ee0cb6557a51	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.011901+00	264f7fd6-6254-4fe3-b719-fc4ec103e89a	1	OPEN
27749859-6af7-4af7-8f35-8ca667c25ff3	87b36464-2ebe-4d51-9239-ee0cb6557a51	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.011901+00	264f7fd6-6254-4fe3-b719-fc4ec103e89a	2	OPEN
005fdcff-f957-4279-80fa-d4b7bb311c87	87b36464-2ebe-4d51-9239-ee0cb6557a51	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.011901+00	264f7fd6-6254-4fe3-b719-fc4ec103e89a	3	OPEN
ccf739f0-c3a1-40de-84d1-47c9ce37192a	6383b998-dcf3-4ec5-8abf-0e62c086ea12	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.020903+00	fa0a5ce9-c7fe-4533-8024-1abd0374c145	1	OPEN
3b9fb6b7-3655-4445-904c-7cc53536a341	6383b998-dcf3-4ec5-8abf-0e62c086ea12	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.020903+00	fa0a5ce9-c7fe-4533-8024-1abd0374c145	2	OPEN
49bff0ab-da0d-4c1f-ae81-74e0c3aa7d2e	6383b998-dcf3-4ec5-8abf-0e62c086ea12	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.020903+00	fa0a5ce9-c7fe-4533-8024-1abd0374c145	3	OPEN
ace73a2a-623f-483d-b52c-7c896437f861	03c3f7d4-82c3-46d8-b22d-2756d281be26	1	tp	2025.0000000000	\N	\N	0.1000	\N	\N	t	f	{}	2026-04-03 20:40:36.029073+00	15467611-0a52-4344-af36-915050a112fa	1	OPEN
9235d361-d9e7-442b-a6c5-f1e6ee675554	3b32a1f3-6389-4b4a-a43e-f5206dd076a6	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.376123+00	9e46c74e-d0a6-4d1a-9e80-7fd1774e8599	1	OPEN
bb073995-59b1-4692-9553-ebbcf676ec47	3b32a1f3-6389-4b4a-a43e-f5206dd076a6	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.376123+00	9e46c74e-d0a6-4d1a-9e80-7fd1774e8599	2	OPEN
c5365a77-a4ae-4c96-b56e-6dcbbfd2f8e6	3b32a1f3-6389-4b4a-a43e-f5206dd076a6	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.376123+00	9e46c74e-d0a6-4d1a-9e80-7fd1774e8599	3	OPEN
23289ee4-29db-4eec-8783-b8ebb25a0ebf	ad21ccbb-6744-405a-bc8e-d6875a31085c	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.389385+00	bfa84fad-1267-4c71-91ac-4dfcef3e1c7e	1	OPEN
d802a7ae-6434-4b04-8e46-901661b43f73	ad21ccbb-6744-405a-bc8e-d6875a31085c	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.389385+00	bfa84fad-1267-4c71-91ac-4dfcef3e1c7e	2	OPEN
ae2b0f2f-29ba-4012-8fde-fb2fbcce095a	ad21ccbb-6744-405a-bc8e-d6875a31085c	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.389385+00	bfa84fad-1267-4c71-91ac-4dfcef3e1c7e	3	OPEN
b197c078-c84f-4d47-9e3f-2d766e3a6593	ad21ccbb-6744-405a-bc8e-d6875a31085c	4	tp	4922.0000000000	4916.0000000000	4527.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.394007+00	bfa84fad-1267-4c71-91ac-4dfcef3e1c7e	4	OPEN
24f8d55a-4925-4810-a63a-92da61e689e6	6507e6e7-d200-4b4a-b79a-410b4318fcad	1	tp	4922.0000000000	4916.0000000000	4950.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.416911+00	70fcc16b-97fe-43b6-97ad-5bc96d01da24	1	OPEN
18a848d9-e804-42e6-b790-9fd6b77ca1c0	6507e6e7-d200-4b4a-b79a-410b4318fcad	2	tp	4922.0000000000	4916.0000000000	4953.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.416911+00	70fcc16b-97fe-43b6-97ad-5bc96d01da24	2	OPEN
7b7d320b-ce3a-4420-b1a5-7dd1beb6753d	6507e6e7-d200-4b4a-b79a-410b4318fcad	3	tp	4922.0000000000	4916.0000000000	4956.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:46.416911+00	70fcc16b-97fe-43b6-97ad-5bc96d01da24	3	OPEN
a8264d63-cc3b-41da-82bc-8960433983bc	6507e6e7-d200-4b4a-b79a-410b4318fcad	4	tp	4922.0000000000	4916.0000000000	4970.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:49:46.421244+00	70fcc16b-97fe-43b6-97ad-5bc96d01da24	4	OPEN
b0eff5ce-6dc8-4999-9abc-ee5f0054ec0d	6507e6e7-d200-4b4a-b79a-410b4318fcad	5	tp	4922.0000000000	4916.0000000000	4985.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:49:46.421244+00	70fcc16b-97fe-43b6-97ad-5bc96d01da24	5	OPEN
7fb8ce70-64d9-4ac6-91f7-2112548e7351	1e0d5493-5182-4ea1-bd86-5ab6feeca72b	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.625487+00	94ab7795-50e8-4363-990e-d54952aac121	1	OPEN
dc750e9a-885b-47ec-a827-bf42da8d6f35	1e0d5493-5182-4ea1-bd86-5ab6feeca72b	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.625487+00	94ab7795-50e8-4363-990e-d54952aac121	2	OPEN
e80b34dc-948a-4e6e-9186-45e46884a523	1e0d5493-5182-4ea1-bd86-5ab6feeca72b	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.625487+00	94ab7795-50e8-4363-990e-d54952aac121	3	OPEN
05a22ec0-6951-4920-9b87-9add762e489d	d655bcf0-e019-402b-afdf-5ef89997810d	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.636674+00	2009c972-dfaa-466c-8cf0-c1d69fef90ec	1	OPEN
c070f131-4ce1-4d2e-947e-9bd160caf9a4	d655bcf0-e019-402b-afdf-5ef89997810d	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.636674+00	2009c972-dfaa-466c-8cf0-c1d69fef90ec	2	OPEN
cf582520-a288-41b7-959b-178634fc5ba1	d655bcf0-e019-402b-afdf-5ef89997810d	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.636674+00	2009c972-dfaa-466c-8cf0-c1d69fef90ec	3	OPEN
4fa9097c-e829-495c-8bd0-c1da3b2c9ed2	d655bcf0-e019-402b-afdf-5ef89997810d	4	tp	4922.0000000000	4916.0000000000	4527.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.639681+00	2009c972-dfaa-466c-8cf0-c1d69fef90ec	4	OPEN
7293aebb-4ec7-4a5b-9f2d-5efa31802c43	74121f45-a56c-4253-980b-ed4fadc299f4	1	tp	4922.0000000000	4916.0000000000	4950.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.647966+00	62470ddb-9d50-4b8b-8edd-08e14075380e	1	OPEN
31c33ff3-2097-4757-9828-2c4ae3e54dd6	74121f45-a56c-4253-980b-ed4fadc299f4	2	tp	4922.0000000000	4916.0000000000	4953.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.647966+00	62470ddb-9d50-4b8b-8edd-08e14075380e	2	OPEN
048f0292-95f6-4524-855b-5221faf2755c	74121f45-a56c-4253-980b-ed4fadc299f4	3	tp	4922.0000000000	4916.0000000000	4956.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:49:59.647966+00	62470ddb-9d50-4b8b-8edd-08e14075380e	3	OPEN
456bfe04-8ccf-4be4-8612-367fc4b87692	74121f45-a56c-4253-980b-ed4fadc299f4	4	tp	4922.0000000000	4916.0000000000	4970.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:49:59.651809+00	62470ddb-9d50-4b8b-8edd-08e14075380e	4	OPEN
29967b39-19dd-4194-8273-3c271ef656c0	74121f45-a56c-4253-980b-ed4fadc299f4	5	tp	4922.0000000000	4916.0000000000	4985.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:49:59.651809+00	62470ddb-9d50-4b8b-8edd-08e14075380e	5	OPEN
76eb1154-e873-4a39-b575-430f5f595317	50172180-f869-43ce-9242-63a80f5877aa	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.542921+00	5b907b8d-754e-4c56-ac83-0cf371a52f4c	1	OPEN
62f53c8f-7d0c-4304-bc6f-64961ff51f82	50172180-f869-43ce-9242-63a80f5877aa	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.542921+00	5b907b8d-754e-4c56-ac83-0cf371a52f4c	2	OPEN
50c2b305-c3c4-414f-883d-64972debbe90	50172180-f869-43ce-9242-63a80f5877aa	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.542921+00	5b907b8d-754e-4c56-ac83-0cf371a52f4c	3	OPEN
9ebb936f-0c78-4c55-befc-ad04455dedd3	774ec162-a8e6-4a46-a5f9-b61ec6c42347	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.555094+00	33f7c544-3008-4998-b715-370270a12ba5	1	OPEN
146c3e6c-0331-43a8-a860-b220579d0b78	774ec162-a8e6-4a46-a5f9-b61ec6c42347	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.555094+00	33f7c544-3008-4998-b715-370270a12ba5	2	OPEN
41b19233-4f4b-4205-b480-b5da00354d63	774ec162-a8e6-4a46-a5f9-b61ec6c42347	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.555094+00	33f7c544-3008-4998-b715-370270a12ba5	3	OPEN
51543919-c615-48c3-821a-5a6207075a26	774ec162-a8e6-4a46-a5f9-b61ec6c42347	4	tp	4922.0000000000	4916.0000000000	4527.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.55865+00	33f7c544-3008-4998-b715-370270a12ba5	4	OPEN
e8dba792-d87b-4745-8127-66da89ba1017	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	1	tp	4922.0000000000	4916.0000000000	4950.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.567619+00	df093d93-bf7c-4144-82d1-d22309273d72	1	OPEN
171c90c3-0f2b-419e-a776-b2980d2dce17	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	2	tp	4922.0000000000	4916.0000000000	4953.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.567619+00	df093d93-bf7c-4144-82d1-d22309273d72	2	OPEN
6956f8aa-79d2-4bbf-a501-b3219a9f79bf	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	3	tp	4922.0000000000	4916.0000000000	4956.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:51:05.567619+00	df093d93-bf7c-4144-82d1-d22309273d72	3	OPEN
407810a5-955a-4c03-9817-f62bdb7191fd	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	4	tp	4922.0000000000	4916.0000000000	4970.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:51:05.570821+00	df093d93-bf7c-4144-82d1-d22309273d72	4	OPEN
465acdf4-319f-48eb-b673-17d169c22b51	840f85e9-dde6-4b3f-992f-bb5c6bf30be6	5	tp	4922.0000000000	4916.0000000000	4985.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 20:51:05.570821+00	df093d93-bf7c-4144-82d1-d22309273d72	5	OPEN
63d86357-63e0-44a4-a782-a2fa67af7d69	47ac7599-af82-494c-9b8a-078a4d7f5b41	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:32.614734+00	1d53212f-dc71-4cc8-a8fe-24c11dfeb66d	1	CLOSED
ab6668a6-70a4-40a1-9a44-8599ab6bd174	47ac7599-af82-494c-9b8a-078a4d7f5b41	2	tp	2025.0000000000	2025.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:32.614734+00	1d53212f-dc71-4cc8-a8fe-24c11dfeb66d	2	OPEN
278fb458-a17b-44c2-8767-40f0f5ae5f49	47ac7599-af82-494c-9b8a-078a4d7f5b41	3	tp	2025.0000000000	2025.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:32.614734+00	1d53212f-dc71-4cc8-a8fe-24c11dfeb66d	3	OPEN
d4fbc5aa-a458-48eb-abd5-00647e463786	66068c90-0e07-4356-8ee2-3ca9d04b0a7d	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.431386+00	b9930696-4bc0-47ca-81ba-477d0563eb70	1	CLOSED
8d0b7e0f-a91b-4835-8bdd-2eb3f78c4fc4	66068c90-0e07-4356-8ee2-3ca9d04b0a7d	2	tp	2025.0000000000	2025.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.431386+00	b9930696-4bc0-47ca-81ba-477d0563eb70	2	OPEN
ab478f78-7c77-456c-8e83-2dfaeb4fae26	66068c90-0e07-4356-8ee2-3ca9d04b0a7d	3	tp	2025.0000000000	2025.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.431386+00	b9930696-4bc0-47ca-81ba-477d0563eb70	3	OPEN
97729ce8-6c03-4f7f-b2b4-6d1acb35f665	f1a8bc8b-874f-4437-911e-413f9eda1e0b	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.444853+00	864a9165-9861-422f-9852-1c2cc77bba9a	1	OPEN
89f20e9c-78ca-457d-a6be-f3988910fec7	f1a8bc8b-874f-4437-911e-413f9eda1e0b	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.444853+00	864a9165-9861-422f-9852-1c2cc77bba9a	2	OPEN
9948fac5-44cf-42cd-9f6b-a78f23f3809e	f1a8bc8b-874f-4437-911e-413f9eda1e0b	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:57:53.444853+00	864a9165-9861-422f-9852-1c2cc77bba9a	3	OPEN
0ff015a4-4772-4934-8b84-52ab70f1fe83	22fefe9d-909c-4b6e-b070-feb72ca4d03c	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.227358+00	be106770-7c24-4c42-a8fc-abc72e778bda	1	CLOSED
337fb939-8fab-4474-9593-11cb88c0a772	22fefe9d-909c-4b6e-b070-feb72ca4d03c	2	tp	2025.0000000000	2025.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.227358+00	be106770-7c24-4c42-a8fc-abc72e778bda	2	OPEN
ac2c1969-13bf-4ac4-9fc4-4c0c5ea40e12	22fefe9d-909c-4b6e-b070-feb72ca4d03c	3	tp	2025.0000000000	2025.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.227358+00	be106770-7c24-4c42-a8fc-abc72e778bda	3	OPEN
ecd3dcc8-0e9b-4f8d-b790-c27e0d5d081e	44306f74-b4cd-4a42-8f48-eb535711b730	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.240171+00	159a8cfd-5c92-4cbe-8fa8-db706edc0d46	1	OPEN
fc6b7e04-08d4-4796-bba6-8ee5c285d7c9	44306f74-b4cd-4a42-8f48-eb535711b730	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.240171+00	159a8cfd-5c92-4cbe-8fa8-db706edc0d46	2	OPEN
cd675a71-72c0-44ab-bbfa-3bad75edb831	44306f74-b4cd-4a42-8f48-eb535711b730	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:14.240171+00	159a8cfd-5c92-4cbe-8fa8-db706edc0d46	3	OPEN
40cfe2e3-865c-49a0-9f3d-dea8fb360c14	5f2e4012-6c15-4a1f-850f-ad2c5ab66178	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.621316+00	68e22a40-8306-48ba-a937-a390bd99f6fb	1	CLOSED
332e0f48-9e5d-4913-8e9a-be1f9a39ad30	5f2e4012-6c15-4a1f-850f-ad2c5ab66178	2	tp	2025.0000000000	2025.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.621316+00	68e22a40-8306-48ba-a937-a390bd99f6fb	2	OPEN
0f2b611e-4e56-4949-ac41-f2ee31814655	5f2e4012-6c15-4a1f-850f-ad2c5ab66178	3	tp	2025.0000000000	2025.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.621316+00	68e22a40-8306-48ba-a937-a390bd99f6fb	3	OPEN
4e520791-5a68-4ec5-85d1-358fabdba5c0	4952c1e5-c64e-4a6b-9986-583413a6f7fe	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.633411+00	1350d079-c3c5-4532-8e55-86d0cd1674dc	1	OPEN
22006efc-7463-4ae9-8726-bdb35cbba1bc	4952c1e5-c64e-4a6b-9986-583413a6f7fe	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.633411+00	1350d079-c3c5-4532-8e55-86d0cd1674dc	2	OPEN
827b9d02-6631-4263-bdec-c39181bc172c	4952c1e5-c64e-4a6b-9986-583413a6f7fe	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 20:58:49.633411+00	1350d079-c3c5-4532-8e55-86d0cd1674dc	3	OPEN
f1925bc1-da86-4c13-ae2a-2ccb62baaf88	c1ebf6bc-b98c-434a-a5e4-75d7feb88363	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:02:50.073599+00	ff2b7a78-9d21-4645-8149-44ef7a3e54b4	1	OPEN
f6bd20e1-38e5-457c-bdb4-196fdc20fc0a	c1ebf6bc-b98c-434a-a5e4-75d7feb88363	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:02:50.073599+00	ff2b7a78-9d21-4645-8149-44ef7a3e54b4	2	OPEN
749191cb-d0f3-4d60-b087-1118472d97d9	c1ebf6bc-b98c-434a-a5e4-75d7feb88363	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:02:50.073599+00	ff2b7a78-9d21-4645-8149-44ef7a3e54b4	3	OPEN
488cfe9d-6f9f-44ea-b462-a11b42af8b6a	0dc82ac2-6e34-4f03-add2-c75ea138488f	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:03:29.16467+00	be7e79ad-80be-4d7b-9782-7213acb513d0	1	OPEN
0cea738c-a3e2-479a-a58c-ecef2e2e3321	0dc82ac2-6e34-4f03-add2-c75ea138488f	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:03:29.16467+00	be7e79ad-80be-4d7b-9782-7213acb513d0	2	OPEN
9de80aa4-1e2f-4ed9-b3df-0e032a571c92	0dc82ac2-6e34-4f03-add2-c75ea138488f	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:03:29.16467+00	be7e79ad-80be-4d7b-9782-7213acb513d0	3	OPEN
1aea4de7-c286-4284-9921-e1f05bb8af1e	04d0b113-af12-4b6d-890c-aade61af6bed	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:05:08.800821+00	a3d78771-9aaa-416d-8c47-e5e0d2abb4dd	1	OPEN
cf03aed3-2950-4fb7-b367-960519f63d75	04d0b113-af12-4b6d-890c-aade61af6bed	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:05:08.800821+00	a3d78771-9aaa-416d-8c47-e5e0d2abb4dd	2	OPEN
051de90b-057f-4df2-abc1-b2708329d6a3	04d0b113-af12-4b6d-890c-aade61af6bed	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:05:08.800821+00	a3d78771-9aaa-416d-8c47-e5e0d2abb4dd	3	OPEN
fcb573d0-965d-4b9c-b5d5-761b0e0a0fef	1cafb528-0fb5-4e68-aeb6-42e71f6ac92a	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:06:27.830836+00	20850be3-a68a-4f65-834b-4886c44b23ec	1	OPEN
5aea7b28-f627-41d9-9586-4985bbc25bef	1cafb528-0fb5-4e68-aeb6-42e71f6ac92a	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:06:27.830836+00	20850be3-a68a-4f65-834b-4886c44b23ec	2	OPEN
4cb7cbdd-1577-495b-8b42-7b8b94e709ce	1cafb528-0fb5-4e68-aeb6-42e71f6ac92a	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:06:27.830836+00	20850be3-a68a-4f65-834b-4886c44b23ec	3	OPEN
5989cebb-6c53-472b-8a4a-bdd7a34b1fad	397218b7-4b22-4041-a5af-d192fa9ca1b4	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:20.256197+00	fdfbef6a-63fb-4bb0-96d2-4fc4de29837a	2	OPEN
a7ebedc3-471b-4166-923e-612a3a1944c6	397218b7-4b22-4041-a5af-d192fa9ca1b4	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:20.256197+00	fdfbef6a-63fb-4bb0-96d2-4fc4de29837a	3	OPEN
87e9b0ef-cf0b-4a4b-9f43-1df201b1688e	397218b7-4b22-4041-a5af-d192fa9ca1b4	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:20.256197+00	fdfbef6a-63fb-4bb0-96d2-4fc4de29837a	1	CLOSED
65c98a8b-79bc-4825-bd00-fd3a02639859	ff8ffeef-a997-40fd-a11f-6be642acac0d	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:44.486809+00	2a4d6c00-fe6c-40c3-b08c-c36c7f21fd7d	1	CLOSED
02bcc978-6885-4529-997e-24137b339ff0	0c34e9d0-ec5b-4210-9d65-74249d3ae549	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:26:13.228648+00	2438c80a-bf70-452b-8f4f-fbb86db33f36	1	OPEN
f5bd39a3-5c0e-4459-b4ad-7833a019f6bc	ff8ffeef-a997-40fd-a11f-6be642acac0d	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:44.486809+00	2a4d6c00-fe6c-40c3-b08c-c36c7f21fd7d	2	OPEN
efa9e0ff-2b81-4f5e-9cf0-281510ba9c20	ff8ffeef-a997-40fd-a11f-6be642acac0d	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:07:44.486809+00	2a4d6c00-fe6c-40c3-b08c-c36c7f21fd7d	3	OPEN
893b06cb-2f2e-436c-8bbc-e62828a32369	0c34e9d0-ec5b-4210-9d65-74249d3ae549	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:26:13.228648+00	2438c80a-bf70-452b-8f4f-fbb86db33f36	2	OPEN
21580c4c-55af-49e8-a94f-477a41d9ffa1	0c34e9d0-ec5b-4210-9d65-74249d3ae549	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:26:13.228648+00	2438c80a-bf70-452b-8f4f-fbb86db33f36	3	OPEN
88ab1a7a-c85d-48cb-895a-8e8422129d54	a9f60005-b92f-4fb8-91eb-5944812f1c30	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.80102+00	85fc65fd-86b6-42d8-bba1-ef167a13a0b0	1	OPEN
933a6dbd-f71b-488a-9cac-9bd4125512e4	e2a59494-cfb8-4108-a1f2-9563cc0c319b	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.811064+00	c6c78b3b-effe-442a-9532-a3a049a8ba50	1	OPEN
08a691f8-cd31-4afe-8b83-3dad753f96bb	e2a59494-cfb8-4108-a1f2-9563cc0c319b	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.811064+00	c6c78b3b-effe-442a-9532-a3a049a8ba50	2	OPEN
dd3a7881-11e1-4254-b818-75cd56141975	e2a59494-cfb8-4108-a1f2-9563cc0c319b	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.811064+00	c6c78b3b-effe-442a-9532-a3a049a8ba50	3	OPEN
d22983e8-ddab-4c0e-bda0-6a809831cfb4	a9f60005-b92f-4fb8-91eb-5944812f1c30	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.80102+00	85fc65fd-86b6-42d8-bba1-ef167a13a0b0	2	OPEN
7242d64f-f6b4-43f8-83e4-194797ccdad1	a9f60005-b92f-4fb8-91eb-5944812f1c30	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.80102+00	85fc65fd-86b6-42d8-bba1-ef167a13a0b0	3	OPEN
af499c9a-4d67-4c4b-95b5-46612be65d71	9f3d69d2-fd8f-4bef-81fc-2ae2e8834683	1	tp	2025.0000000000	\N	\N	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:56.818612+00	fe4680bf-6dd4-47f7-b332-97367087e98b	1	OPEN
185e5b9d-2284-4acd-b070-093a7a681303	fe7b5960-a6f5-4fde-bac9-ad12eaa9cbff	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.673046+00	8b495e7a-16a3-47f2-b496-506f3fc7e3a5	1	OPEN
de2d5a8f-e33d-40c1-b08e-a094784790f9	fe7b5960-a6f5-4fde-bac9-ad12eaa9cbff	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.673046+00	8b495e7a-16a3-47f2-b496-506f3fc7e3a5	2	OPEN
17f6eac9-acc3-46a5-bcdf-cedaac54d962	fe7b5960-a6f5-4fde-bac9-ad12eaa9cbff	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.673046+00	8b495e7a-16a3-47f2-b496-506f3fc7e3a5	3	OPEN
4c34e129-e532-4548-b8d4-db13cfeff8a2	fe933205-2ffb-46f6-981d-3c566fc70355	1	tp	4922.0000000000	4916.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.683903+00	5cfb7c99-a700-4695-ac4a-eb95a1e2e747	1	OPEN
a1207807-c930-4dde-922b-6c5ce64b1902	fe933205-2ffb-46f6-981d-3c566fc70355	2	tp	4922.0000000000	4916.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.683903+00	5cfb7c99-a700-4695-ac4a-eb95a1e2e747	2	OPEN
9ba4f73f-67e4-4f05-b827-8c872b87874a	fe933205-2ffb-46f6-981d-3c566fc70355	3	tp	4922.0000000000	4916.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.683903+00	5cfb7c99-a700-4695-ac4a-eb95a1e2e747	3	OPEN
d9b42d52-a11f-48b4-9df6-ee2c8bca0f86	fe933205-2ffb-46f6-981d-3c566fc70355	4	tp	4922.0000000000	4916.0000000000	4527.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.687006+00	5cfb7c99-a700-4695-ac4a-eb95a1e2e747	4	OPEN
bc5235b5-e6c9-4745-a9ff-76af95a61f5a	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	1	tp	4922.0000000000	4916.0000000000	4950.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.693683+00	797785e9-75a0-4a71-a5eb-2a0db7316dfd	1	OPEN
283202e2-6306-492e-bd19-cdf1808e7d69	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	2	tp	4922.0000000000	4916.0000000000	4953.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.693683+00	797785e9-75a0-4a71-a5eb-2a0db7316dfd	2	OPEN
71b8e6e8-b2d7-46e7-ba23-532e571c66de	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	3	tp	4922.0000000000	4916.0000000000	4956.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:57.693683+00	797785e9-75a0-4a71-a5eb-2a0db7316dfd	3	OPEN
0638e1b9-45e1-4be5-9e1e-e1817a4a52e9	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	4	tp	4922.0000000000	4916.0000000000	4970.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 21:27:57.696834+00	797785e9-75a0-4a71-a5eb-2a0db7316dfd	4	OPEN
9ec5166b-b4ba-4ed4-a64a-2a45c32028b1	530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	5	tp	4922.0000000000	4916.0000000000	4985.0000000000	0.0100	\N	\N	t	f	{}	2026-04-03 21:27:57.696834+00	797785e9-75a0-4a71-a5eb-2a0db7316dfd	5	OPEN
7c4744ff-7989-4eb3-9259-f71b298c0d18	7c566562-2f73-4d2d-b26c-2ea5606539d6	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.116584+00	c9d419fb-0142-4c59-8558-aa725ae06559	1	CLOSED
176be6f0-d76c-476a-a1f0-3dacea10145a	7c566562-2f73-4d2d-b26c-2ea5606539d6	2	tp	2025.0000000000	2025.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.116584+00	c9d419fb-0142-4c59-8558-aa725ae06559	2	OPEN
b10daa2c-079d-4cad-99a2-f41860e33689	7c566562-2f73-4d2d-b26c-2ea5606539d6	3	tp	2025.0000000000	2025.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.116584+00	c9d419fb-0142-4c59-8558-aa725ae06559	3	OPEN
ca137f1c-7557-425a-9d4d-e81466ae81d3	11d7b2a7-d24c-4be6-bec6-b12f8fca4c42	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.129972+00	fdffe50a-c339-4214-95f2-24055fbf7bdb	1	OPEN
805256ee-612e-45e5-bc63-1d63639d1eec	11d7b2a7-d24c-4be6-bec6-b12f8fca4c42	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.129972+00	fdffe50a-c339-4214-95f2-24055fbf7bdb	2	OPEN
ac9181e9-66e1-40bb-b0c4-a3687dbecf9f	11d7b2a7-d24c-4be6-bec6-b12f8fca4c42	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.129972+00	fdffe50a-c339-4214-95f2-24055fbf7bdb	3	OPEN
dfdaad9b-48fb-49cf-b830-1ce86a4bf552	a7f9d16d-d7c7-4483-959a-5955c7413803	1	tp	4922.0000000000	4922.0000000000	4925.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.569245+00	106c8a28-e8c6-457d-a5d9-7b90ef5b4504	1	OPEN
9d63117e-7825-477b-9989-db5328db1bea	a7f9d16d-d7c7-4483-959a-5955c7413803	2	tp	4922.0000000000	4922.0000000000	4928.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.569245+00	106c8a28-e8c6-457d-a5d9-7b90ef5b4504	2	OPEN
6d96ef56-c430-4245-b389-759a75b03b5c	a7f9d16d-d7c7-4483-959a-5955c7413803	3	tp	4922.0000000000	4922.0000000000	4934.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 21:27:58.569245+00	106c8a28-e8c6-457d-a5d9-7b90ef5b4504	3	OPEN
e73808ad-8a7f-460e-ac9e-4a9740bc2e7d	8c6f6ce5-639e-4232-807f-7760bb545b35	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.717697+00	f22f4393-3b18-4cfc-8921-c794f505d579	1	OPEN
9c76a64b-eb79-45fd-849b-1c3901d6ba12	8c6f6ce5-639e-4232-807f-7760bb545b35	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.717697+00	f22f4393-3b18-4cfc-8921-c794f505d579	2	OPEN
7d2ea4fc-5dd5-45f4-a91e-1b57e10c918b	8c6f6ce5-639e-4232-807f-7760bb545b35	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.717697+00	f22f4393-3b18-4cfc-8921-c794f505d579	3	OPEN
050c3a94-c3d6-4bd0-88ef-d2bc395658de	8c6f6ce5-639e-4232-807f-7760bb545b35	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.717697+00	f22f4393-3b18-4cfc-8921-c794f505d579	4	OPEN
f5f7000d-69ed-4de4-a7ec-8e32b3c05ab3	41904e23-5ad5-4f91-aa3c-9c725960812c	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:21.726787+00	69a0d61f-c5b6-4915-9782-e59fc2ceb5f1	1	OPEN
9b90a054-dd2d-4f44-9264-4ac75f247ff6	41904e23-5ad5-4f91-aa3c-9c725960812c	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:21.726787+00	69a0d61f-c5b6-4915-9782-e59fc2ceb5f1	2	OPEN
8ea8a8f3-9e29-4d1b-974d-0aaa67bc9496	41904e23-5ad5-4f91-aa3c-9c725960812c	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:21.726787+00	69a0d61f-c5b6-4915-9782-e59fc2ceb5f1	3	OPEN
6f8c3160-c0b7-48d1-bb9c-4734336d87c7	41904e23-5ad5-4f91-aa3c-9c725960812c	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:21.726787+00	69a0d61f-c5b6-4915-9782-e59fc2ceb5f1	4	OPEN
6bc73bbc-f684-4472-be4c-fb2047f6ef63	26d8f3b3-0c73-4576-8493-4be89f81cbc3	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.680378+00	56c08e89-1735-48b1-835a-55776b941c9a	1	OPEN
40787e6f-257d-498f-ad7b-93bcfcd3c4e2	26d8f3b3-0c73-4576-8493-4be89f81cbc3	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.680378+00	56c08e89-1735-48b1-835a-55776b941c9a	2	OPEN
a62ce68c-dc86-45b4-8b12-d7a9f5ed094a	26d8f3b3-0c73-4576-8493-4be89f81cbc3	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.680378+00	56c08e89-1735-48b1-835a-55776b941c9a	3	OPEN
a5ea1424-df3f-4ea3-89d0-66548b9f7dd5	26d8f3b3-0c73-4576-8493-4be89f81cbc3	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:21.680378+00	56c08e89-1735-48b1-835a-55776b941c9a	4	OPEN
6cd85b7b-32a9-4932-aaea-8b0ea2514210	c8facc82-a136-4de7-a9aa-5d2803019dbe	1	tp	2025.0000000000	2010.0000000000	4690.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:21.734543+00	7e97b199-c034-49cf-8962-ad461ab03d06	1	OPEN
6a0c27ee-4780-49f7-b1c1-c36022d98a42	c8facc82-a136-4de7-a9aa-5d2803019dbe	2	tp	2025.0000000000	2010.0000000000	4701.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:21.734543+00	7e97b199-c034-49cf-8962-ad461ab03d06	2	OPEN
c2456b25-5557-4d5e-b563-909af1803063	f6b5dc43-f372-4555-9ce7-2a310f91ea72	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:21.741467+00	a4a8dd56-b69f-40c3-8090-a3f48bf7148a	1	OPEN
ba20a7b0-2d3c-4909-82da-036bdc6fe053	f6b5dc43-f372-4555-9ce7-2a310f91ea72	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:21.741467+00	a4a8dd56-b69f-40c3-8090-a3f48bf7148a	2	OPEN
f1f5fed4-022f-4f52-8a72-01bc6ac8fcd8	f6b5dc43-f372-4555-9ce7-2a310f91ea72	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:21.741467+00	a4a8dd56-b69f-40c3-8090-a3f48bf7148a	3	OPEN
91f98f4f-d67d-4d9f-a997-399118aa693a	f6b5dc43-f372-4555-9ce7-2a310f91ea72	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:21.741467+00	a4a8dd56-b69f-40c3-8090-a3f48bf7148a	4	OPEN
b6e72787-533d-42f9-9a56-b89d6b6a2b6f	4fe39f82-6d44-432a-b2db-158508055a0a	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.131612+00	61efca0a-fc62-424c-82e0-cdfac34adea6	1	OPEN
f3e0ceb6-fbdb-4c09-b6f4-b26b763f0382	4fe39f82-6d44-432a-b2db-158508055a0a	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.131612+00	61efca0a-fc62-424c-82e0-cdfac34adea6	2	OPEN
90af259f-5ddb-4a58-8d27-8774991857c4	4fe39f82-6d44-432a-b2db-158508055a0a	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.131612+00	61efca0a-fc62-424c-82e0-cdfac34adea6	3	OPEN
eaa6dc3a-51cd-4754-b2ec-79ed6208bb4d	4fe39f82-6d44-432a-b2db-158508055a0a	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.131612+00	61efca0a-fc62-424c-82e0-cdfac34adea6	4	OPEN
7f78d13b-7c56-4e32-9546-3a611031b1b2	a0388a18-6936-4fed-8749-8034132a02ba	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.141839+00	bfcb9ac3-6b3d-45c0-8ddb-74c93050eb55	1	OPEN
8ed9d368-5ad6-4ef0-bc88-1d95041eef24	a0388a18-6936-4fed-8749-8034132a02ba	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.141839+00	bfcb9ac3-6b3d-45c0-8ddb-74c93050eb55	2	OPEN
8ccb8c3e-6ce6-4465-bb73-dd4df3d558de	a0388a18-6936-4fed-8749-8034132a02ba	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.141839+00	bfcb9ac3-6b3d-45c0-8ddb-74c93050eb55	3	OPEN
13c429fa-3290-4b44-9e22-d9fb5974e9cf	a0388a18-6936-4fed-8749-8034132a02ba	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:34.141839+00	bfcb9ac3-6b3d-45c0-8ddb-74c93050eb55	4	OPEN
1dbbde57-70b7-4c48-838b-073b90da7735	c6093315-90a1-4fa0-a84f-30520c8f029e	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:34.149623+00	5b2cbc57-63ca-4baf-8ca5-97e1b366efe3	1	OPEN
569f81e5-6209-447c-9ced-452e9a075e80	c6093315-90a1-4fa0-a84f-30520c8f029e	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:34.149623+00	5b2cbc57-63ca-4baf-8ca5-97e1b366efe3	2	OPEN
52dc4cb3-bc86-4d5f-bd53-7b039b76d0c8	c6093315-90a1-4fa0-a84f-30520c8f029e	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:34.149623+00	5b2cbc57-63ca-4baf-8ca5-97e1b366efe3	3	OPEN
c2b3ce92-93b6-45ca-9fe6-285154fe0a12	c6093315-90a1-4fa0-a84f-30520c8f029e	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:34.149623+00	5b2cbc57-63ca-4baf-8ca5-97e1b366efe3	4	OPEN
b3e9cf43-494d-48e9-b500-9b4cbeecb710	dc8b8c43-a9b2-4a53-9b1d-d917c58ab82e	1	tp	2025.0000000000	2010.0000000000	4690.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:34.156809+00	9d0be965-2983-4951-9efb-5a3f05a9331a	1	OPEN
09ef407d-6a8d-42de-8eed-9e33b7df50af	dc8b8c43-a9b2-4a53-9b1d-d917c58ab82e	2	tp	2025.0000000000	2010.0000000000	4701.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:34.156809+00	9d0be965-2983-4951-9efb-5a3f05a9331a	2	OPEN
4523376a-ce43-4376-95b0-f6c2f5091dd5	2165441a-4f1c-40c0-8655-05e15cb77afe	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:34.163921+00	cdcc4da3-2998-4409-9e2b-85c078cac2cb	1	OPEN
ab557e85-862b-4d3a-8dfa-1fc1a242a953	2165441a-4f1c-40c0-8655-05e15cb77afe	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:34.163921+00	cdcc4da3-2998-4409-9e2b-85c078cac2cb	2	OPEN
b3836cac-bf37-4c84-8b57-11e4d8a7413c	2165441a-4f1c-40c0-8655-05e15cb77afe	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:34.163921+00	cdcc4da3-2998-4409-9e2b-85c078cac2cb	3	OPEN
b2c81c4e-58c5-4f44-9407-0d690da6aa6d	2165441a-4f1c-40c0-8655-05e15cb77afe	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:34.163921+00	cdcc4da3-2998-4409-9e2b-85c078cac2cb	4	OPEN
1246dded-bab7-4050-9607-22eae8929d20	a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.141688+00	07810645-f584-428f-980e-a477d96fe881	1	OPEN
c5e92547-769c-4460-8e18-67547325a6ea	a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.141688+00	07810645-f584-428f-980e-a477d96fe881	2	OPEN
d854abf3-9794-40a1-abdb-39369243c743	a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.141688+00	07810645-f584-428f-980e-a477d96fe881	3	OPEN
78556c1f-1add-4c8d-97dc-5d1858cc2604	a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.141688+00	07810645-f584-428f-980e-a477d96fe881	4	OPEN
35cd0095-996f-41fc-8d9f-2090d76115f1	258c8c76-d09b-47c2-92c2-9f4878faed73	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.152841+00	acba5d94-cc9b-4baa-a0c1-1ec6c554bb53	1	OPEN
f4e910d6-4608-44aa-aad0-693065e6dcbe	258c8c76-d09b-47c2-92c2-9f4878faed73	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.152841+00	acba5d94-cc9b-4baa-a0c1-1ec6c554bb53	2	OPEN
71742899-61c8-4c4b-a43b-eae0c61c8745	258c8c76-d09b-47c2-92c2-9f4878faed73	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.152841+00	acba5d94-cc9b-4baa-a0c1-1ec6c554bb53	3	OPEN
f6d052e7-a9ff-48f8-8925-847f5470bb81	258c8c76-d09b-47c2-92c2-9f4878faed73	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:18:52.152841+00	acba5d94-cc9b-4baa-a0c1-1ec6c554bb53	4	OPEN
fd471818-5d3b-4e17-a9c1-7986b238e131	666edf02-f17b-47c2-9b5f-51252bf33338	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:52.160911+00	60d37206-7cb5-4055-bd8b-7134b6a1faac	1	OPEN
3651ef30-32df-435f-a493-7239d4cfbe7e	666edf02-f17b-47c2-9b5f-51252bf33338	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:52.160911+00	60d37206-7cb5-4055-bd8b-7134b6a1faac	2	OPEN
48d179be-a34a-42ef-a9c8-bfd3df4b8697	666edf02-f17b-47c2-9b5f-51252bf33338	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:52.160911+00	60d37206-7cb5-4055-bd8b-7134b6a1faac	3	OPEN
79dd78f1-317c-426c-b16f-4ee00cfbe617	666edf02-f17b-47c2-9b5f-51252bf33338	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:18:52.160911+00	60d37206-7cb5-4055-bd8b-7134b6a1faac	4	OPEN
e48638bc-2b39-471e-ae87-5ad7a5e00fe5	7c1a0e9f-8324-4d19-92d9-2ce5d3dce2cc	1	tp	2025.0000000000	2010.0000000000	4690.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:52.168409+00	a1ea73d2-c543-49e6-8889-6debf5c9305c	1	OPEN
cd70f2dd-c938-47fc-b636-ca526e371a34	7c1a0e9f-8324-4d19-92d9-2ce5d3dce2cc	2	tp	2025.0000000000	2010.0000000000	4701.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:18:52.168409+00	a1ea73d2-c543-49e6-8889-6debf5c9305c	2	OPEN
dc257d5e-5c3a-40de-a60e-9f7b563aea05	6d9905d4-78ee-4c46-96c8-e252a7112f18	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:52.174536+00	ea7ea8b2-8606-4365-9c04-4f90028e1c7d	1	OPEN
8a5c1997-67d5-4034-b7aa-9115b7c74655	6d9905d4-78ee-4c46-96c8-e252a7112f18	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:52.174536+00	ea7ea8b2-8606-4365-9c04-4f90028e1c7d	2	OPEN
7ca93476-db2e-462a-8ba3-d82f9bd9457a	6d9905d4-78ee-4c46-96c8-e252a7112f18	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:52.174536+00	ea7ea8b2-8606-4365-9c04-4f90028e1c7d	3	OPEN
bbe24f9a-4975-44b7-9cee-8116ecb61898	6d9905d4-78ee-4c46-96c8-e252a7112f18	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:18:52.174536+00	ea7ea8b2-8606-4365-9c04-4f90028e1c7d	4	OPEN
f5c5332b-5a84-499f-bfb0-a38c809908c4	318d72a0-26ef-47cc-b8d8-181cb75c6f3b	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.333963+00	08f20fea-bec3-44bd-9a86-217368c783ee	1	OPEN
b1d313ee-38b3-4ac6-a46e-5b985218dc8c	318d72a0-26ef-47cc-b8d8-181cb75c6f3b	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.333963+00	08f20fea-bec3-44bd-9a86-217368c783ee	2	OPEN
3d303f4d-b73f-4924-9026-ed901dd52982	318d72a0-26ef-47cc-b8d8-181cb75c6f3b	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.333963+00	08f20fea-bec3-44bd-9a86-217368c783ee	3	OPEN
c172a4df-5c59-4946-ba95-970dc9d5910b	318d72a0-26ef-47cc-b8d8-181cb75c6f3b	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.333963+00	08f20fea-bec3-44bd-9a86-217368c783ee	4	OPEN
e2a6c6e8-e355-4039-81ce-582073f33d35	3e96ea12-917e-423d-8835-fdcf6e96c974	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.346302+00	bdaed2ce-29ea-46b2-b321-efa558272674	1	OPEN
8de7b865-4e36-4c5b-b21d-20b51cf1fdfb	3e96ea12-917e-423d-8835-fdcf6e96c974	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.346302+00	bdaed2ce-29ea-46b2-b321-efa558272674	2	OPEN
35a0ff07-eeaa-4579-b2f8-11b4df52b3dc	3e96ea12-917e-423d-8835-fdcf6e96c974	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.346302+00	bdaed2ce-29ea-46b2-b321-efa558272674	3	OPEN
504d3c66-c312-4386-8dc2-23669973c258	3e96ea12-917e-423d-8835-fdcf6e96c974	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0500	\N	\N	t	f	{}	2026-04-03 22:21:53.346302+00	bdaed2ce-29ea-46b2-b321-efa558272674	4	OPEN
09c8eece-6137-42e9-ac32-f682a4c56512	1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:21:53.353469+00	9b05146b-62be-46e5-8242-e7364991e200	1	OPEN
d11e8847-9390-4a55-ae89-33ab1d7a4ed7	1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:21:53.353469+00	9b05146b-62be-46e5-8242-e7364991e200	2	OPEN
8299082e-41e6-40d3-b1df-a44e9e28c6cd	1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:21:53.353469+00	9b05146b-62be-46e5-8242-e7364991e200	3	OPEN
e4205457-33e1-4c53-8e20-e28094b1b0db	1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.0400	\N	\N	t	f	{}	2026-04-03 22:21:53.353469+00	9b05146b-62be-46e5-8242-e7364991e200	4	OPEN
b9f2799a-89e9-47f7-a1d3-38d8f07e0362	81c9d440-379a-43af-8908-2dcd55d4bd8c	1	tp	2025.0000000000	2010.0000000000	4690.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:21:53.360403+00	4a25a111-6298-471a-bd05-f2c64a629c5d	1	OPEN
640ff1ce-1cdb-4f02-9c75-e719fccb6afc	81c9d440-379a-43af-8908-2dcd55d4bd8c	2	tp	2025.0000000000	2010.0000000000	4701.0000000000	0.4000	\N	\N	t	f	{}	2026-04-03 22:21:53.360403+00	4a25a111-6298-471a-bd05-f2c64a629c5d	2	OPEN
e5bc11bb-6bd0-4f92-8596-bb9508217f10	05bb2611-213f-458b-bcd8-df8c7b3a0a60	1	tp	2025.0000000000	2010.0000000000	2030.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:21:53.366298+00	662a77bf-524f-4ed4-9db0-39a200a0a18a	1	OPEN
ca352c02-01fb-4a15-bf8e-e1528bd8552e	05bb2611-213f-458b-bcd8-df8c7b3a0a60	2	tp	2025.0000000000	2010.0000000000	2040.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:21:53.366298+00	662a77bf-524f-4ed4-9db0-39a200a0a18a	2	OPEN
c2cfb8e1-7a07-458b-8692-6106a5defa48	05bb2611-213f-458b-bcd8-df8c7b3a0a60	3	tp	2025.0000000000	2010.0000000000	2050.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:21:53.366298+00	662a77bf-524f-4ed4-9db0-39a200a0a18a	3	OPEN
e5a973ad-0285-4560-8a17-762edbb8104a	05bb2611-213f-458b-bcd8-df8c7b3a0a60	4	tp	2025.0000000000	2010.0000000000	2060.0000000000	0.1000	\N	\N	t	f	{}	2026-04-03 22:21:53.366298+00	662a77bf-524f-4ed4-9db0-39a200a0a18a	4	OPEN
\.


--
-- Data for Name: trade_plans; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, lot_total, lot_per_leg, legs_count, candidate_expires_at, policy_reasons, meta, created_at, updated_at) FROM stdin;
035b82f2-cc26-425a-a09e-a0b6c102de4f	a96dd72d-e1d4-49f6-b0a4-41fd04dbc821	09a52cfc-4d61-40d7-93af-ddc2974eb157	require_approval	t	\N	\N	1	\N	{approval_required}	{}	2026-04-03 20:12:24.224722+00	2026-04-03 20:12:24.224722+00
8c8d99e5-a236-41b3-b84e-324e13e3d226	a0e70f8c-ea66-4366-a024-ffe35cf378ff	09a52cfc-4d61-40d7-93af-ddc2974eb157	require_approval	t	\N	\N	1	\N	{mubeen_high_risk_requires_approval}	{"source": "approvals_service"}	2026-04-03 20:20:09.447733+00	2026-04-03 20:20:09.447733+00
7666787c-02fb-4424-9cdd-9148cb4fe64e	3658bdd4-ca6d-4d4c-af58-40013b3cf875	09a52cfc-4d61-40d7-93af-ddc2974eb157	require_approval	t	\N	\N	1	\N	{mubeen_high_risk_requires_approval}	{"source": "approvals_service"}	2026-04-03 20:20:09.454022+00	2026-04-03 20:20:09.454022+00
f0fd2c6a-53a5-485f-9868-a29e21629c7f	802a7a20-488f-4691-a22e-c96c4a608783	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:39:29.340287+00	2026-04-03 20:39:29.340287+00
dd09c66a-5ee3-4d52-8d08-d9650f1c82f4	6384ef2b-88d3-4e9c-9dc5-0e89c700b609	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:03.808341+00	2026-04-03 20:40:03.808341+00
6053ef95-4504-483e-afce-dbb170903cb3	94b5efcd-e18b-414f-87df-326ca0df9fa1	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:03.819489+00	2026-04-03 20:40:03.819489+00
47118e92-5c4a-4805-a6ed-28d73c13c29e	5036b649-b3c1-46e5-b5e3-12ec1b529e11	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:03.848728+00	2026-04-03 20:40:03.848728+00
0c1a7071-240a-401b-9668-644ad45a122b	2020f1c5-e82d-4275-9fce-30c065dcbee1	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:16.819243+00	2026-04-03 20:40:16.819243+00
3b5b3754-91cc-41e7-9c8a-291626b6cf95	bf84564a-8075-47e0-9a5e-c188b3f18bf0	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:16.830315+00	2026-04-03 20:40:16.830315+00
e88af324-4082-475a-8f14-ac5f8683d407	cbc19947-48a3-4fff-aab1-c19529691879	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:16.838117+00	2026-04-03 20:40:16.838117+00
87b36464-2ebe-4d51-9239-ee0cb6557a51	78e1d4c7-221d-4bc0-8cde-7bd790aa8d9b	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:36.001292+00	2026-04-03 20:40:36.001292+00
6383b998-dcf3-4ec5-8abf-0e62c086ea12	4e058e7a-c512-4ff6-825f-8c399835c395	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:36.01819+00	2026-04-03 20:40:36.01819+00
03c3f7d4-82c3-46d8-b22d-2756d281be26	5e85c36a-7fb4-4cad-8f5f-db75eb673035	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:40:36.026382+00	2026-04-03 20:40:36.026382+00
3b32a1f3-6389-4b4a-a43e-f5206dd076a6	cdedf728-de44-4550-b3aa-69a6885d9e65	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:46.367059+00	2026-04-03 20:49:46.367059+00
ad21ccbb-6744-405a-bc8e-d6875a31085c	b2de2bb3-ea10-49ed-87ba-bc1f19505c7e	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:46.386882+00	2026-04-03 20:49:46.386882+00
6507e6e7-d200-4b4a-b79a-410b4318fcad	a301185b-7bb4-44c3-95fb-5f2b6ba8db94	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:46.413466+00	2026-04-03 20:49:46.413466+00
1e0d5493-5182-4ea1-bd86-5ab6feeca72b	3ea697d7-758b-463c-a4bc-cf4b5b82ef7c	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:59.62046+00	2026-04-03 20:49:59.62046+00
d655bcf0-e019-402b-afdf-5ef89997810d	e08335eb-ffc7-467c-a0e5-38bccb316968	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:59.634441+00	2026-04-03 20:49:59.634441+00
74121f45-a56c-4253-980b-ed4fadc299f4	1e065d1a-2a6f-4674-96f8-5faa9159ed76	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:49:59.645539+00	2026-04-03 20:49:59.645539+00
50172180-f869-43ce-9242-63a80f5877aa	c4165dd6-1995-4003-a6d6-6f240120323d	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:51:05.535837+00	2026-04-03 20:51:05.535837+00
774ec162-a8e6-4a46-a5f9-b61ec6c42347	c1a91826-79eb-4ec9-988a-0c3d8c041249	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:51:05.551267+00	2026-04-03 20:51:05.551267+00
840f85e9-dde6-4b3f-992f-bb5c6bf30be6	1788158b-a537-4b9d-bac2-ad112b154362	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:51:05.565345+00	2026-04-03 20:51:05.565345+00
47ac7599-af82-494c-9b8a-078a4d7f5b41	0210b7d9-44d1-44ed-8b49-7509329d08a9	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:57:32.607904+00	2026-04-03 20:57:32.607904+00
66068c90-0e07-4356-8ee2-3ca9d04b0a7d	297ff76e-a63a-473a-9c2e-eb40a55c501a	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:57:53.426095+00	2026-04-03 20:57:53.426095+00
f1a8bc8b-874f-4437-911e-413f9eda1e0b	2790b42d-55c5-403f-aa2d-f641ee074a81	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:57:53.442426+00	2026-04-03 20:57:53.442426+00
22fefe9d-909c-4b6e-b070-feb72ca4d03c	5255ff19-41ce-4397-9205-f07cd4146ad3	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:58:14.220531+00	2026-04-03 20:58:14.220531+00
44306f74-b4cd-4a42-8f48-eb535711b730	7ec485d1-8d41-476d-a307-fbca8fc8af5e	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:58:14.237699+00	2026-04-03 20:58:14.237699+00
5f2e4012-6c15-4a1f-850f-ad2c5ab66178	9647ad4d-4764-4302-9093-1fcc2e49b19a	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:58:49.611826+00	2026-04-03 20:58:49.611826+00
4952c1e5-c64e-4a6b-9986-583413a6f7fe	df23dcdf-f648-4a77-89c2-2c7dc0c801e1	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 20:58:49.631+00	2026-04-03 20:58:49.631+00
c1ebf6bc-b98c-434a-a5e4-75d7feb88363	bcae035f-75e3-4f4a-b86e-8e776907e826	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:02:50.065587+00	2026-04-03 21:02:50.065587+00
0dc82ac2-6e34-4f03-add2-c75ea138488f	732e5e56-2872-449c-b399-750184f73370	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:03:29.155382+00	2026-04-03 21:03:29.155382+00
04d0b113-af12-4b6d-890c-aade61af6bed	ab42dbbb-1183-44ba-90cb-231a472e00b1	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:05:08.79502+00	2026-04-03 21:05:08.79502+00
1cafb528-0fb5-4e68-aeb6-42e71f6ac92a	c889c719-bf17-41c4-8d06-4273f9826340	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:06:27.823298+00	2026-04-03 21:06:27.823298+00
397218b7-4b22-4041-a5af-d192fa9ca1b4	bee37c84-17ed-4eae-b73a-3b9829bea716	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{smoke}	{}	2026-04-03 21:07:20.246035+00	2026-04-03 21:07:20.246035+00
ff8ffeef-a997-40fd-a11f-6be642acac0d	cda005ea-8c2f-4cdd-a171-1658b24fa6e8	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{smoke}	{}	2026-04-03 21:07:44.477234+00	2026-04-03 21:07:44.477234+00
0c34e9d0-ec5b-4210-9d65-74249d3ae549	ff05bf6e-7959-4a6a-a7ff-45b20190a7ae	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:26:13.222477+00	2026-04-03 21:26:13.222477+00
a9f60005-b92f-4fb8-91eb-5944812f1c30	36b6828b-503f-4da0-abf7-51c942ceb90a	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:56.792247+00	2026-04-03 21:27:56.792247+00
e2a59494-cfb8-4108-a1f2-9563cc0c319b	2ff82c48-7800-4e9a-b28a-5990ee777efa	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:56.806971+00	2026-04-03 21:27:56.806971+00
9f3d69d2-fd8f-4bef-81fc-2ae2e8834683	53b639b2-b507-497d-b674-b877bb093d5d	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:56.81633+00	2026-04-03 21:27:56.81633+00
fe7b5960-a6f5-4fde-bac9-ad12eaa9cbff	dcaf24cf-0523-43b4-8e31-5f3bfff18b11	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:57.666223+00	2026-04-03 21:27:57.666223+00
fe933205-2ffb-46f6-981d-3c566fc70355	83a7e7f7-e03f-4cee-bd07-172d0ae157fb	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:57.681386+00	2026-04-03 21:27:57.681386+00
530ef4c2-0bed-4ffd-aaa4-f32f8dc3588a	95b26403-e600-412d-95d1-d1f3f7b20141	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:57.691476+00	2026-04-03 21:27:57.691476+00
7c566562-2f73-4d2d-b26c-2ea5606539d6	04fb282d-144b-460e-bb6b-9831a0bf0885	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:58.10856+00	2026-04-03 21:27:58.10856+00
11d7b2a7-d24c-4be6-bec6-b12f8fca4c42	542e566a-c6b0-46bc-9840-469af776ad3d	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:58.127538+00	2026-04-03 21:27:58.127538+00
a7f9d16d-d7c7-4483-959a-5955c7413803	0c3a607b-bfb7-4cf2-a1d4-2599be25fada	21ef5d9a-3798-4990-9839-32e1e8dd37ba	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 21:27:58.561892+00	2026-04-03 21:27:58.561892+00
b1b3ccde-1485-4ab7-9a9d-682b54176e9e	07c17981-c2e3-49ee-9203-e58057e8a2b5	545a7094-7611-4c6e-a8c2-cedf56f6513d	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:26.49059+00	2026-04-03 22:17:26.49059+00
46481267-818c-469d-94ad-c33e3f209f18	363bc708-9411-4ef2-b41b-0f40a14267ef	feb955ba-8b12-4c3d-a0fb-af8b73b54696	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:42.087418+00	2026-04-03 22:17:42.087418+00
2f74f107-6b58-4e93-9fdd-50036096f1ba	84421644-aac4-4f4c-83dd-72d41c96c5b2	4392de58-270a-4bb2-97a9-a1a81b6ac544	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:42.216003+00	2026-04-03 22:17:42.216003+00
6f5203ec-01d1-45a1-84d4-f85bc9b06f66	d188c938-552a-490f-851d-5c4b7752e608	946f9428-0379-4888-94b6-9c4f8943509a	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:42.324965+00	2026-04-03 22:17:42.324965+00
9d7e618b-c70b-427c-9f1d-059659a3dfd4	45ba3329-4aed-4f2a-8bfd-f0f65292cdf2	39094c3e-21fd-4c81-a781-a27a25e7f185	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:42.432171+00	2026-04-03 22:17:42.432171+00
3e85df6d-0b49-4f71-b2ad-77a05594259a	e01d8f16-1a70-4fb4-979c-d9b9e0583621	1c00bf39-29c9-4c3d-836d-3e2ef4bdb9b2	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:17:42.539643+00	2026-04-03 22:17:42.539643+00
d95bf498-637a-4674-a806-0a6657ee7a52	9933c38c-7289-48b5-b4fc-f627207e50b3	9e16133d-7e8c-4378-9be9-c10eb28f068d	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:05.780998+00	2026-04-03 22:18:05.780998+00
44ce616e-a55b-42ce-9854-b9378ca8add5	2bb69f0f-18c1-40d3-8068-2d2c815271ad	e6c465a9-5fe4-48ca-ba9b-d3acdc92ffc1	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:05.907617+00	2026-04-03 22:18:05.907617+00
12391ddf-00ae-4615-a24c-c3483d669d9b	d1ac0956-c112-4508-b7d6-233a276b9b6f	d477032c-d3d1-4557-ab87-04c201139ceb	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:06.019037+00	2026-04-03 22:18:06.019037+00
ba7c4178-89b4-4f74-a248-1e3f1bdfa15e	67ae54be-a296-4e24-9806-35ee3877140c	d01ab4d2-d515-4ccf-b72f-11a121ab8773	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:06.130525+00	2026-04-03 22:18:06.130525+00
965eca84-0d32-4e2b-afaa-5dc84d0eea5e	d31e9f5e-b578-47a6-b910-05edcbbf42f6	c25e86f9-1862-450c-a255-e7bf2ef7eb11	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:06.240272+00	2026-04-03 22:18:06.240272+00
26d8f3b3-0c73-4576-8493-4be89f81cbc3	d153b796-93db-453c-bacd-715fe2ed1148	ef228b4f-1aac-46b3-84d4-ee5ca0a54da6	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:21.672404+00	2026-04-03 22:18:21.672404+00
8c6f6ce5-639e-4232-807f-7760bb545b35	9d80fa21-706f-4f1f-bdc4-c8875fb9315d	daffc05c-6315-4b19-8819-652140b7cbe1	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:21.712283+00	2026-04-03 22:18:21.712283+00
41904e23-5ad5-4f91-aa3c-9c725960812c	b5c3b213-d159-4a99-a6ad-7063d2022e80	7ccae282-2a32-4214-b81e-0469462064a8	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:21.723139+00	2026-04-03 22:18:21.723139+00
c8facc82-a136-4de7-a9aa-5d2803019dbe	a02d2c14-3de2-4431-b77f-ee71c579d9b8	23bf57be-08ef-48f0-a55b-ee27f8832feb	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:21.731582+00	2026-04-03 22:18:21.731582+00
f6b5dc43-f372-4555-9ce7-2a310f91ea72	f296cf43-3ada-4adf-9e6b-ef0aad515aa9	3124081e-3ba8-4ffb-9ab8-6e2df38aa102	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:21.738179+00	2026-04-03 22:18:21.738179+00
4fe39f82-6d44-432a-b2db-158508055a0a	ce2dc344-76bd-4d9c-ae55-6df40570dc27	5cd409c1-539b-4090-9463-807acf89608d	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:34.123482+00	2026-04-03 22:18:34.123482+00
a0388a18-6936-4fed-8749-8034132a02ba	b884ecc4-05b6-4fa5-a4f9-164b5af0f122	6666dd6e-a1b6-468b-8254-60d08a0343e8	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:34.138995+00	2026-04-03 22:18:34.138995+00
c6093315-90a1-4fa0-a84f-30520c8f029e	0a95f015-a32b-47f0-a09b-b533d47e7616	a232161d-b7eb-4352-b294-9a032e9f3dbd	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:34.146141+00	2026-04-03 22:18:34.146141+00
dc8b8c43-a9b2-4a53-9b1d-d917c58ab82e	30f22593-11a3-4fcb-87ea-0e012fa19031	77931193-66f4-4059-9a45-8fd508202ad7	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:34.154188+00	2026-04-03 22:18:34.154188+00
2165441a-4f1c-40c0-8655-05e15cb77afe	5aadc761-827e-4835-96f9-7adb10428207	4968e2f2-56bd-48b8-995f-5afae76c5e17	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:34.160373+00	2026-04-03 22:18:34.160373+00
a2c0ed30-31bc-4c86-95d5-84f5943d6d5c	a7af5b1d-125d-4c32-9384-a0d291bd4f1a	4844ef78-0ecb-47e4-8804-63f1d0e0bf1f	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:52.136249+00	2026-04-03 22:18:52.136249+00
258c8c76-d09b-47c2-92c2-9f4878faed73	1e960f4b-7143-409b-83aa-e0d6fdb527c2	2dea5bda-b6b9-4140-bb17-b96491985e6c	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:52.149992+00	2026-04-03 22:18:52.149992+00
666edf02-f17b-47c2-9b5f-51252bf33338	b7f56819-0e26-4b9d-9e26-d6b7169c9e2a	0e2087ea-a5a5-42b1-b25e-fbc5671bce67	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:52.158023+00	2026-04-03 22:18:52.158023+00
7c1a0e9f-8324-4d19-92d9-2ce5d3dce2cc	9ecc9106-b955-440f-a78f-788bd8649202	b0b638a8-0bc6-44cb-ada3-b828f3641e7d	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:52.165817+00	2026-04-03 22:18:52.165817+00
6d9905d4-78ee-4c46-96c8-e252a7112f18	3835649c-e0f9-4d82-83a9-3fa7039a39ab	847d1eb6-b556-4aee-bbba-fe940171153c	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:18:52.17185+00	2026-04-03 22:18:52.17185+00
318d72a0-26ef-47cc-b8d8-181cb75c6f3b	87addf72-f3e9-4126-9d86-a970f5cda2f6	6a8ced54-c85e-4104-9b6d-9515240f5799	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:21:53.327781+00	2026-04-03 22:21:53.327781+00
3e96ea12-917e-423d-8835-fdcf6e96c974	3e6f896d-de30-49fc-8953-b7734dcd7676	4b23c3da-90e6-4113-b8f8-953d75f563d6	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:21:53.343125+00	2026-04-03 22:21:53.343125+00
1214ebf9-5d5d-42b8-b7aa-9e3cece16a19	53e1ce2f-0430-41cb-8b89-528fb4acd976	cad218aa-a82d-4d08-b01b-5c69448b6370	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:21:53.350739+00	2026-04-03 22:21:53.350739+00
81c9d440-379a-43af-8908-2dcd55d4bd8c	33993392-8a9a-42b0-b443-da0601eb9e2e	d911eab5-c050-4fbc-84b0-2d5a4e6065d3	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:21:53.357547+00	2026-04-03 22:21:53.357547+00
05bb2611-213f-458b-bcd8-df8c7b3a0a60	65abf42e-cda2-4514-9e3b-113456a6d4c0	fb88b82f-5e04-4fa3-8eaf-9c15cc1a8f65	allow	f	\N	\N	1	\N	{seed}	{}	2026-04-03 22:21:53.363786+00	2026-04-03 22:21:53.363786+00
\.


--
-- Data for Name: trade_updates; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.trade_updates (update_id, provider, chat_id, source_msg_pk, kind, symbol_canonical, target_intent_id, target_plan_id, new_entry_price, new_sl_price, new_tp_prices, instruction_text, meta, created_at) FROM stdin;
41329041-1077-4acd-8799-e1e40e10531e	mubeen	-1002298510219	a430edb4-a3bc-472d-ad0e-a60cfa3153a9	move_tp	BTCUSD	\N	\N	\N	\N	{53000.0000000000}	BTC update: TP1 to 53000	{"sl": null, "tps": [], "meta": {}, "side": null, "entry": null, "flags": [], "symbol": null, "update": {"notes": [], "symbol": "BTCUSD", "add_tps": [], "close_all": false, "raw_symbol": "BTC", "close_partial": null, "move_sl_to_be": false, "move_sl_to_entry": false, "move_sl_to_price": null, "move_tp_to_price": {"1": "53000"}}, "raw_text": "BTC update: TP1 to 53000", "be_at_tp1": true, "clean_text": "BTC update: TP1 to 53000", "confidence": 80, "order_type": null, "raw_symbol": null, "unofficial": false, "message_type": "UPDATE", "provider_code": "mubeen"}	2026-03-24 16:29:24.605994+00
ca45217e-3245-44f7-97f6-f077ff76fc27	mubeen	-1002298510219	5919aa78-bbc9-4d34-9378-0a81ca7f47a0	move_tp	BTCUSD	\N	\N	\N	\N	{53000.0000000000}	BTC update: TP1 to 53000	{"sl": null, "tps": [], "meta": {}, "side": null, "entry": null, "flags": [], "symbol": null, "update": {"notes": [], "symbol": "BTCUSD", "add_tps": [], "close_all": false, "raw_symbol": "BTC", "close_partial": null, "move_sl_to_be": false, "move_sl_to_entry": false, "move_sl_to_price": null, "move_tp_to_price": {"1": "53000"}}, "raw_text": "BTC update: TP1 to 53000", "be_at_tp1": true, "clean_text": "BTC update: TP1 to 53000", "confidence": 80, "order_type": null, "raw_symbol": null, "unofficial": false, "message_type": "UPDATE", "provider_code": "mubeen"}	2026-03-24 16:35:06.400998+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: tradebot
--

COPY public.users (user_id, telegram_user_id, display_name, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Name: provider_account_routes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tradebot
--

SELECT pg_catalog.setval('public.provider_account_routes_id_seq', 314, true);


--
-- Name: routing_decisions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tradebot
--

SELECT pg_catalog.setval('public.routing_decisions_id_seq', 440, true);


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

\unrestrict FzxLCeGNmGEGVVAdCHRa3pZE8UIaU42ttaXn210nzQjtTChkKhayElvJsmLYYn0

