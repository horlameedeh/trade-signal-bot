BEGIN;

-- Providers
INSERT INTO providers (code, name)
VALUES
  ('fredtrading', 'Fredtrading'),
  ('billionaire_club', 'BILLIONAIRE CLUB'),
  ('mubeen', 'Mubeen Trading')
ON CONFLICT (code) DO NOTHING;

-- Canonical symbols
INSERT INTO symbols (canonical, asset_class)
VALUES
  ('XAUUSD','metal'),
  ('XAGUSD','metal'),
  ('DJ30','index'),
  ('SP500','index'),
  ('NAS100','index'),
  ('USOIL','oil'),
  ('BTCUSD','crypto'),
  ('ETHUSD','crypto'),
  ('XRPUSD','crypto'),
  ('SOLUSD','crypto'),

  ('EURUSD','fx'),
  ('GBPUSD','fx'),
  ('USDJPY','fx'),
  ('USDCHF','fx'),
  ('USDCAD','fx'),
  ('AUDUSD','fx'),
  ('NZDUSD','fx'),

  ('AUDCAD','fx'),
  ('AUDCHF','fx'),
  ('AUDJPY','fx'),
  ('AUDNZD','fx'),
  ('AUDSGD','fx'),
  ('CADCHF','fx'),
  ('CADJPY','fx'),
  ('CHFJPY','fx'),
  ('EURAUD','fx'),
  ('EURCAD','fx'),
  ('EURCHF','fx'),
  ('EURGBP','fx'),
  ('EURJPY','fx'),
  ('EURNZD','fx'),
  ('GBPAUD','fx'),
  ('GBPCAD','fx'),
  ('GBPCHF','fx'),
  ('GBPJPY','fx'),
  ('GBPNZD','fx'),
  ('NZDCAD','fx'),
  ('NZDCHF','fx'),
  ('NZDJPY','fx')
ON CONFLICT (canonical) DO NOTHING;

-- -------------------------
-- Vantage mappings (mt4)
-- -------------------------
INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
VALUES
  ('vantage','mt4','XAUUSD','XAUUSD'),
  ('vantage','mt4','XAGUSD','XAGUSD'),
  ('vantage','mt4','DJ30','DJ30'),
  ('vantage','mt4','SP500','SP500'),
  ('vantage','mt4','NAS100','NAS100'),
  ('vantage','mt4','USOIL','USOUSD'),
  ('vantage','mt4','BTCUSD','BTCUSD'),
  ('vantage','mt4','ETHUSD','ETHUSD'),
  ('vantage','mt4','XRPUSD','XRPUSD'),
  ('vantage','mt4','SOLUSD','SOLUSD'),
  ('vantage','mt4','EURUSD','EURUSD'),
  ('vantage','mt4','GBPUSD','GBPUSD'),
  ('vantage','mt4','USDJPY','USDJPY'),
  ('vantage','mt4','USDCHF','USDCHF'),
  ('vantage','mt4','USDCAD','USDCAD'),
  ('vantage','mt4','AUDUSD','AUDUSD'),
  ('vantage','mt4','NZDUSD','NZDUSD'),
  ('vantage','mt4','AUDCAD','AUDCAD'),
  ('vantage','mt4','AUDCHF','AUDCHF'),
  ('vantage','mt4','AUDJPY','AUDJPY'),
  ('vantage','mt4','AUDNZD','AUDNZD'),
  ('vantage','mt4','CADCHF','CADCHF'),
  ('vantage','mt4','CADJPY','CADJPY'),
  ('vantage','mt4','CHFJPY','CHFJPY'),
  ('vantage','mt4','EURAUD','EURAUD'),
  ('vantage','mt4','EURCAD','EURCAD'),
  ('vantage','mt4','EURCHF','EURCHF'),
  ('vantage','mt4','EURGBP','EURGBP'),
  ('vantage','mt4','EURJPY','EURJPY'),
  ('vantage','mt4','EURNZD','EURNZD'),
  ('vantage','mt4','GBPAUD','GBPAUD'),
  ('vantage','mt4','GBPCAD','GBPCAD'),
  ('vantage','mt4','GBPCHF','GBPCHF'),
  ('vantage','mt4','GBPJPY','GBPJPY'),
  ('vantage','mt4','GBPNZD','GBPNZD'),
  ('vantage','mt4','NZDCAD','NZDCAD'),
  ('vantage','mt4','NZDCHF','NZDCHF'),
  ('vantage','mt4','NZDJPY','NZDJPY')
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

