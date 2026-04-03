"""init schema

Revision ID: 8da18ba68ca6
Revises:
Create Date: 2026-02-21 18:17:07.720934

"""
from alembic import op

# revision identifiers, used by Alembic.
revision = "8da18ba68ca6"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Extensions
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')

    # --- Enums (created conditionally so migration is safer) ---
    op.execute(
        """
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'provider_code') THEN
        CREATE TYPE provider_code AS ENUM ('fredtrading','billionaire_club','mubeen');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'broker_code') THEN
        CREATE TYPE broker_code AS ENUM ('vantage','ftmo','traderscale','fundednext','startrader','vtmarkets');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'platform_code') THEN
        CREATE TYPE platform_code AS ENUM ('mt4','mt5');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_kind') THEN
        CREATE TYPE account_kind AS ENUM ('demo','personal_live','prop_challenge','prop_verification','prop_funded');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'channel_kind') THEN
        CREATE TYPE channel_kind AS ENUM ('forex','crypto','indices','mixed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trade_side') THEN
        CREATE TYPE trade_side AS ENUM ('buy','sell');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type') THEN
        CREATE TYPE order_type AS ENUM ('market','limit','stop');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'intent_status') THEN
        CREATE TYPE intent_status AS ENUM (
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
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_decision') THEN
        CREATE TYPE approval_decision AS ENUM ('approve','reject','snooze');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'exec_status') THEN
        CREATE TYPE exec_status AS ENUM ('queued','sent','accepted','rejected','partial','filled','modified','closed','error');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_tag') THEN
        CREATE TYPE risk_tag AS ENUM ('unknown','normal','half','tiny','high');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'policy_outcome') THEN
        CREATE TYPE policy_outcome AS ENUM ('allow','require_approval','block');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leg_role') THEN
        CREATE TYPE leg_role AS ENUM ('tp','runner','single');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'update_kind') THEN
        CREATE TYPE update_kind AS ENUM ('set_sl_tp','move_sl_to_entry','move_tp','close_partial','close_all','reenter');
    END IF;
END$$;
        """
    )

    # --- Tables ---
    op.execute(
        """
CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  telegram_user_id BIGINT UNIQUE,
  display_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS providers (
  provider_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code provider_code NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS telegram_chats (
  chat_id BIGINT PRIMARY KEY,
  title TEXT,
  username TEXT,
  provider_code provider_code,
  channel_kind channel_kind NOT NULL DEFAULT 'mixed',
  is_control_chat BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_telegram_chats_provider ON telegram_chats(provider_code);

CREATE TABLE IF NOT EXISTS broker_accounts (
  account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id),
  broker broker_code NOT NULL,
  platform platform_code NOT NULL,
  kind account_kind NOT NULL,
  label TEXT NOT NULL,

  prop_firm broker_code,
  prop_phase TEXT,
  base_currency TEXT NOT NULL DEFAULT 'USD',
  equity_start NUMERIC(18,2),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  allowed_providers provider_code[] NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(user_id, broker, platform, label)
);

CREATE INDEX IF NOT EXISTS idx_broker_accounts_active ON broker_accounts(is_active);
CREATE INDEX IF NOT EXISTS idx_broker_accounts_broker_platform ON broker_accounts(broker, platform);

CREATE TABLE IF NOT EXISTS broker_credentials (
  cred_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES broker_accounts(account_id) ON DELETE CASCADE,

  login TEXT,
  server TEXT,
  password_cipher BYTEA,
  password_nonce BYTEA,
  kek_id TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(account_id)
);

CREATE TABLE IF NOT EXISTS symbols (
  symbol_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canonical TEXT NOT NULL UNIQUE,
  asset_class TEXT NOT NULL,
  pip_size NUMERIC(18,10),
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS symbol_mappings (
  mapping_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker broker_code NOT NULL,
  platform platform_code NOT NULL,
  canonical TEXT NOT NULL REFERENCES symbols(canonical) ON DELETE CASCADE,
  broker_symbol TEXT NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(broker, platform, canonical),
  UNIQUE(broker, platform, broker_symbol)
);

CREATE INDEX IF NOT EXISTS idx_symbol_mappings_enabled ON symbol_mappings(broker, platform, is_enabled);

CREATE TABLE IF NOT EXISTS entry_jitter_policies (
  jitter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker broker_code NOT NULL,
  platform platform_code NOT NULL,
  canonical TEXT NOT NULL REFERENCES symbols(canonical) ON DELETE CASCADE,

  max_jitter NUMERIC(18,10) NOT NULL,
  leg_step NUMERIC(18,10) NOT NULL,
  apply_to TEXT NOT NULL DEFAULT 'limit_stop',

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(broker, platform, canonical)
);

CREATE TABLE IF NOT EXISTS prop_rulesets (
  ruleset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker broker_code NOT NULL,
  phase TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',

  max_daily_loss_pct NUMERIC(6,3),
  max_total_loss_pct NUMERIC(6,3),
  profit_target_pct NUMERIC(6,3),
  min_trading_days INTEGER,

  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(broker, phase, currency)
);

CREATE TABLE IF NOT EXISTS account_risk_state (
  snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES broker_accounts(account_id) ON DELETE CASCADE,

  as_of TIMESTAMPTZ NOT NULL,
  balance NUMERIC(18,2),
  equity NUMERIC(18,2),
  floating_pl NUMERIC(18,2),

  daily_pl NUMERIC(18,2),
  daily_dd NUMERIC(18,2),
  total_dd NUMERIC(18,2),

  source TEXT NOT NULL DEFAULT 'terminal',
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_account_risk_state_account_time ON account_risk_state(account_id, as_of DESC);

CREATE TABLE IF NOT EXISTS telegram_messages (
  msg_pk UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id BIGINT NOT NULL REFERENCES telegram_chats(chat_id),
  message_id BIGINT NOT NULL,
  sender_id BIGINT,
  sent_at TIMESTAMPTZ,
  text TEXT,
  raw_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(chat_id, message_id)
);

CREATE INDEX IF NOT EXISTS idx_telegram_messages_chat_time ON telegram_messages(chat_id, sent_at DESC);

CREATE TABLE IF NOT EXISTS trade_intents (
  intent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id),

  provider provider_code NOT NULL,
  chat_id BIGINT NOT NULL REFERENCES telegram_chats(chat_id),
  source_msg_pk UUID NOT NULL REFERENCES telegram_messages(msg_pk) ON DELETE CASCADE,

  source_message_id BIGINT NOT NULL,
  dedupe_hash TEXT NOT NULL,
  parse_confidence NUMERIC(4,3) NOT NULL DEFAULT 0.0,

  status intent_status NOT NULL DEFAULT 'received',

  symbol_canonical TEXT REFERENCES symbols(canonical),
  symbol_raw TEXT,
  side trade_side,
  order_type order_type,
  entry_price NUMERIC(18,10),
  sl_price NUMERIC(18,10),
  tp_prices NUMERIC(18,10)[],
  has_runner BOOLEAN NOT NULL DEFAULT FALSE,

  risk_tag risk_tag NOT NULL DEFAULT 'unknown',
  is_scalp BOOLEAN NOT NULL DEFAULT FALSE,
  is_swing BOOLEAN NOT NULL DEFAULT FALSE,
  is_unofficial BOOLEAN NOT NULL DEFAULT FALSE,
  reenter_tag BOOLEAN NOT NULL DEFAULT FALSE,

  instructions TEXT,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(provider, chat_id, source_message_id)
);

CREATE INDEX IF NOT EXISTS idx_trade_intents_status ON trade_intents(status);
CREATE INDEX IF NOT EXISTS idx_trade_intents_provider_time ON trade_intents(provider, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trade_intents_dedupe_hash ON trade_intents(dedupe_hash);

CREATE TABLE IF NOT EXISTS trade_plans (
  plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES trade_intents(intent_id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES broker_accounts(account_id),

  policy_outcome policy_outcome NOT NULL,
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,

  lot_total NUMERIC(18,4),
  lot_per_leg NUMERIC(18,4),
  legs_count INTEGER NOT NULL DEFAULT 1,

  candidate_expires_at TIMESTAMPTZ,

  policy_reasons TEXT[],
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trade_plans_account_time ON trade_plans(account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trade_plans_intent ON trade_plans(intent_id);

CREATE TABLE IF NOT EXISTS trade_legs (
  leg_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES trade_plans(plan_id) ON DELETE CASCADE,

  idx INTEGER NOT NULL,
  role leg_role NOT NULL DEFAULT 'tp',

  entry_price NUMERIC(18,10),
  sl_price NUMERIC(18,10),
  tp_price NUMERIC(18,10),
  lots NUMERIC(18,4) NOT NULL,

  entry_jitter_applied NUMERIC(18,10),
  entry_jitter_policy_id UUID REFERENCES entry_jitter_policies(jitter_id),

  move_sl_to_entry_at_tp1 BOOLEAN NOT NULL DEFAULT TRUE,
  is_tp1 BOOLEAN NOT NULL DEFAULT FALSE,

  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_trade_legs_plan_idx ON trade_legs(plan_id, idx);
CREATE INDEX IF NOT EXISTS idx_trade_legs_plan ON trade_legs(plan_id);

CREATE TABLE IF NOT EXISTS approvals (
  approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES trade_plans(plan_id) ON DELETE CASCADE,

  control_chat_id BIGINT REFERENCES telegram_chats(chat_id),
  control_message_id BIGINT,

  requested_by_user_id UUID REFERENCES users(user_id),
  decision_by_telegram_user_id BIGINT,

  decision approval_decision,
  decided_at TIMESTAMPTZ,

  snooze_until TIMESTAMPTZ,
  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_approvals_plan ON approvals(plan_id);
CREATE INDEX IF NOT EXISTS idx_approvals_decision ON approvals(decision, decided_at DESC);

CREATE TABLE IF NOT EXISTS execution_batches (
  batch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES trade_plans(plan_id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES broker_accounts(account_id),

  executor_node TEXT NOT NULL,
  request_id TEXT NOT NULL,
  status exec_status NOT NULL DEFAULT 'queued',
  error_message TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(account_id, request_id)
);

CREATE INDEX IF NOT EXISTS idx_execution_batches_plan ON execution_batches(plan_id);

CREATE TABLE IF NOT EXISTS execution_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES execution_batches(batch_id) ON DELETE CASCADE,
  leg_id UUID REFERENCES trade_legs(leg_id) ON DELETE SET NULL,

  status exec_status NOT NULL,
  terminal_order_id BIGINT,
  terminal_position_id BIGINT,
  fill_price NUMERIC(18,10),
  filled_lots NUMERIC(18,4),

  message TEXT,
  raw_json JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_execution_events_batch_time ON execution_events(batch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_execution_events_leg ON execution_events(leg_id);

CREATE TABLE IF NOT EXISTS open_positions (
  pos_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES broker_accounts(account_id) ON DELETE CASCADE,

  broker_symbol TEXT NOT NULL,
  symbol_canonical TEXT REFERENCES symbols(canonical),

  side trade_side NOT NULL,
  entry_price NUMERIC(18,10),
  sl_price NUMERIC(18,10),
  tp_price NUMERIC(18,10),

  lots NUMERIC(18,4),
  terminal_position_id BIGINT,
  terminal_order_id BIGINT,

  linked_leg_id UUID REFERENCES trade_legs(leg_id),
  linked_plan_id UUID REFERENCES trade_plans(plan_id),

  opened_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_open BOOLEAN NOT NULL DEFAULT TRUE,

  meta JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_open_positions_account_open ON open_positions(account_id, is_open);
CREATE INDEX IF NOT EXISTS idx_open_positions_plan ON open_positions(linked_plan_id);

CREATE TABLE IF NOT EXISTS plan_risk_checks (
  check_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES trade_plans(plan_id) ON DELETE CASCADE,

  ruleset_id UUID REFERENCES prop_rulesets(ruleset_id),
  as_of_snapshot_id UUID REFERENCES account_risk_state(snapshot_id),

  est_sl_loss_ccy NUMERIC(18,2),
  est_sl_loss_pct NUMERIC(6,3),

  outcome policy_outcome NOT NULL,
  reasons TEXT[],

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_plan_risk_checks_plan ON plan_risk_checks(plan_id);

CREATE TABLE IF NOT EXISTS trade_updates (
  update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider provider_code NOT NULL,
  chat_id BIGINT NOT NULL REFERENCES telegram_chats(chat_id),
  source_msg_pk UUID NOT NULL REFERENCES telegram_messages(msg_pk) ON DELETE CASCADE,

  kind update_kind NOT NULL,
  symbol_canonical TEXT REFERENCES symbols(canonical),

  target_intent_id UUID REFERENCES trade_intents(intent_id),
  target_plan_id UUID REFERENCES trade_plans(plan_id),

  new_entry_price NUMERIC(18,10),
  new_sl_price NUMERIC(18,10),
  new_tp_prices NUMERIC(18,10)[],
  instruction_text TEXT,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trade_updates_target_intent ON trade_updates(target_intent_id);
CREATE INDEX IF NOT EXISTS idx_trade_updates_provider_time ON trade_updates(provider, created_at DESC);

CREATE TABLE IF NOT EXISTS lot_sizing_profiles (
  profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider provider_code NOT NULL,
  broker broker_code NOT NULL,
  account_size INTEGER NOT NULL,
  lot_total NUMERIC(18,4) NOT NULL,
  legs_hint INTEGER,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(provider, broker, account_size)
);

CREATE TABLE IF NOT EXISTS risk_multipliers (
  provider provider_code NOT NULL,
  tag risk_tag NOT NULL,
  multiplier NUMERIC(6,3) NOT NULL,
  requires_approval BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY(provider, tag)
);
        """
    )


