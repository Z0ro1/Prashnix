-- Phase 2: Supabase Initialization Schema

-- 1. Create Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_id TEXT NOT NULL DEFAULT 'avatar_01',
  district TEXT NOT NULL,
  total_xp INTEGER DEFAULT 0,
  weekly_xp INTEGER DEFAULT 0,
  streak_count INTEGER DEFAULT 0,
  current_hearts INTEGER DEFAULT 25,
  last_heart_regen TIMESTAMPTZ DEFAULT NOW(),
  is_onboarded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Indexes
-- Index for District Leaderboards (as requested by user)
CREATE INDEX IF NOT EXISTS idx_profiles_district_weekly_xp 
ON public.profiles(district, weekly_xp DESC);

-- 3. Create Leaderboard View (Standard Query View)
-- Materialized view would need cron to refresh, standard view is real-time and fine with the index
CREATE OR REPLACE VIEW public.district_leaderboards AS
SELECT 
  id,
  username,
  avatar_id,
  district,
  weekly_xp,
  RANK() OVER (PARTITION BY district ORDER BY weekly_xp DESC) as district_rank
FROM public.profiles
WHERE is_onboarded = TRUE;

-- 4. Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- SELECT: Public read access
CREATE POLICY "Public profiles are viewable by everyone."
ON public.profiles FOR SELECT
USING ( TRUE );

-- UPDATE: Allowed ONLY if auth.uid() = id
CREATE POLICY "Users can update own profile."
ON public.profiles FOR UPDATE
USING ( auth.uid() = id );

-- INSERT: Allowed ONLY during auth onboarding (can also be handled by trigger)
CREATE POLICY "Users can insert their own profile."
ON public.profiles FOR INSERT
WITH CHECK ( auth.uid() = id );

-- 5. Trigger: Auto-create profile on Auth signup
-- Function to handle new user
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, district, is_onboarded)
  VALUES (
    new.id,
    -- Default username fallback (will be updated during onboarding)
    'candidate_' || substr(md5(random()::text), 1, 8),
    'Pending',
    FALSE
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger definition
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger for updating updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