-- Vantage mt5 mirrors mt4
INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
SELECT 'vantage','mt5', canonical, broker_symbol
FROM symbol_mappings
WHERE broker='vantage' AND platform='mt4'
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

-- -------------------------
-- FTMO mappings
-- -------------------------
INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
VALUES
  ('ftmo','mt4','DJ30','US30.cash'),
  ('ftmo','mt4','SP500','US500.cash'),
  ('ftmo','mt4','NAS100','US100.cash'),
  ('ftmo','mt4','USOIL','USOIL.cash'),
  ('ftmo','mt4','XAUUSD','XAUUSD'),
  ('ftmo','mt4','XAGUSD','XAGUSD'),
  ('ftmo','mt4','BTCUSD','BTCUSD'),
  ('ftmo','mt4','ETHUSD','ETHUSD'),
  ('ftmo','mt4','XRPUSD','XRPUSD'),
  ('ftmo','mt4','SOLUSD','SOLUSD'),
  ('ftmo','mt4','EURUSD','EURUSD'),
  ('ftmo','mt4','GBPUSD','GBPUSD'),
  ('ftmo','mt4','USDJPY','USDJPY'),
  ('ftmo','mt4','USDCHF','USDCHF'),
  ('ftmo','mt4','USDCAD','USDCAD'),
  ('ftmo','mt4','AUDUSD','AUDUSD'),
  ('ftmo','mt4','NZDUSD','NZDUSD'),
  ('ftmo','mt4','AUDCAD','AUDCAD'),
  ('ftmo','mt4','AUDCHF','AUDCHF'),
  ('ftmo','mt4','AUDJPY','AUDJPY'),
  ('ftmo','mt4','AUDNZD','AUDNZD'),
  ('ftmo','mt4','CADCHF','CADCHF'),
  ('ftmo','mt4','CADJPY','CADJPY'),
  ('ftmo','mt4','CHFJPY','CHFJPY'),
  ('ftmo','mt4','EURAUD','EURAUD'),
  ('ftmo','mt4','EURCAD','EURCAD'),
  ('ftmo','mt4','EURCHF','EURCHF'),
  ('ftmo','mt4','EURGBP','EURGBP'),
  ('ftmo','mt4','EURJPY','EURJPY'),
  ('ftmo','mt4','EURNZD','EURNZD'),
  ('ftmo','mt4','GBPAUD','GBPAUD'),
  ('ftmo','mt4','GBPCAD','GBPCAD'),
  ('ftmo','mt4','GBPCHF','GBPCHF'),
  ('ftmo','mt4','GBPJPY','GBPJPY'),
  ('ftmo','mt4','GBPNZD','GBPNZD'),
  ('ftmo','mt4','NZDCAD','NZDCAD'),
  ('ftmo','mt4','NZDCHF','NZDCHF'),
  ('ftmo','mt4','NZDJPY','NZDJPY')
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
SELECT 'ftmo','mt5', canonical, broker_symbol
FROM symbol_mappings
WHERE broker='ftmo' AND platform='mt4'
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

