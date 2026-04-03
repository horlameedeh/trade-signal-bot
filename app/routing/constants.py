PROVIDER_CODES = {"fredtrading", "billionaire_club", "mubeen"}

# Enforce “provider must map only to this broker_name”
# Note: broker_accounts.broker is a Postgres enum (broker_code) whose labels are lowercase.
PROVIDER_ALLOWED_BROKER_NAME = {
    "fredtrading": "ftmo",
    "billionaire_club": "traderscale",
    "mubeen": "fundednext",
}
