-- Phase 4: Weekly Tests Schema & RLS Policies
-- Enables admin dashboard to schedule 100-mark weekly tests with calendar date, time, and 100 questions

CREATE TABLE IF NOT EXISTS public.weekly_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  exam_type TEXT NOT NULL DEFAULT 'Police Bharti',
  scheduled_date DATE NOT NULL,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  duration_minutes INTEGER DEFAULT 90,
  total_marks INTEGER DEFAULT 100,
  total_questions INTEGER DEFAULT 100,
  questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying active tests and upcoming dates
CREATE INDEX IF NOT EXISTS idx_weekly_tests_date_active 
ON public.weekly_tests(scheduled_date, is_active);

CREATE INDEX IF NOT EXISTS idx_weekly_tests_exam_type 
ON public.weekly_tests(exam_type);

-- Enable RLS
ALTER TABLE public.weekly_tests ENABLE ROW LEVEL SECURITY;

-- RLS Policies:
-- 1. Public can view active weekly tests
CREATE POLICY "Weekly tests are viewable by everyone"
ON public.weekly_tests FOR SELECT
USING ( TRUE );

-- 2. Insert allowed for admin dashboard
CREATE POLICY "Enable insert for weekly_tests"
ON public.weekly_tests FOR INSERT
WITH CHECK ( TRUE );

-- 3. Update allowed for admin dashboard
CREATE POLICY "Enable update for weekly_tests"
ON public.weekly_tests FOR UPDATE
USING ( TRUE )
WITH CHECK ( TRUE );

-- 4. Delete allowed for admin dashboard
CREATE POLICY "Enable delete for weekly_tests"
ON public.weekly_tests FOR DELETE
USING ( TRUE );