-- -------------------------
-- Traderscale mappings
-- -------------------------
INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
VALUES
  ('traderscale','mt4','XAUUSD','XAUUSDc'),
  ('traderscale','mt4','XAGUSD','XAGUSDc'),
  ('traderscale','mt4','DJ30','DJ30.c'),
  ('traderscale','mt4','SP500','US500.c'),
  ('traderscale','mt4','NAS100','USTEC.c'),
  ('traderscale','mt4','BTCUSD','BTCUSD'),
  ('traderscale','mt4','ETHUSD','ETHUSD'),
  ('traderscale','mt4','XRPUSD','XRPUSD'),
  ('traderscale','mt4','EURUSD','EURUSDc'),
  ('traderscale','mt4','GBPUSD','GBPUSDc'),
  ('traderscale','mt4','USDJPY','USDJPYc'),
  ('traderscale','mt4','USDCHF','USDCHFc'),
  ('traderscale','mt4','USDCAD','USDCADc'),
  ('traderscale','mt4','AUDUSD','AUDUSDc'),
  ('traderscale','mt4','NZDUSD','NZDUSDc'),
  ('traderscale','mt4','AUDCAD','AUDCADc'),
  ('traderscale','mt4','AUDCHF','AUDCHFc'),
  ('traderscale','mt4','AUDJPY','AUDJPYc'),
  ('traderscale','mt4','AUDNZD','AUDNZDc'),
  ('traderscale','mt4','CADCHF','CADCHFc'),
  ('traderscale','mt4','CADJPY','CADJPYc'),
  ('traderscale','mt4','CHFJPY','CHFJPYc'),
  ('traderscale','mt4','EURAUD','EURAUDc'),
  ('traderscale','mt4','EURCAD','EURCADc'),
  ('traderscale','mt4','EURCHF','EURCHFc'),
  ('traderscale','mt4','EURGBP','EURGBPc'),
  ('traderscale','mt4','EURJPY','EURJPYc'),
  ('traderscale','mt4','EURNZD','EURNZDc'),
  ('traderscale','mt4','GBPAUD','GBPAUDc'),
  ('traderscale','mt4','GBPCAD','GBPCADc'),
  ('traderscale','mt4','GBPCHF','GBPCHFc'),
  ('traderscale','mt4','GBPJPY','GBPJPYc'),
  ('traderscale','mt4','GBPNZD','GBPNZDc'),
  ('traderscale','mt4','NZDCAD','NZDCADc'),
  ('traderscale','mt4','NZDCHF','NZDCHFc'),
  ('traderscale','mt4','NZDJPY','NZDJPYc')
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
SELECT 'traderscale','mt5', canonical, broker_symbol
FROM symbol_mappings
WHERE broker='traderscale' AND platform='mt4'
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

-- -------------------------
-- FundedNext mappings
-- -------------------------
INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
VALUES
  ('fundednext','mt4','XAUUSD','XAUUSD'),
  ('fundednext','mt4','XAGUSD','XAGUSD'),
  ('fundednext','mt4','DJ30','US30'),
  ('fundednext','mt4','SP500','SPX500'),
  ('fundednext','mt4','NAS100','NDX100'),
  ('fundednext','mt4','USOIL','USOUSD'),
  ('fundednext','mt4','BTCUSD','BTCUSD'),
  ('fundednext','mt4','ETHUSD','ETHUSD'),
  ('fundednext','mt4','XRPUSD','XRPUSD'),
  ('fundednext','mt4','SOLUSD','SOLUSD'),
  ('fundednext','mt4','EURUSD','EURUSD'),
  ('fundednext','mt4','GBPUSD','GBPUSD'),
  ('fundednext','mt4','USDJPY','USDJPY'),
  ('fundednext','mt4','USDCHF','USDCHF'),
  ('fundednext','mt4','USDCAD','USDCAD'),
  ('fundednext','mt4','AUDUSD','AUDUSD'),
  ('fundednext','mt4','NZDUSD','NZDUSD'),
  ('fundednext','mt4','AUDCAD','AUDCAD'),
  ('fundednext','mt4','AUDCHF','AUDCHF'),
  ('fundednext','mt4','AUDJPY','AUDJPY'),
  ('fundednext','mt4','AUDNZD','AUDNZD'),
  ('fundednext','mt4','AUDSGD','AUDSGD'),
  ('fundednext','mt4','CADCHF','CADCHF'),
  ('fundednext','mt4','CADJPY','CADJPY'),
  ('fundednext','mt4','CHFJPY','CHFJPY'),
  ('fundednext','mt4','EURAUD','EURAUD'),
  ('fundednext','mt4','EURCAD','EURCAD'),
  ('fundednext','mt4','EURCHF','EURCHF'),
  ('fundednext','mt4','EURGBP','EURGBP'),
  ('fundednext','mt4','EURJPY','EURJPY'),
  ('fundednext','mt4','EURNZD','EURNZD'),
  ('fundednext','mt4','GBPAUD','GBPAUD'),
  ('fundednext','mt4','GBPCAD','GBPCAD'),
  ('fundednext','mt4','GBPCHF','GBPCHF'),
  ('fundednext','mt4','GBPJPY','GBPJPY'),
  ('fundednext','mt4','GBPNZD','GBPNZD'),
  ('fundednext','mt4','NZDCAD','NZDCAD'),
  ('fundednext','mt4','NZDCHF','NZDCHF'),
  ('fundednext','mt4','NZDJPY','NZDJPY')
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