def downgrade() -> None:
    # Drop tables in reverse dependency order
    op.execute(
        """
DROP TABLE IF EXISTS risk_multipliers;
DROP TABLE IF EXISTS lot_sizing_profiles;

DROP TABLE IF EXISTS trade_updates;
DROP TABLE IF EXISTS plan_risk_checks;
DROP TABLE IF EXISTS open_positions;
DROP TABLE IF EXISTS execution_events;
DROP TABLE IF EXISTS execution_batches;
DROP TABLE IF EXISTS approvals;
DROP TABLE IF EXISTS trade_legs;
DROP TABLE IF EXISTS trade_plans;
DROP TABLE IF EXISTS trade_intents;
DROP TABLE IF EXISTS telegram_messages;

DROP TABLE IF EXISTS account_risk_state;
DROP TABLE IF EXISTS prop_rulesets;

DROP TABLE IF EXISTS entry_jitter_policies;
DROP TABLE IF EXISTS symbol_mappings;
DROP TABLE IF EXISTS symbols;

DROP TABLE IF EXISTS broker_credentials;
DROP TABLE IF EXISTS broker_accounts;

DROP TABLE IF EXISTS telegram_chats;
DROP TABLE IF EXISTS providers;
DROP TABLE IF EXISTS users;
        """
    )

    # Drop enums (reverse order; conditional)
    op.execute(
        """
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'update_kind') THEN DROP TYPE update_kind; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leg_role') THEN DROP TYPE leg_role; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'policy_outcome') THEN DROP TYPE policy_outcome; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_tag') THEN DROP TYPE risk_tag; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'exec_status') THEN DROP TYPE exec_status; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_decision') THEN DROP TYPE approval_decision; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'intent_status') THEN DROP TYPE intent_status; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_type') THEN DROP TYPE order_type; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trade_side') THEN DROP TYPE trade_side; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'channel_kind') THEN DROP TYPE channel_kind; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_kind') THEN DROP TYPE account_kind; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'platform_code') THEN DROP TYPE platform_code; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'broker_code') THEN DROP TYPE broker_code; END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'provider_code') THEN DROP TYPE provider_code; END IF;
END$$;
        """
    )