INSERT INTO symbol_mappings (broker, platform, canonical, broker_symbol)
SELECT 'fundednext','mt5', canonical, broker_symbol
FROM symbol_mappings
WHERE broker='fundednext' AND platform='mt4'
ON CONFLICT (broker, platform, canonical) DO UPDATE SET broker_symbol = EXCLUDED.broker_symbol;

-- Risk multipliers (Mubeen high risk requires approval)
INSERT INTO risk_multipliers (provider, tag, multiplier, requires_approval)
VALUES
  ('fredtrading','unknown',1.0,false),
  ('fredtrading','normal',1.0,false),
  ('fredtrading','half',0.5,false),
  ('fredtrading','tiny',0.25,true),
  ('fredtrading','high',1.0,true),

  ('billionaire_club','unknown',1.0,false),
  ('billionaire_club','normal',1.0,false),
  ('billionaire_club','half',0.5,false),
  ('billionaire_club','tiny',0.25,true),
  ('billionaire_club','high',1.0,true),

  ('mubeen','unknown',1.0,false),
  ('mubeen','normal',1.0,false),
  ('mubeen','half',0.5,false),
  ('mubeen','tiny',0.25,false),
  ('mubeen','high',1.0,true)
ON CONFLICT (provider, tag) DO UPDATE
SET multiplier = EXCLUDED.multiplier,
    requires_approval = EXCLUDED.requires_approval;

-- Lot sizing profiles
INSERT INTO lot_sizing_profiles (provider, broker, account_size, lot_total, legs_hint)
VALUES
  ('fredtrading','ftmo',10000,0.20,NULL),
  ('fredtrading','ftmo',20000,0.40,NULL),
  ('fredtrading','ftmo',35000,0.60,NULL),
  ('fredtrading','ftmo',100000,1.20,4),
  ('fredtrading','ftmo',200000,1.60,4),

  ('billionaire_club','traderscale',10000,0.20,NULL),
  ('billionaire_club','traderscale',20000,0.40,NULL),
  ('billionaire_club','traderscale',35000,0.60,NULL),
  ('billionaire_club','traderscale',100000,1.20,4),
  ('billionaire_club','traderscale',200000,1.60,4),

  ('mubeen','fundednext',10000,0.20,NULL),
  ('mubeen','fundednext',20000,0.40,NULL),
  ('mubeen','fundednext',35000,0.60,NULL),
  ('mubeen','fundednext',100000,1.20,4),
  ('mubeen','fundednext',200000,1.60,4),

  -- Personal live baseline on your £1k accounts
  ('fredtrading','vantage',1000,0.20,NULL),
  ('fredtrading','startrader',1000,0.20,NULL),
  ('fredtrading','vtmarkets',1000,0.20,NULL)
ON CONFLICT (provider, broker, account_size) DO UPDATE
SET lot_total = EXCLUDED.lot_total, legs_hint = EXCLUDED.legs_hint;

COMMIT;
